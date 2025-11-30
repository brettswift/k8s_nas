#!/bin/bash
# Add SABnzbd download client to Sonarr and Radarr via API

set -e

SABNZBD_API_KEY="${1:-8ae9fbed4b344a72908859434269067c}"
SONARR_API_KEY="${2:-aa91f40651d84c2bb03faadc07d9ccbc}"
RADARR_API_KEY="${3:-20c22574260f40d691b1256889ba0216}"

SONARR_URL="http://sonarr.media:8989/sonarr"
RADARR_URL="http://radarr.media:7878/radarr"
SABNZBD_HOST="sabnzbd.media.svc.cluster.local"
SABNZBD_PORT="8080"
SABNZBD_URL_BASE="/sabnzbd"

echo "Adding SABnzbd to Sonarr..."
curl -s -X POST "${SONARR_URL}/api/v3/downloadclient?apikey=${SONARR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"enable\": true,
    \"protocol\": \"usenet\",
    \"priority\": 1,
    \"removeCompletedDownloads\": true,
    \"removeFailedDownloads\": true,
    \"name\": \"SABnzbd\",
    \"fields\": [
      {\"order\": 0, \"name\": \"host\", \"value\": \"${SABNZBD_HOST}\"},
      {\"order\": 1, \"name\": \"port\", \"value\": ${SABNZBD_PORT}},
      {\"order\": 2, \"name\": \"urlBase\", \"value\": \"${SABNZBD_URL_BASE}\"},
      {\"order\": 3, \"name\": \"apiKey\", \"value\": \"${SABNZBD_API_KEY}\"},
      {\"order\": 4, \"name\": \"tvCategory\", \"value\": \"tv\"},
      {\"order\": 5, \"name\": \"recentTvPriority\", \"value\": 0},
      {\"order\": 6, \"name\": \"olderTvPriority\", \"value\": 0},
      {\"order\": 7, \"name\": \"useSsl\", \"value\": false}
    ],
    \"implementationName\": \"Sabnzbd\",
    \"implementation\": \"Sabnzbd\",
    \"configContract\": \"SabnzbdSettings\",
    \"infoLink\": \"https://wiki.servarr.com/sonarr/supported#sabnzbd\"
  }" | python3 -m json.tool 2>/dev/null || echo "Response received"

echo ""
echo "Adding SABnzbd to Radarr..."
curl -s -X POST "${RADARR_URL}/api/v3/downloadclient?apikey=${RADARR_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"enable\": true,
    \"protocol\": \"usenet\",
    \"priority\": 1,
    \"removeCompletedDownloads\": true,
    \"removeFailedDownloads\": true,
    \"name\": \"SABnzbd\",
    \"fields\": [
      {\"order\": 0, \"name\": \"host\", \"value\": \"${SABNZBD_HOST}\"},
      {\"order\": 1, \"name\": \"port\", \"value\": ${SABNZBD_PORT}},
      {\"order\": 2, \"name\": \"urlBase\", \"value\": \"${SABNZBD_URL_BASE}\"},
      {\"order\": 3, \"name\": \"apiKey\", \"value\": \"${SABNZBD_API_KEY}\"},
      {\"order\": 4, \"name\": \"movieCategory\", \"value\": \"movies\"},
      {\"order\": 5, \"name\": \"recentMoviePriority\", \"value\": 0},
      {\"order\": 6, \"name\": \"olderMoviePriority\", \"value\": 0},
      {\"order\": 7, \"name\": \"useSsl\", \"value\": false}
    ],
    \"implementationName\": \"Sabnzbd\",
    \"implementation\": \"Sabnzbd\",
    \"configContract\": \"SabnzbdSettings\",
    \"infoLink\": \"https://wiki.servarr.com/radarr/supported#sabnzbd\"
  }" | python3 -m json.tool 2>/dev/null || echo "Response received"

echo ""
echo "Done! Check Sonarr and Radarr UIs to verify SABnzbd is configured."

