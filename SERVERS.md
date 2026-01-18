# Server Configuration Guide

This project uses a **dynamic server configuration** system that makes it easy to add, remove, or modify Plex servers without manually editing the docker-compose.yml file.

## How It Works

1. **servers.txt** - Contains your list of Plex servers
2. **generate-compose.sh** - Generates docker-compose.yml from servers.txt
3. **docker-compose.yml** - Generated file (don't edit manually!)

---

## Managing Servers

### View Current Servers

```bash
cat servers.txt
```

### Add a New Server

Edit `servers.txt` and add a line in this format:

```
CONTAINER_NAME|PLEX_URL|DISPLAY_NAME
```

**Example:**
```
kometa-newserver|http://newserver:32400|My New Server
```

**Field Explanations:**
- `CONTAINER_NAME` - Docker container name (use `kometa-` prefix)
- `PLEX_URL` - Full URL to your Plex server (with port)
- `DISPLAY_NAME` - Human-readable name for documentation

### Remove a Server

Simply delete or comment out (add `#` at the start) the line in `servers.txt`:

```
# kometa-oldserver|http://oldserver:32400|Old Server
```

### Modify a Server

Edit the line in `servers.txt` with the new values.

---

## Current Server Configuration

Your current servers (from servers.txt):

```
kometa-kempfnas2|http://kempfnas2:32400|kempfnas2
kometa-kempfplex1|http://kempfplex1:32400|kempfplex1
kometa-demaria-dt|http://10.200.201.99:32400|DEMARIA-DT
```

---

## Regenerating docker-compose.yml

After making any changes to `servers.txt`, regenerate the docker-compose.yml file:

```bash
cd /volume1/docker/kometa/kometa-config
./generate-compose.sh
```

This will:
1. Read all servers from `servers.txt`
2. Generate a new `docker-compose.yml` file
3. Create service definitions for each server
4. Create volume definitions for logs and cache

**Output Example:**
```
✅ docker-compose.yml generated successfully from servers.txt

Server configuration:
  - kempfnas2: http://kempfnas2:32400
  - kempfplex1: http://kempfplex1:32400
  - DEMARIA-DT: http://10.200.201.99:32400
```

---

## Applying Changes

After regenerating docker-compose.yml, apply the changes:

```bash
# Stop existing containers
docker-compose down

# Start with new configuration
docker-compose up -d
```

---

## Examples

### Example 1: Add a New Plex Server

1. Edit `servers.txt`:
   ```bash
   nano servers.txt
   ```

2. Add new server:
   ```
   kometa-kempfnas3|http://kempfnas3:32400|kempfnas3
   ```

3. Regenerate and deploy:
   ```bash
   ./generate-compose.sh
   docker-compose down
   docker-compose up -d
   ```

### Example 2: Change a Server's IP Address

1. Edit `servers.txt`:
   ```bash
   nano servers.txt
   ```

2. Update the URL:
   ```
   # Old:
   # kometa-demaria-dt|http://10.200.201.99:32400|DEMARIA-DT

   # New:
   kometa-demaria-dt|http://10.200.201.100:32400|DEMARIA-DT
   ```

3. Regenerate and deploy:
   ```bash
   ./generate-compose.sh
   docker-compose restart kometa-demaria-dt
   ```

### Example 3: Temporarily Disable a Server

1. Comment out the server in `servers.txt`:
   ```bash
   nano servers.txt
   ```

   ```
   # kometa-kempfnas2|http://kempfnas2:32400|kempfnas2
   kometa-kempfplex1|http://kempfplex1:32400|kempfplex1
   kometa-demaria-dt|http://10.200.201.99:32400|DEMARIA-DT
   ```

2. Regenerate and deploy:
   ```bash
   ./generate-compose.sh
   docker-compose up -d
   ```

---

## Important Notes

### Don't Edit docker-compose.yml Directly

The `docker-compose.yml` file is **generated** from `servers.txt`. Any manual edits will be overwritten when you run `./generate-compose.sh`.

### Server Names

- Container names should start with `kometa-` for consistency
- The part after `kometa-` is used for volume names (logs/cache)
- Use lowercase and hyphens (not spaces or underscores)

### Shared Secrets

All servers use the **same secrets** from the `.env` file:
- `PLEX_TOKEN` - Same Plex account for all servers
- `TMDB_KEY` - Shared TMDb API key
- `OMDB_KEY` - Shared OMDb API key
- `RADARR_TOKEN` - Shared Radarr token
- `SONARR_TOKEN` - Shared Sonarr token

Only the `PLEX_URL` is unique per server.

### IP Addresses vs Hostnames

You can use either:
- Hostnames: `http://kempfplex1:32400`
- IP addresses: `http://10.200.201.99:32400`

Hostnames are recommended for easier maintenance.

---

## Troubleshooting

### generate-compose.sh: Permission denied

Make the script executable:
```bash
chmod +x generate-compose.sh
```

### Invalid server format

Ensure each line in `servers.txt` uses exactly 2 pipe characters (`|`):
```
CORRECT:   kometa-server|http://server:32400|Server Name
INCORRECT: kometa-server http://server:32400 Server Name
```

### Containers not starting after regeneration

Check that you ran `docker-compose down` before `docker-compose up -d`:
```bash
docker-compose down
docker-compose up -d
```

### Old containers still running

List all Kometa containers:
```bash
docker ps -a | grep kometa
```

Remove old containers manually:
```bash
docker rm -f kometa-oldserver
```

---

## Git Workflow

The `servers.txt` file **is tracked in git**, so you can version control your server configuration:

```bash
# After updating servers.txt
./generate-compose.sh
git add servers.txt docker-compose.yml
git commit -m "Add new Plex server: kempfnas3"
git push
```

**Note:** The generated `docker-compose.yml` can be committed to git for reference, but it will be regenerated on each deployment.

---

## Benefits of This Approach

✅ **Single source of truth** - All servers defined in one simple file
✅ **Easy to add/remove servers** - Edit one line, regenerate
✅ **Version controlled** - Track server changes in git
✅ **No manual YAML editing** - Script handles all the boilerplate
✅ **Consistent structure** - All servers configured identically
✅ **Self-documenting** - servers.txt shows all your Plex servers at a glance
