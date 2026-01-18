# Kometa Multi-Server Configuration

Shared Kometa configuration for managing multiple Plex servers with consistent collections, overlays, and metadata.

## Quick Start

**Using Docker Compose (Recommended):**

```bash
# Clone repository
mkdir -p /volume1/docker/kometa
cd /volume1/docker/kometa
git clone https://github.com/kdemaria/kometa-config.git
cd kometa-config

# Create secrets file
cp env.compose.example .env
nano .env  # Fill in your tokens

# Start all containers
docker-compose up -d
```

See [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) for complete Docker Compose deployment guide.

## What's Included

- **config.yml** - Shared Kometa configuration with:
  - Award collections (Oscars, Emmys, Golden Globes)
  - Seasonal/holiday collections
  - Genre, studio, streaming service collections
  - Actor/director collections with colorful poster styles
  - Modern overlays (4K HDR, Dolby Vision, ratings, streaming logos)

- **docker-compose.yml** - Deploy to multiple Plex servers
- **env.compose.example** - Template for shared secrets

## Documentation

- [DOCKER-COMPOSE.md](DOCKER-COMPOSE.md) - Docker Compose deployment (recommended)
- [SERVERS.md](SERVERS.md) - Managing your Plex servers (add/remove/modify)
- [DEPLOYMENT.md](DEPLOYMENT.md) - Alternative deployment methods
- [CLAUDE.MD](CLAUDE.MD) - Project documentation for AI assistants

## Features

✅ **Multi-server support** - Single config, multiple Plex instances
✅ **Auto-sync from GitHub** - Always uses latest config
✅ **Shared secrets** - One .env file for all servers
✅ **Beautiful collections** - Oscar winners, franchises, genres, etc.
✅ **Modern overlays** - 4K HDR, Dolby Vision, ratings, streaming logos
✅ **Isolated logs/cache** - Per-server Docker volumes

## Architecture

**Shared:**
- config.yml (pulled from GitHub)
- All API keys/tokens (same Plex account)

**Unique per server:**
- Plex URL only
- Logs and cache directories

## Requirements

- Docker & Docker Compose
- Plex Media Server(s)
- TMDb API key (free)
- OMDb API key (free)
- Optional: Radarr, Sonarr

## License

MIT
