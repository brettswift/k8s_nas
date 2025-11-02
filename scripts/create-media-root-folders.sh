#!/bin/bash
# Create media root folders for Sonarr and Radarr
# Run this script on the host where /mnt/data is mounted

set -e

MEDIA_BASE="/mnt/data/media"
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Creating media root folders..."
echo "Base path: $MEDIA_BASE"
echo "PUID: $PUID, PGID: $PGID"

# Create directories
sudo mkdir -p "$MEDIA_BASE/series"
sudo mkdir -p "$MEDIA_BASE/movies"

# Set ownership
sudo chown -R "${PUID}:${PGID}" "$MEDIA_BASE/series"
sudo chown -R "${PUID}:${PGID}" "$MEDIA_BASE/movies"

# Set permissions
sudo chmod 755 "$MEDIA_BASE/series"
sudo chmod 755 "$MEDIA_BASE/movies"

echo "✅ Created directories:"
ls -la "$MEDIA_BASE/" | grep -E "(series|movies)"

echo ""
echo "Verifying write access (testing from a pod if available)..."
if kubectl get pods -n media -l app=sonarr -o name > /dev/null 2>&1; then
  SONARR_POD=$(kubectl get pods -n media -l app=sonarr -o jsonpath='{.items[0].metadata.name}')
  if [ -n "$SONARR_POD" ]; then
    echo "Testing write access from Sonarr pod..."
    kubectl exec -n media "$SONARR_POD" -- touch /data/media/series/.test_write 2>/dev/null && \
      kubectl exec -n media "$SONARR_POD" -- rm /data/media/series/.test_write && \
      echo "✅ Write access verified for series folder" || \
      echo "⚠️  Could not verify write access for series folder"
    
    kubectl exec -n media "$SONARR_POD" -- touch /data/media/movies/.test_write 2>/dev/null && \
      kubectl exec -n media "$SONARR_POD" -- rm /data/media/movies/.test_write && \
      echo "✅ Write access verified for movies folder" || \
      echo "⚠️  Could not verify write access for movies folder"
  fi
fi

echo ""
echo "✅ Media root folders created successfully!"
echo "Next steps:"
echo "1. Configure root folders in Sonarr UI: Settings → Media Management → Root Folders → Add '/data/media/series'"
echo "2. Configure root folders in Radarr UI: Settings → Media Management → Root Folders → Add '/data/media/movies'"

