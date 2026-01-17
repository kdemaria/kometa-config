# Kometa Multi-Server Deployment Guide

## Architecture Overview

This configuration supports **multiple Plex servers** using a single shared `config.yml` file. Each server gets its own container with a unique `.env` file containing server-specific values.

### What's Shared:
- `config.yml` - Collection and overlay definitions
- TMDb API key
- OMDb API key
- Collection/overlay preferences

### What's Unique Per Server:
- Plex URL
- Plex token
- (Optional) Radarr/Sonarr URLs and tokens if different per server

## Deployment Options

### Option 1: Synology Container Manager (Recommended)

#### Directory Structure on Synology:
```
/volume1/docker/kometa/
├── config/                    # Shared config directory
│   ├── config.yml            # Shared configuration (read-only)
│   └── assets/               # Shared assets (optional)
├── kempfplex1/
│   ├── .env                  # Server-specific environment variables
│   ├── logs/                 # Server-specific logs
│   └── cache/                # Server-specific cache
├── server2/
│   ├── .env
│   ├── logs/
│   └── cache/
└── server3/
    ├── .env
    ├── logs/
    └── cache/
```

#### Setup Steps for Each Server:

1. **Create server-specific directory:**
   ```bash
   mkdir -p /volume1/docker/kometa/kempfplex1/{logs,cache}
   ```

2. **Copy the appropriate env template:**
   ```bash
   cp env.kempfplex1.example /volume1/docker/kometa/kempfplex1/.env
   ```

3. **Edit the .env file with actual values:**
   ```bash
   nano /volume1/docker/kometa/kempfplex1/.env
   ```
   Fill in:
   - `KOMETA_PLEXURL` - Your Plex server URL
   - `KOMETA_PLEXTOKEN` - Your Plex token
   - `KOMETA_TMDBKEY` - TMDb API key (same for all servers)
   - `KOMETA_OMDBKEY` - OMDb API key (same for all servers)

4. **In Synology Container Manager:**
   - Click "Image" → Search "kometateam/kometa" → Download
   - Click "Container" → "Create"
   - Select the `kometateam/kometa` image
   - Click "Advanced Settings"

5. **Configure Volume Mounts:**
   | Container Path | Host Path | Mode |
   |----------------|-----------|------|
   | `/config` | `/volume1/docker/kometa/config` | Read-only |
   | `/config/.env` | `/volume1/docker/kometa/kempfplex1/.env` | Read/Write |
   | `/config/logs` | `/volume1/docker/kometa/kempfplex1/logs` | Read/Write |
   | `/config/cache` | `/volume1/docker/kometa/kempfplex1/cache` | Read/Write |

6. **Configure Environment (if needed):**
   You can also pass environment variables directly in Container Manager instead of using .env file:
   - Add each `KOMETA_*` variable from your .env file
   - This is optional if you're using the .env file mount

7. **Set Container Name:**
   - Name: `kometa-kempfplex1`

8. **Configure Restart Policy:**
   - Set to "Always" or "Unless stopped"

9. **Set Run Command (optional):**
   ```
   --run --read-only-config
   ```
   The `--read-only-config` flag prevents Kometa from modifying the shared config.yml

10. **Apply and Start Container**

#### Quick Container Manager Setup (Alternative - Direct Env Vars):

If you prefer to use Container Manager's environment variable UI instead of .env files:

**Volume Mounts:**
- `/config` → `/volume1/docker/kometa/config` (Read-only)
- `/config/logs` → `/volume1/docker/kometa/kempfplex1/logs` (Read/Write)
- `/config/cache` → `/volume1/docker/kometa/kempfplex1/cache` (Read/Write)

**Environment Variables (add in Container Manager UI):**
```
KOMETA_SERVERNAME=kempfplex1
KOMETA_PLEXURL=http://kempfplex1:32400
KOMETA_PLEXTOKEN=your_token_here
KOMETA_TMDBKEY=your_tmdb_key
KOMETA_OMDBKEY=your_omdb_key
KOMETA_RADARRTOKEN=your_radarr_token
KOMETA_SONARRTOKEN=your_sonarr_token
```

### Option 2: Docker Compose

Create a `docker-compose.yml` for each server:

```yaml
version: '3.8'

services:
  kometa-kempfplex1:
    image: kometateam/kometa:latest
    container_name: kometa-kempfplex1
    restart: unless-stopped
    env_file:
      - ./kempfplex1/.env
    volumes:
      # Shared config (read-only)
      - ./config:/config:ro
      # Server-specific writeable directories
      - ./kempfplex1/logs:/config/logs
      - ./kempfplex1/cache:/config/cache
    command: --run --read-only-config

  kometa-server2:
    image: kometateam/kometa:latest
    container_name: kometa-server2
    restart: unless-stopped
    env_file:
      - ./server2/.env
    volumes:
      - ./config:/config:ro
      - ./server2/logs:/config/logs
      - ./server2/cache:/config/cache
    command: --run --read-only-config
```

