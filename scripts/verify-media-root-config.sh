#!/bin/bash
# Verify media root folder configuration
# Checks volume mounts, directory existence, and access

set -e

echo "=== Verifying Media Root Folder Configuration ==="
echo ""

# Check Sonarr pod
echo "1. Checking Sonarr pod..."
SONARR_POD=$(kubectl get pods -n media -l app=sonarr -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$SONARR_POD" ]; then
  echo "   ⚠️  Sonarr pod not found"
else
  echo "   ✅ Sonarr pod: $SONARR_POD"
  
  # Check volume mounts
  echo "   Checking volume mounts..."
  kubectl get pod -n media "$SONARR_POD" -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -q "/usenet" && \
    echo "   ✅ /usenet mount found" || echo "   ⚠️  /usenet mount not found"
  kubectl get pod -n media "$SONARR_POD" -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -q "/data" && \
    echo "   ✅ /data mount found" || echo "   ⚠️  /data mount not found"
  
  # Check directory access
  echo "   Checking directory access..."
  kubectl exec -n media "$SONARR_POD" -- ls -d /data/media/series > /dev/null 2>&1 && \
    echo "   ✅ /data/media/series accessible" || echo "   ⚠️  /data/media/series not accessible"
  kubectl exec -n media "$SONARR_POD" -- ls -d /usenet/complete > /dev/null 2>&1 && \
    echo "   ✅ /usenet/complete accessible" || echo "   ⚠️  /usenet/complete not accessible"
fi

echo ""

# Check Radarr pod
echo "2. Checking Radarr pod..."
RADARR_POD=$(kubectl get pods -n media -l app=radarr -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$RADARR_POD" ]; then
  echo "   ⚠️  Radarr pod not found"
else
  echo "   ✅ Radarr pod: $RADARR_POD"
  
  # Check volume mounts
  echo "   Checking volume mounts..."
  kubectl get pod -n media "$RADARR_POD" -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -q "/usenet" && \
    echo "   ✅ /usenet mount found" || echo "   ⚠️  /usenet mount not found"
  kubectl get pod -n media "$RADARR_POD" -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -q "/data" && \
    echo "   ✅ /data mount found" || echo "   ⚠️  /data mount not found"
  
  # Check directory access
  echo "   Checking directory access..."
  kubectl exec -n media "$RADARR_POD" -- ls -d /data/media/movies > /dev/null 2>&1 && \
    echo "   ✅ /data/media/movies accessible" || echo "   ⚠️  /data/media/movies not accessible"
  kubectl exec -n media "$RADARR_POD" -- ls -d /usenet/complete > /dev/null 2>&1 && \
    echo "   ✅ /usenet/complete accessible" || echo "   ⚠️  /usenet/complete not accessible"
fi

echo ""

# Check host directories (if accessible)
echo "3. Checking host directories..."
if [ -d "/mnt/data/media/series" ]; then
  echo "   ✅ /mnt/data/media/series exists"
  ls -ld /mnt/data/media/series
else
  echo "   ⚠️  /mnt/data/media/series does not exist (run scripts/create-media-root-folders.sh)"
fi

if [ -d "/mnt/data/media/movies" ]; then
  echo "   ✅ /mnt/data/media/movies exists"
  ls -ld /mnt/data/media/movies
else
  echo "   ⚠️  /mnt/data/media/movies does not exist (run scripts/create-media-root-folders.sh)"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Run scripts/create-media-root-folders.sh on the host to create directories"
echo "2. Configure root folders in Sonarr UI: Settings → Media Management → Root Folders → Add '/data/media/series'"
echo "3. Configure root folders in Radarr UI: Settings → Media Management → Root Folders → Add '/data/media/movies'"
echo "4. Fix SABnzbd remote path mappings in Sonarr/Radarr: Remote: /data/usenet/complete, Local: /usenet/complete"

