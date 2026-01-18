# Docker Compose Deployment Guide

This guide covers deploying Kometa to multiple Plex servers using Docker Compose with a single shared config and secrets file.

## Prerequisites

Before starting, ensure your Synology NAS has:

1. **Docker & Docker Compose installed:**
   - Open Package Center
   - Search for "Container Manager" (formerly Docker)
   - Install Container Manager
   - Docker Compose is included with Container Manager

2. **Git installed:**
   - Open Package Center
   - Search for "Git Server"
   - Install Git Server
   - SSH into your Synology to verify: `git --version`

3. **SSH access enabled:**
   - Control Panel → Terminal & SNMP
   - Enable SSH service (port 22)

4. **Required API Keys:**
   - **TMDb API key** (free) - https://www.themoviedb.org/settings/api
   - **OMDb API key** (free) - http://www.omdbapi.com/apikey.aspx
   - **Plex token** - See "Getting Your Plex Token" section below

5. **Optional (if using):**
   - Radarr token (Settings → General → Security → API Key)
   - Sonarr token (Settings → General → Security → API Key)

---

## Architecture

**Single Config File:** `config.yml` - Shared across all servers (auto-updated from GitHub)

**Single Secrets File:** `.env` - Contains all shared secrets (same Plex account)

**Per-Service Configuration:** Only Plex URL differs (hardcoded in docker-compose.yml)

## Features

✅ **Auto-sync config from GitHub** - Pulls latest config.yml before containers start
✅ **Single secrets file** - All API keys in one place (shared Plex account)
✅ **Easy to add servers** - Just add a new service block
✅ **Isolated logs/cache** - Each server has its own Docker volume
✅ **Read-only config** - Prevents accidental modifications

---

## Setup Instructions

**Note:** This project uses a dynamic server configuration system. All Plex servers are defined in `servers.txt`, and the `docker-compose.yml` file is generated from it. See [SERVERS.md](SERVERS.md) for details on adding/removing servers.

### 1. Clone Repository on Synology

SSH into your Synology:

```bash
# Create base kometa directory
mkdir -p /volume1/docker/kometa

# Navigate to the kometa directory
cd /volume1/docker/kometa

# Clone the repository
git clone https://github.com/kdemaria/kometa-config.git

# Navigate into the repository
cd kometa-config
```

### 2. Create Secrets File

Copy the example and fill in your actual values:

```bash
cp env.compose.example .env
nano .env
```

Fill in these values (all shared across servers):
- `PLEX_TOKEN` - Your Plex token (same for all servers - same account)
- `TMDB_KEY` - Your TMDb API key
- `OMDB_KEY` - Your OMDb API key
- `RADARR_TOKEN` - Your Radarr token (optional)
- `SONARR_TOKEN` - Your Sonarr token (optional)
- `SHARED_METADATA_PATH` - Path to shared metadata directory (optional, see below)

**Important:** The `.env` file is gitignored and will never be committed.

#### Optional: Enable Shared Metadata

By default, each Kometa instance uses its own internal metadata storage. You can optionally configure all instances to share a centralized metadata directory on your NAS.

**To enable shared metadata:**

1. Create the shared metadata directory on your NAS:
   ```bash
   mkdir -p /volume1/demaria_ops/metadata
   ```

2. Set the path in your `.env` file:
   ```bash
   SHARED_METADATA_PATH=/volume1/demaria_ops/metadata
   ```

3. Regenerate docker-compose.yml (see step 3a below)

**Benefits:**
- All servers share the same custom assets (posters, backgrounds)
- Custom metadata files are centralized
- Easier to manage assets across multiple servers
- Reduces storage duplication

**To disable:** Leave `SHARED_METADATA_PATH` empty or remove it from `.env`

### 3. Configure Your Servers

Edit `servers.txt` to define your Plex servers:

```bash
cp servers.txt.example servers.txt
nano servers.txt
```

See [SERVERS.md](SERVERS.md) for details on the server configuration format.

### 3a. Generate docker-compose.yml

Run the generation script to create `docker-compose.yml` from your server list:

```bash
bash generate-compose.sh
```

This will:
- Read your servers from `servers.txt`
- Load configuration from `.env` (including `SHARED_METADATA_PATH` if set)
- Generate `docker-compose.yml` with the appropriate volume mounts
- Display a summary of your configuration

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

---

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

---

## Adding a New Server

To add a new Plex server:

1. **Add service to `docker-compose.yml`:**
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
       - KOMETA_PLEXTOKEN=${PLEX_TOKEN}
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

