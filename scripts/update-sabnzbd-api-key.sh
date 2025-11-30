#!/bin/bash
# Update SABnzbd API key in Sonarr and Radarr

set -e

SABNZBD_API_KEY="${1:-8ae9fbed4b344a72908859434269067c}"
SONARR_API_KEY="${2:-aa91f40651d84c2bb03faadc07d9ccbc}"
RADARR_API_KEY="${3:-20c22574260f40d691b1256889ba0216}"

SONARR_URL="http://sonarr.media:8989/sonarr"
RADARR_URL="http://radarr.media:7878/radarr"

echo "Fetching Sonarr download clients..."
SONARR_CLIENTS=$(kubectl run -it --rm --restart=Never api-helper --image=curlimages/curl -- \
  curl -s "${SONARR_URL}/api/v3/downloadclient?apikey=${SONARR_API_KEY}" 2>/dev/null)

SABNZBD_ID=$(echo "$SONARR_CLIENTS" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$SABNZBD_ID" ]; then
  echo "SABnzbd not found in Sonarr. Creating new configuration..."
  # Create new SABnzbd client
  kubectl run -it --rm --restart=Never api-helper --image=curlimages/curl -- \
    curl -s -X POST "${SONARR_URL}/api/v3/downloadclient?apikey=${SONARR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"enable\":true,\"protocol\":\"usenet\",\"priority\":1,\"removeCompletedDownloads\":true,\"removeFailedDownloads\":true,\"name\":\"SABnzbd\",\"fields\":[{\"order\":0,\"name\":\"host\",\"value\":\"sabnzbd.media.svc.cluster.local\"},{\"order\":1,\"name\":\"port\",\"value\":8080},{\"order\":2,\"name\":\"urlBase\",\"value\":\"/sabnzbd\"},{\"order\":3,\"name\":\"apiKey\",\"value\":\"${SABNZBD_API_KEY}\"},{\"order\":4,\"name\":\"tvCategory\",\"value\":\"tv\"}],\"implementationName\":\"Sabnzbd\",\"implementation\":\"Sabnzbd\",\"configContract\":\"SabnzbdSettings\"}" 2>/dev/null
else
  echo "Found SABnzbd in Sonarr (ID: $SABNZBD_ID). Updating API key..."
  # Get current config and update apiKey field
  CURRENT_CONFIG=$(kubectl run -it --rm --restart=Never api-helper --image=curlimages/curl -- \
    curl -s "${SONARR_URL}/api/v3/downloadclient/${SABNZBD_ID}?apikey=${SONARR_API_KEY}" 2>/dev/null)
  
  # Update the apiKey field in the fields array
  UPDATED_CONFIG=$(echo "$CURRENT_CONFIG" | sed "s/\"name\":\"apiKey\",\"value\":\"[^\"]*\"/\"name\":\"apiKey\",\"value\":\"${SABNZBD_API_KEY}\"/")
  
  kubectl run -it --rm --restart=Never api-helper --image=curlimages/curl -- \
    curl -s -X PUT "${SONARR_URL}/api/v3/downloadclient/${SABNZBD_ID}?apikey=${SONARR_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$UPDATED_CONFIG" 2>/dev/null
fi

echo ""
echo "Done updating Sonarr. Check the UI to verify."

