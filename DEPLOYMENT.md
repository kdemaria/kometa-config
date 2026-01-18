# Kometa Multi-Server Deployment Guide

## Recommended Deployment

**For the simplest deployment, use Docker Compose.** See [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) for the complete guide.

This document covers alternative deployment methods for advanced users.

---

## Architecture Overview

This configuration supports **multiple Plex servers** using a single shared `config.yml` file.

### What's Shared Across All Servers:
- `config.yml` - Collection and overlay definitions
- Plex token (same account)
- TMDb API key
- OMDb API key
- Radarr/Sonarr tokens

### What's Unique Per Server:
- Plex URL only (e.g., `http://kempfplex1:32400`)

---

## Alternative Deployment Methods

### Option 1: Synology Container Manager (Manual Setup)

**Note:** This is more complex than using Docker Compose. Consider using [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) instead.

#### Setup Steps:

1. **Clone repository on Synology:**
   ```bash
   cd /volume1/docker
   git clone https://github.com/kdemaria/kometa-config.git
   ```

2. **Create a shared .env file:**
   ```bash
   cd kometa-config
   cp env.compose.example .env
   nano .env
   ```

   Fill in all your secrets:
   - `PLEX_TOKEN` - Your Plex token (shared across all servers)
   - `TMDB_KEY` - TMDb API key
   - `OMDB_KEY` - OMDb API key
   - `RADARR_TOKEN` - Radarr token
   - `SONARR_TOKEN` - Sonarr token

3. **In Synology Container Manager, for each server:**

   **Container Settings:**
   - Image: `kometateam/kometa:latest`
   - Container Name: `kometa-kempfplex1` (or appropriate server name)
   - Restart Policy: "Always" or "Unless stopped"

   **Volume Mounts:**
   | Container Path | Host Path | Mode |
   |----------------|-----------|------|
   | `/config/config.yml` | `/volume1/docker/kometa-config/config.yml` | Read-only |
   | `/config/.env` | `/volume1/docker/kometa-config/.env` | Read-only |
   | `/config/logs` | `/volume1/docker/kometa-logs/kempfplex1` | Read/Write |
   | `/config/cache` | `/volume1/docker/kometa-cache/kempfplex1` | Read/Write |

   **Environment Variables:**
   - `KOMETA_PLEXURL=http://kempfplex1:32400` (change for each server)

   **Command:**
   ```
   --run --read-only-config
   ```

4. **Repeat for each server**, changing only:
   - Container name (`kometa-kempfnas2`, `kometa-demaria-dt`)
   - `KOMETA_PLEXURL` environment variable
   - Log/cache paths

---

### Option 2: Individual Docker Run Commands

**For kempfplex1:**
```bash
docker run -d \
  --name kometa-kempfplex1 \
  --restart unless-stopped \
  --env-file /volume1/docker/kometa-config/.env \
  -e KOMETA_PLEXURL=http://kempfplex1:32400 \
  -v /volume1/docker/kometa-config/config.yml:/config/config.yml:ro \
  -v kometa-kempfplex1-logs:/config/logs \
  -v kometa-kempfplex1-cache:/config/cache \
  kometateam/kometa:latest \
  --run --read-only-config
```

**For kempfnas2:**
```bash
docker run -d \
  --name kometa-kempfnas2 \
  --restart unless-stopped \
  --env-file /volume1/docker/kometa-config/.env \
  -e KOMETA_PLEXURL=http://kempfnas2:32400 \
  -v /volume1/docker/kometa-config/config.yml:/config/config.yml:ro \
  -v kometa-kempfnas2-logs:/config/logs \
  -v kometa-kempfnas2-cache:/config/cache \
  kometateam/kometa:latest \
  --run --read-only-config
```

**For DEMARIA-DT:**
```bash
docker run -d \
  --name kometa-demaria-dt \
  --restart unless-stopped \
  --env-file /volume1/docker/kometa-config/.env \
  -e KOMETA_PLEXURL=http://demaria-dt:32400 \
  -v /volume1/docker/kometa-config/config.yml:/config/config.yml:ro \
  -v kometa-demaria-dt-logs:/config/logs \
  -v kometa-demaria-dt-cache:/config/cache \
  kometateam/kometa:latest \
  --run --read-only-config
```