2. **Add volumes:**
   ```yaml
   volumes:
     kometa-newserver-logs:
     kometa-newserver-cache:
   ```

3. **Restart:**
   ```bash
   docker-compose up -d
   ```

**Note:** No need to update `.env` - all servers share the same Plex token!

---

## Getting Your Plex Token

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
   cd /volume1/docker/kometa/kometa-config
   docker-compose restart
   ```

### Option 3: Cron Job

Add to crontab:
```bash
0 3 * * * cd /volume1/docker/kometa-config && docker-compose restart
```

---

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

---

## Troubleshooting

### Config not updating from GitHub

Check config-sync logs:
```bash
docker-compose logs config-sync
```

Manually pull:
```bash
cd /volume1/docker/kometa-config
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

- Verify `PLEX_TOKEN` in `.env` file is correct
- Ensure Plex server is accessible from the container
- Check that all servers are on the same Plex account

### Changes to config.yml not taking effect

1. Ensure you pushed changes to GitHub
2. Restart containers (this pulls latest config):
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Git not installed on Synology

If you get "git: command not found":
1. Open Package Center
2. Search for "Git Server"
3. Install Git Server package
4. Verify: `git --version`

---

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
   cd /volume1/docker/kometa/kometa-config
   docker-compose down
   docker-compose up -d
   ```

### Update secrets

1. **Edit `.env` file:**
   ```bash
   nano /volume1/docker/kometa-config/.env
   ```

2. **Restart containers:**
   ```bash
   docker-compose restart
   ```

---

## Managing Shared Metadata

If you've enabled shared metadata via `SHARED_METADATA_PATH`, all Kometa instances will use the same metadata directory.

### Directory Structure

```
/volume1/demaria_ops/metadata/
├── assets/                        # Shared poster/background images
│   ├── Movies/
│   ├── TV Shows/
│   └── Collections/
├── collections/                   # Custom collection definitions
├── overlays/                      # Overlay definitions
└── custom/                        # Custom metadata files
```

### Adding Custom Assets

1. **Place images in the assets directory:**
   ```bash
   # Example: Custom poster for a movie
   /volume1/demaria_ops/metadata/assets/Movies/The Matrix (1999)/poster.jpg
   ```

2. **Kometa will automatically detect and use them** when it runs

### Updating Metadata Files

All servers read from the same `/config/metadata` directory (mounted from `SHARED_METADATA_PATH`):

```bash
# Edit a custom metadata file
nano /volume1/demaria_ops/metadata/custom/my-collection.yml

# Restart containers to apply changes
cd /volume1/docker/kometa/kometa-config
docker-compose restart
```

### Disabling Shared Metadata

To switch back to individual metadata storage:

1. Remove or empty `SHARED_METADATA_PATH` in `.env`
2. Regenerate docker-compose.yml:
   ```bash
   bash generate-compose.sh
   ```
3. Restart containers:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

---

## File Structure

```
/volume1/docker/kometa/
├── kometa-config/                 # Shared config repository
│   ├── .git/                      # Git repository
│   ├── .env                       # Your secrets (gitignored)
│   ├── config.yml                 # Shared Kometa config (from GitHub)
│   ├── docker-compose.yml         # Generated container definitions
│   ├── servers.txt                # Server list (gitignored)
│   ├── generate-compose.sh        # Generates docker-compose.yml
│   ├── env.compose.example        # Example secrets file
│   ├── servers.txt.example        # Example server list
│   └── README.md                  # Documentation
├── kempfplex1/                    # (Optional) Server-specific files
├── kempfnas2/                     # (Optional) Server-specific files
└── demaria-dt/                    # (Optional) Server-specific files

/volume1/demaria_ops/              # (Optional) Shared metadata storage
└── metadata/                      # Shared across all Kometa instances
    ├── assets/
    ├── collections/
    ├── overlays/
    └── custom/
```

---

## Security Notes

- The `.env` file is **never committed to git** (in .gitignore)
- Config is mounted **read-only** in containers
- Each server's cache and logs are isolated
- Plex tokens are kept in environment variables, not in config.yml
- All servers share the same Plex token (same account)

---

## Benefits Over Individual Containers

✅ **Single command to manage all servers** - `docker-compose up -d`
✅ **Shared secrets management** - One `.env` file for everything
✅ **Auto-sync config from GitHub** - Always uses latest config
✅ **Easy to add/remove servers** - Edit docker-compose.yml
✅ **Consistent deployment** - All servers use identical setup
✅ **Version controlled** - docker-compose.yml is in git
