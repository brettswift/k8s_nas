#!/usr/bin/env bash
# Test script for torrent scraper
# Runs the scraper in Docker to keep host clean
# Builds and caches a Docker image for faster subsequent runs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="${SCRIPT_DIR}/torrent-scraper.py"
IMAGE_NAME="torrent-scraper-test:latest"
TEMP_DOCKERFILE=$(mktemp)

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: torrent-scraper.py not found at $SCRIPT_FILE" >&2
    exit 1
fi

# Create temporary Dockerfile
cat > "$TEMP_DOCKERFILE" << 'DOCKERFILE'
FROM python:3.11-slim

# Install system dependencies for Playwright
RUN apt-get update -qq && \
    apt-get install -y -qq wget gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies (much simpler now - no Playwright needed!)
RUN pip install --no-cache-dir --quiet \
    requests

WORKDIR /scripts
DOCKERFILE

# Build image if it doesn't exist or if we need to rebuild
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "Building Docker image (this may take a few minutes, but will be cached)..."
    docker build -q -f "$TEMP_DOCKERFILE" -t "$IMAGE_NAME" . > /dev/null
    echo "✓ Image built and cached"
else
    echo "Using cached Docker image"
fi

# Clean up temp Dockerfile
rm -f "$TEMP_DOCKERFILE"

echo ""
echo "Running torrent scraper in Docker (TEST MODE)..."
echo "Script: $SCRIPT_FILE"
echo ""
echo ""

# Run using cached image
docker run --rm -it \
  -v "${SCRIPT_FILE}:/scripts/torrent-scraper.py:ro" \
  -v "$(mktemp -d):/var/log" \
  -e TEST_MODE=true \
  -e SCRAPE_URL="${SCRAPE_URL:-https://apibay.org/q.php?q=user:smcgill1969}" \
  -e QBT_URL="${QBT_URL:-http://127.0.0.1:8080}" \
  -e CHECK_INTERVAL="${CHECK_INTERVAL:-900}" \
  -e STATE_FILE="/tmp/scraper-state.json" \
  -e LOG_FILE="/var/log/scraper.log" \
  "$IMAGE_NAME" \
  python3 /scripts/torrent-scraper.py

