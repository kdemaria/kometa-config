# Kometa Configuration Project

## Project Overview

This is a shared Kometa (formerly Plex Meta Manager) configuration project designed to manage metadata, collections, and overlays across multiple Plex servers. The configurations are deployed to dedicated containers, with each container serving a specific Plex server instance.

## What is Kometa?

Kometa is an automation tool that enhances Plex libraries by:
- Creating and managing collections (franchises, genres, studios, etc.)
- Applying overlays to posters (resolution badges, ratings, ribbons)
- Organizing metadata consistently across libraries
- Integrating with external services (TMDb, IMDb, Radarr, Sonarr, etc.)

## Project Purpose

- **Multi-server deployment**: Single source of truth for Kometa configs across multiple Plex instances
- **Consistency**: Maintain uniform collection and overlay standards across all servers
- **Containerized**: Each Plex server has a dedicated Kometa container using these configs
- **Centralized management**: Edit once, deploy to multiple servers

## Configuration Structure

### Required Connections
- **Plex**: Connection to Plex Media Server (REQUIRED)
  - URL, token, timeout settings
  - Per-server configuration needed
- **TMDb**: The Movie Database API (REQUIRED)
  - API key for metadata fetching
  - Cache and language settings

### Library Types

The configuration supports multiple library types:
- **Movies**: Feature films with collections, overlays, and metadata
- **TV Shows**: Television series with episode/season management
- **Anime**: Specialized anime collections (optional)
- **Music**: Music library management (optional)

### Key Configuration Sections

1. **collection_files**: Define what collections to create
   - `default:` - Built-in Kometa defaults (basic, imdb, studio, streaming, franchises, etc.)
   - `file:` - Local custom configuration files
   - `git:` - Remote configurations from Git repositories

2. **overlay_files**: Visual overlays on posters
   - Common: ribbon, resolution, audio_codec
   - Applied as image layers on existing posters

3. **metadata_files**: Custom metadata and attributes

4. **Integration Services**:
   - **Radarr**: Movie automation (add missing, quality profiles)
   - **Sonarr**: TV show automation (monitoring, series types)
   - **OMDb**: Additional movie database
   - **Trakt/MAL/AniDB**: Optional tracking services

## Configuration Conventions

### File Organization
- Main configuration files should be named descriptively (e.g., `kempfplex1.yml`, `server2.yml`)
- Custom metadata files in `config/metadata/` directory
- Assets in `config/assets/` with folder structure matching library organization

### Settings Standards
- **sync_mode**: `append` - Add to collections without removing existing items
- **minimum_items**: `1` - Collections need at least 1 item to be created
- **delete_below_minimum**: `true` - Remove collections that fall below minimum
- **asset_folders**: `true` - Use folder structure for assets
- **overlay_artwork_filetype**: `webp_lossy` - Efficient image format for overlays
- **run_order**: operations → metadata → collections → overlays

### Sensitive Information
- **Never commit tokens/API keys to version control**
- Plex tokens, TMDb API keys, Radarr/Sonarr tokens should be environment variables or externalized
- Use placeholders in committed configs

### Library Naming
- Library names in config MUST exactly match Plex library names
- Common names: "Movies", "TV Shows", "Anime", "Music"

## Template Variables

Many default files support template variables for customization:
- `style`: Visual style (e.g., diiivoycolor, signature, standards)
- `data.depth`: How deep to search for actors/metadata
- `data.limit`: Maximum items in collections
- `collection_section`: Numbering for collection ordering
- `exclude`: Items to exclude from collections

## Common Workflow

1. **Per-Server Setup**:
   - Copy base configuration
   - Update Plex URL and token for specific server
   - Adjust Radarr/Sonarr URLs and tokens if applicable
   - Configure library-specific settings

2. **Collection Management**:
   - Enable/disable collection files by commenting/uncommenting
   - Use template_variables to customize behavior
   - Test with single library before deploying widely

3. **Overlay Application**:
   - Set `remove_overlays: false` for normal operation
   - Set `remove_overlays: true` to strip all overlays
   - Use `reset_overlays: tmdb` to restore original posters

## Deployment Notes

- Each Plex server runs its own Kometa container
- Containers mount this shared configuration directory
- Schedule runs via cron or Kometa's built-in scheduler
- Monitor logs for API rate limits and errors

## Troubleshooting

- **Collections not appearing**: Check `minimum_items` and `delete_below_minimum`
- **Overlays not applying**: Verify image paths and `overlay_artwork_filetype`
- **API errors**: Check cache_expiration settings and rate limits
- **Missing items**: Review `add_missing` settings in Radarr/Sonarr integration

## External Resources

- [Kometa Wiki](https://kometa.wiki/)
- [Default Collections Reference](https://kometa.wiki/en/latest/defaults/guide/)
- [Overlay Guide](https://kometa.wiki/en/latest/defaults/overlays/)
- [Template Variables](https://kometa.wiki/en/latest/files/templates/)
