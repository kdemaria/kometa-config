#!/bin/bash
# Generate docker-compose.yml from servers.txt

# Check if we need sudo for file operations
SUDO=""
if [ -f docker-compose.yml ] && [ ! -w docker-compose.yml ]; then
  echo "docker-compose.yml is read-only. Attempting to make it writable..."
  if ! chmod +w docker-compose.yml 2>/dev/null; then
    echo "Need sudo permissions to modify docker-compose.yml"
    SUDO="sudo"
    $SUDO chmod +w docker-compose.yml || {
      echo "Error: Cannot make docker-compose.yml writable even with sudo"
      exit 1
    }
  fi
fi

cat > docker-compose.yml << 'HEADER'
version: '3.8'

services:
  # Config sync service - pulls latest config from GitHub before other services start
  config-sync:
    image: alpine:latest
    container_name: kometa-config-sync
    volumes:
      - ./:/git
    command: >
      sh -c "
        apk add --no-cache git &&
        cd /git &&
        git config --global --add safe.directory /git &&
        git pull origin main || echo 'Git pull failed or no changes'
      "
    restart: "no"

HEADER

# Read servers.txt and generate service blocks
while IFS='|' read -r container_name plex_url display_name || [ -n "$container_name" ]; do
  # Skip empty lines and comments
  [[ -z "$container_name" || "$container_name" =~ ^[[:space:]]*# ]] && continue

  # Trim whitespace
  container_name=$(echo "$container_name" | xargs)
  plex_url=$(echo "$plex_url" | xargs)
  display_name=$(echo "$display_name" | xargs)

  # Extract server name for volume names (remove kometa- prefix)
  server_name="${container_name#kometa-}"

  # Determine if this is the local server (kometa-kempfnas2) which needs host networking
  if [ "$container_name" = "kometa-kempfnas2" ]; then
    cat >> docker-compose.yml << SERVICE

  # Kometa for ${display_name}
  ${container_name}:
    image: kometateam/kometa:latest
    container_name: ${container_name}
    depends_on:
      config-sync:
        condition: service_completed_successfully
    restart: unless-stopped
    network_mode: host
    environment:
SERVICE
  else
    cat >> docker-compose.yml << SERVICE

  # Kometa for ${display_name}
  ${container_name}:
    image: kometateam/kometa:latest
    container_name: ${container_name}
    depends_on:
      config-sync:
        condition: service_completed_successfully
    restart: unless-stopped
    dns:
      - 10.100.103.1
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
SERVICE
  fi

  cat >> docker-compose.yml << SERVICE_CONT
      # Server-specific Plex URL (only thing that differs per server)
      - KOMETA_PLEXURL=${plex_url}

      # All other secrets are shared (from .env file)
      - KOMETA_PLEXTOKEN=\${PLEX_TOKEN}
      - KOMETA_TMDBKEY=\${TMDB_KEY}
      - KOMETA_OMDBKEY=\${OMDB_KEY}
      - KOMETA_RADARRTOKEN=\${RADARR_TOKEN}
      - KOMETA_SONARRTOKEN=\${SONARR_TOKEN}
    volumes:
      # Shared config (read-only)
      - ./config.yml:/config/config.yml:ro

      # Server-specific writable directories
      - ${server_name}-logs:/config/logs
      - ${server_name}-cache:/config/cache
    command: --run --read-only-config
SERVICE_CONT

done < servers.txt

# Generate volumes section
cat >> docker-compose.yml << 'VOLUMES_HEADER'

# Named volumes for logs and cache (persists between container restarts)
volumes:
VOLUMES_HEADER

# Read servers.txt again for volume definitions
while IFS='|' read -r container_name plex_url display_name || [ -n "$container_name" ]; do
  # Skip empty lines and comments
  [[ -z "$container_name" || "$container_name" =~ ^[[:space:]]*# ]] && continue

  # Trim whitespace
  container_name=$(echo "$container_name" | xargs)

  # Extract server name for volume names
  server_name="${container_name#kometa-}"

  cat >> docker-compose.yml << VOLUME
  ${server_name}-logs:
  ${server_name}-cache:
VOLUME

done < servers.txt

echo "✅ docker-compose.yml generated successfully from servers.txt"
echo ""
echo "Server configuration:"
grep -v '^#' servers.txt | grep -v '^[[:space:]]*$' | while IFS='|' read -r container_name plex_url display_name; do
  container_name=$(echo "$container_name" | xargs)
  plex_url=$(echo "$plex_url" | xargs)
  display_name=$(echo "$display_name" | xargs)
  echo "  - ${display_name}: ${plex_url}"
done
