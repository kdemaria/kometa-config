# Docker Compose Deployment Guide

This guide covers deploying Kometa to multiple Plex servers using Docker Compose with a single shared config and secrets file.

## Architecture

**Single Config File:** `config.yml` - Shared across all servers (auto-updated from GitHub)

**Single Secrets File:** `.env` - Contains all shared secrets + per-server Plex tokens

**Per-Service Configuration:** Only Plex URL differs (hardcoded in docker-compose.yml)

## Features

✅ **Auto-sync config from GitHub** - Pulls latest config.yml before containers start
✅ **Single secrets file** - All API keys in one place
✅ **Easy to add servers** - Just add a new service block
✅ **Isolated logs/cache** - Each server has its own Docker volume
✅ **Read-only config** - Prevents accidental modifications

## Setup Instructions

### 1. Clone Repository on Synology

SSH into your Synology and clone the repo:

```bash
# Navigate to your docker directory
cd /volume1/docker

# Clone the repository
git clone https://github.com/kdemaria/kometa-config.git

# Navigate into the directory
cd kometa-config
```

### 2. Create Secrets File

Copy the example and fill in your actual values:

```bash
cp env.compose.example .env
nano .env
```

Fill in:
- `TMDB_KEY` - Your TMDb API key (shared)
- `OMDB_KEY` - Your OMDb API key (shared)
- `RADARR_TOKEN` - Your Radarr token (shared)
- `SONARR_TOKEN` - Your Sonarr token (shared)
- `PLEX_TOKEN_KEMPFPLEX1` - Plex token for kempfplex1
- `PLEX_TOKEN_KEMPFNAS2` - Plex token for kempfnas2
- `PLEX_TOKEN_DEMARIA_DT` - Plex token for DEMARIA-DT

**Important:** The `.env` file is gitignored and will never be committed.

### 3. Verify Plex URLs

Check the Plex URLs in `docker-compose.yml` match your servers:

```yaml
environment:
  - KOMETA_PLEXURL=http://kempfplex1:32400  # Verify this matches your server
```

If your Plex servers use different hostnames or IPs, update them in the docker-compose.yml file.

### 4. Start All Containers

```bash
docker-compose up -d
```

This will:
1. Pull the latest config from GitHub
2. Start all three Kometa containers
3. Each container will use the shared config with its specific Plex server

### 5. Verify Containers Are Running

```bash
docker-compose ps
```

You should see:
- `kometa-config-sync` (exited - this is normal, it only runs once)
- `kometa-kempfplex1` (running)
- `kometa-kempfnas2` (running)
- `kometa-demaria-dt` (running)

## Common Operations

### View Logs

**All containers:**
```bash
docker-compose logs -f
```

**Specific server:**
```bash
docker-compose logs -f kometa-kempfplex1
```

### Restart All Containers

```bash
docker-compose restart
```

### Restart Specific Server

```bash
docker-compose restart kometa-kempfplex1
```

### Pull Latest Config and Restart

```bash
docker-compose down
docker-compose up -d
```

The `config-sync` service will automatically pull the latest config from GitHub.

### Stop All Containers

```bash
docker-compose down
```

### Update Kometa Image

```bash
docker-compose pull
docker-compose up -d
```

## Adding a New Server

To add a new Plex server:

1. **Add Plex token to `.env` file:**
   ```bash
   PLEX_TOKEN_NEWSERVER=your_new_server_token_here
   ```

2. **Add service to `docker-compose.yml`:**
   ```yaml
   kometa-newserver:
     image: kometateam/kometa:latest
     container_name: kometa-newserver
     depends_on:
       config-sync:
         condition: service_completed_successfully
     restart: unless-stopped
     environment:
       - KOMETA_PLEXURL=http://newserver:32400
       - KOMETA_PLEXTOKEN=${PLEX_TOKEN_NEWSERVER}
       - KOMETA_TMDBKEY=${TMDB_KEY}
       - KOMETA_OMDBKEY=${OMDB_KEY}
       - KOMETA_RADARRTOKEN=${RADARR_TOKEN}
       - KOMETA_SONARRTOKEN=${SONARR_TOKEN}
     volumes:
       - ./config.yml:/config/config.yml:ro
       - kometa-newserver-logs:/config/logs
       - kometa-newserver-cache:/config/cache
     command: --run --read-only-config
   ```

3. **Add volumes:**
   ```yaml
   volumes:
     kometa-newserver-logs:
     kometa-newserver-cache:
   ```

4. **Restart:**
   ```bash
   docker-compose up -d
   ```

## Scheduling Runs

### Option 1: Use Kometa's Built-in Scheduler

Add to your `.env` file:
```bash
KOMETA_TIME=03:00  # Run daily at 3 AM
```

Then update `docker-compose.yml` to pass this variable:
```yaml
environment:
  - KOMETA_TIME=${KOMETA_TIME}
```

### Option 2: Use Synology Task Scheduler

1. Control Panel → Task Scheduler
2. Create → Scheduled Task → User-defined script
3. Schedule: Daily at 3:00 AM
4. Script:
   ```bash
   cd /volume1/docker/kometa-config
   docker-compose restart
   ```

### Option 3: Cron Job

Add to crontab:
```bash
0 3 * * * cd /volume1/docker/kometa-config && docker-compose restart
```

## Accessing Logs and Cache

Logs and cache are stored in Docker volumes. To access them:

**List volumes:**
```bash
docker volume ls | grep kometa
```

**Inspect a volume:**
```bash
docker volume inspect kometa-config_kometa-kempfplex1-logs
```

**View logs directly:**
```bash
docker run --rm -v kometa-config_kometa-kempfplex1-logs:/logs alpine ls -la /logs
```

## Troubleshooting

### Config not updating from GitHub

Check config-sync logs:
```bash
docker-compose logs config-sync
```

Manually pull:
```bash
git pull origin main
```

### Container won't start

Check logs:
```bash
docker-compose logs kometa-kempfplex1
```

Common issues:
- Invalid Plex token
- Plex URL not reachable
- Missing environment variables

### "Plex Error: Unauthorized"

- Verify `PLEX_TOKEN_*` in `.env` file is correct
- Ensure Plex server is accessible from the container

### Changes to config.yml not taking effect

1. Ensure you pushed changes to GitHub
2. Restart containers (this pulls latest config):
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Updating Configuration

### Update config.yml

1. **Make changes locally and push to GitHub:**
   ```bash
   git add config.yml
   git commit -m "Update configuration"
   git push
   ```

2. **Restart containers to pull changes:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Update secrets

1. **Edit `.env` file:**
   ```bash
   nano .env
   ```

2. **Restart containers:**
   ```bash
   docker-compose restart
   ```

## File Structure

```
/volume1/docker/kometa-config/
├── .git/                          # Git repository
├── .env                           # Your secrets (gitignored)
├── config.yml                     # Shared Kometa config (from GitHub)
├── docker-compose.yml             # Container definitions
├── env.compose.example            # Example secrets file
└── README.md                      # Documentation
```

## Security Notes

- The `.env` file is **never committed to git** (in .gitignore)
- Config is mounted **read-only** in containers
- Each server's cache and logs are isolated
- Plex tokens are kept in environment variables, not in config.yml

## Benefits Over Individual Containers

✅ **Single command to manage all servers** - `docker-compose up -d`
✅ **Shared secrets management** - One `.env` file instead of three
✅ **Auto-sync config from GitHub** - Always uses latest config
✅ **Easy to add/remove servers** - Edit docker-compose.yml
✅ **Consistent deployment** - All servers use identical setup
✅ **Version controlled** - docker-compose.yml is in git