---

## Getting Your Plex Token

To find your Plex token:

**Method 1: Via Plex Web**
1. Open Plex Web App
2. Open any media item
3. Click "Get Info" → "View XML"
4. Look at the URL: `...?X-Plex-Token=YOURTOKEN`

**Method 2: Via SSH** (if you have access to the Plex server)
```bash
cat "$(find ~/.config/Plex\ Media\ Server/Preferences.xml 2>/dev/null)" | grep -oP 'PlexOnlineToken="\K[^"]+'
```

**Method 3: Via Kometa Documentation**
https://kometa.wiki/en/latest/config/plex/#getting-your-plex-token

---

## Scheduling Kometa Runs

### Option A: Use Kometa's Built-in Scheduler

Add to your `.env` file:
```bash
KOMETA_TIME=03:00  # Run at 3 AM daily
```

Or run continuously:
```bash
KOMETA_RUN=true
```

### Option B: Use Synology Task Scheduler

1. Open "Control Panel" → "Task Scheduler"
2. Create → "Scheduled Task" → "User-defined script"
3. Schedule: Daily at 3:00 AM
4. User-defined script:
   ```bash
   docker restart kometa-kempfplex1 kometa-kempfnas2 kometa-demaria-dt
   ```

### Option C: Cron

Add to crontab:
```
0 3 * * * docker restart kometa-kempfplex1 kometa-kempfnas2 kometa-demaria-dt
```

---

## Updating Configuration

### Update config.yml

1. Make changes to config.yml locally
2. Commit and push to GitHub:
   ```bash
   git add config.yml
   git commit -m "Update configuration"
   git push
   ```

3. On Synology, pull changes:
   ```bash
   cd /volume1/docker/kometa-config
   git pull
   ```

4. Restart containers:
   ```bash
   docker restart kometa-kempfplex1 kometa-kempfnas2 kometa-demaria-dt
   ```

### Update secrets (.env)

1. Edit the `.env` file:
   ```bash
   nano /volume1/docker/kometa-config/.env
   ```

2. Restart containers:
   ```bash
   docker restart kometa-kempfplex1 kometa-kempfnas2 kometa-demaria-dt
   ```

---

## Monitoring and Logs

### View logs:

**Container Manager:** Click container → "Details" → "Log"

**Docker CLI:**
```bash
docker logs kometa-kempfplex1

# Follow logs in real-time:
docker logs -f kometa-kempfplex1

# Check specific volume:
docker volume inspect kometa-kempfplex1-logs
```

---

## Common Issues

**Issue: "Plex Error: Unauthorized"**
- Check your `PLEX_TOKEN` in `.env` is correct
- Ensure Plex URL is accessible from the container
- Verify the Plex server is running

**Issue: "Config file not found"**
- Verify volume mount: `/config/config.yml` should point to your config file
- Check file permissions

**Issue: "TMDb API Error"**
- Verify `TMDB_KEY` is set correctly in `.env`
- Check TMDb API rate limits

**Issue: Overlays not applying**
- Ensure you're not running overlays on different schedules
- Check `remove_overlays: false` in config.yml
- Review logs for specific errors

**Issue: Config changes not taking effect**
- Ensure you pulled latest from GitHub: `git pull`
- Restart containers after updating config
- Check that config is mounted read-only to prevent local modifications

---

## Why Use Docker Compose Instead?

**Docker Compose provides:**
- ✅ Single command to manage all servers (`docker-compose up -d`)
- ✅ Auto-sync config from GitHub on startup
- ✅ Easier to add/remove servers
- ✅ Version controlled deployment configuration
- ✅ Simpler troubleshooting

See [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) for the recommended deployment method.

---

## Security Notes

- The `.env` file is **never committed to git** (in .gitignore)
- Config is mounted **read-only** in containers
- Each server's cache and logs are isolated
- Plex tokens are kept in environment variables, not in config.yml
- Never expose Plex tokens in logs or screenshots
