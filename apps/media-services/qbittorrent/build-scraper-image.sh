#!/usr/bin/env bash
# Build script for qBittorrent scraper Docker image
# Builds image with git commit hash tag for lazy loading/caching

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Get git commit hash (short)
GIT_COMMIT=$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "latest")
IMAGE_NAME="qbittorrent-scraper"
IMAGE_TAG="${IMAGE_NAME}:${GIT_COMMIT}"
IMAGE_LATEST="${IMAGE_NAME}:latest"

echo "Building scraper image: $IMAGE_TAG"
echo "Dockerfile: $SCRIPT_DIR/Dockerfile.scraper"

# Build image with commit hash tag
docker build -f "$SCRIPT_DIR/Dockerfile.scraper" -t "$IMAGE_TAG" -t "$IMAGE_LATEST" "$SCRIPT_DIR"

echo "✓ Image built: $IMAGE_TAG"
echo "✓ Also tagged as: $IMAGE_LATEST"
echo ""
echo "Image is available locally. k3s will use it automatically."
echo "To verify: docker images | grep $IMAGE_NAME"

