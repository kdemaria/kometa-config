#!/bin/bash
# Kometa Docker Compose Troubleshooting Script

echo "=== Kometa Troubleshooting ==="
echo ""

echo "1. Checking if .env file exists..."
if [ -f .env ]; then
  echo "   ✓ .env file found"
  echo "   Variables defined:"
  grep -v '^#' .env | grep -v '^$' | cut -d'=' -f1 | sed 's/^/     - /'
else
  echo "   ✗ .env file NOT found - this is required!"
fi
echo ""

echo "2. Checking if docker-compose.yml exists..."
if [ -f docker-compose.yml ]; then
  echo "   ✓ docker-compose.yml found"
else
  echo "   ✗ docker-compose.yml NOT found - run ./generate-compose.sh"
fi
echo ""

echo "3. Checking Docker containers status..."
docker-compose ps 2>/dev/null || echo "   ✗ docker-compose not available or no containers"
echo ""

echo "4. Checking config-sync logs (if container exists)..."
docker logs kometa-config-sync 2>/dev/null | tail -20 || echo "   ✗ config-sync container not found"
echo ""

echo "5. Checking Kometa container logs..."
for container in kometa-kempfnas2 kometa-kempfplex1 kometa-demaria-dt; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "   Container: $container"
    docker logs "$container" 2>&1 | tail -10 | sed 's/^/     /'
    echo ""
  fi
done

echo "6. Testing Plex connectivity from host..."
echo "   Testing kempfnas2 (host.docker.internal:32400):"
curl -s -o /dev/null -w "     HTTP Status: %{http_code}\n" http://localhost:32400 2>/dev/null || echo "     ✗ Cannot reach localhost:32400"

echo "   Testing kempfplex1 (kempfplex1:32400):"
ping -c 1 kempfplex1 >/dev/null 2>&1 && echo "     ✓ kempfplex1 is reachable" || echo "     ✗ kempfplex1 not reachable"

echo "   Testing DEMARIA-DT (10.200.201.99:32400):"
curl -s -o /dev/null -w "     HTTP Status: %{http_code}\n" http://10.200.201.99:32400 2>/dev/null || echo "     ✗ Cannot reach 10.200.201.99:32400"

echo ""
echo "=== Troubleshooting Complete ==="
