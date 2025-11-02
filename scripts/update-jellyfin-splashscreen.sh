#!/bin/bash
# Update Jellyfin splash screen image
# Usage: ./scripts/update-jellyfin-splashscreen.sh <path-to-image-file>

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $0 <path-to-image-file>"
  echo ""
  echo "Example:"
  echo "  $0 /path/to/my-splashscreen.png"
  echo ""
  echo "The image will be copied to Jellyfin's config directory with correct permissions."
  exit 1
fi

IMAGE_FILE="$1"
POD_NAME=$(kubectl get pods -n media -l app=jellyfin -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  echo "❌ Error: Jellyfin pod not found"
  exit 1
fi

if [ ! -f "$IMAGE_FILE" ]; then
  echo "❌ Error: Image file not found: $IMAGE_FILE"
  exit 1
fi

echo "📦 Copying splash screen image to Jellyfin pod..."
echo "   Source: $IMAGE_FILE"
echo "   Destination: /config/data/splashscreen.png"
echo ""

# Copy file to pod's /tmp first
kubectl cp "$IMAGE_FILE" "media/$POD_NAME:/tmp/splashscreen.png"

# Move to final location and set permissions
kubectl exec -n media "$POD_NAME" -- sh -c "
  mv /tmp/splashscreen.png /config/data/splashscreen.png && \
  chown 1000:1000 /config/data/splashscreen.png && \
  chmod 644 /config/data/splashscreen.png && \
  echo '✅ Splash screen updated successfully'
"

echo ""
echo "✅ Done! The splash screen should appear after refreshing Jellyfin."
echo "   Note: You may need to refresh the browser or restart Jellyfin for changes to take effect."