Run with:
```bash
docker-compose up -d
```

### Option 3: Individual Docker Run Commands

**For kempfplex1:**
```bash
docker run -d \
  --name kometa-kempfplex1 \
  --restart unless-stopped \
  --env-file /volume1/docker/kometa/kempfplex1/.env \
  -v /volume1/docker/kometa/config:/config:ro \
  -v /volume1/docker/kometa/kempfplex1/logs:/config/logs \
  -v /volume1/docker/kometa/kempfplex1/cache:/config/cache \
  kometateam/kometa:latest \
  --run --read-only-config
```

**For server2:**
```bash
docker run -d \
  --name kometa-server2 \
  --restart unless-stopped \
  --env-file /volume1/docker/kometa/server2/.env \
  -v /volume1/docker/kometa/config:/config:ro \
  -v /volume1/docker/kometa/server2/logs:/config/logs \
  -v /volume1/docker/kometa/server2/cache:/config/cache \
  kometateam/kometa:latest \
  --run --read-only-config
```

## Getting Your Plex Token

To find your Plex token:
1. Open a Plex Web App
2. Open any media item
3. Click "Get Info" → "View XML"
4. Look at the URL: `...?X-Plex-Token=YOURTOKEN`

Or use this method:
1. SSH into your Plex server
2. Run: `cat "$(find ~/.config/Plex\ Media\ Server/Preferences.xml)" | grep -oP 'PlexOnlineToken="\K[^"]+'`

## Scheduling Kometa Runs

### Option A: Use Kometa's Built-in Scheduler

Edit your `.env` file and add:
```
KOMETA_TIME=03:00  # Run at 3 AM daily
```

Or run continuously with interval:
```
KOMETA_RUN=true
```

### Option B: Use Synology Task Scheduler

1. Open "Control Panel" → "Task Scheduler"
2. Create → "Scheduled Task" → "User-defined script"
3. Schedule: Daily at 3:00 AM
4. User-defined script:
   ```bash
   docker start kometa-kempfplex1
   ```

### Option C: Cron (if using Docker Compose)

Add to crontab:
```
0 3 * * * docker-compose -f /volume1/docker/kometa/docker-compose.yml up kometa-kempfplex1
```

## Monitoring and Logs

### View logs:
```bash
# Container Manager: Click container → "Details" → "Log"

# Docker CLI:
docker logs kometa-kempfplex1

# Follow logs in real-time:
docker logs -f kometa-kempfplex1

# Or check the mounted log directory:
cat /volume1/docker/kometa/kempfplex1/logs/meta.log
```

### Common Issues:

**Issue: "Plex Error: Unauthorized"**
- Check your `KOMETA_PLEXTOKEN` is correct
- Ensure Plex URL is accessible from the container

**Issue: "Config file not found"**
- Verify volume mount: `/config` should point to your config directory
- Check file permissions

**Issue: "TMDb API Error"**
- Verify `KOMETA_TMDBKEY` is set correctly
- Check TMDb API rate limits

**Issue: Overlays not applying**
- Ensure you're not running overlays on different schedules
- Check `remove_overlays: false` in config.yml
- Review logs for specific errors

## Updating Configuration

### To update shared config.yml:
1. Edit `config.yml` in your git repo
2. Commit and push changes
3. Pull changes on Synology: `git pull`
4. Restart all containers to pick up changes

### To update per-server settings:
1. Edit the specific `.env` file
2. Restart that server's container:
   ```bash
   docker restart kometa-kempfplex1
   ```

## Best Practices

1. **Keep config.yml in version control** - Track all changes via git
2. **Never commit .env files** - They contain secrets
3. **Use read-only mounts for shared config** - Prevents accidental modifications
4. **Separate logs and cache per server** - Easier troubleshooting
5. **Test on one server first** - Validate config before deploying to all servers
6. **Schedule runs during off-hours** - 3-5 AM to avoid API rate limits
7. **Monitor logs regularly** - Catch issues early
8. **Backup your .env files** - Store securely outside the container

## Security Notes

- **Never expose Plex tokens in logs or screenshots**
- **Use strong, unique tokens for Radarr/Sonarr**
- **Restrict container network access if possible**
- **Regularly update the Kometa image** for security patches
