#!/bin/bash
# Extract API Keys from All Running Starr Services
# Updates starr-secrets Secret with extracted keys

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

echo "🔑 Extracting API Keys from All Starr Services"
echo "================================================"
echo ""

# Function to extract API key from pod
extract_api_key_from_pod() {
    local app=$1
    local config_path=$2
    local grep_pattern=$3
    local name=$4
    
    POD_NAME=$(kubectl get pods -n media -l app="$app" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD_NAME" ]; then
        echo "⚠️  $name: Pod not running, skipping..."
        echo ""
        return 1
    fi
    
    echo "📦 $name: Extracting from pod $POD_NAME..."
    
    # Wait for config file to exist
    for i in {1..10}; do
        if kubectl exec -n media "$POD_NAME" -- test -f "$config_path" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    
    if kubectl exec -n media "$POD_NAME" -- test -f "$config_path" 2>/dev/null; then
        KEY=$(kubectl exec -n media "$POD_NAME" -- cat "$config_path" 2>/dev/null | eval "$grep_pattern" | head -1 || echo "")
        if [ -n "$KEY" ]; then
            echo "✅ $name: Extracted: ${KEY:0:10}..."
            echo "$KEY"
            return 0
        else
            echo "⚠️  $name: Config exists but API key not found (may need initial setup)"
            return 1
        fi
    else
        echo "⚠️  $name: Config file not found (service may need initial setup)"
        return 1
    fi
}

# Extract keys from running services
SONARR_KEY=""
RADARR_KEY=""
PROWLARR_KEY=""
SABNZBD_KEY=""
LIDARR_KEY=""
BAZARR_KEY=""
JELLYSEERR_KEY=""

echo "Extracting API keys from running services..."
echo ""

# Sonarr
SONARR_KEY=$(extract_api_key_from_pod "sonarr" "/config/config.xml" "grep '<ApiKey>' | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/'" "Sonarr") || SONARR_KEY=""
echo ""

# Radarr
RADARR_KEY=$(extract_api_key_from_pod "radarr" "/config/config.xml" "grep '<ApiKey>' | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/'" "Radarr") || RADARR_KEY=""
echo ""

# Prowlarr
PROWLARR_KEY=$(extract_api_key_from_pod "prowlarr" "/config/config.xml" "grep '<ApiKey>' | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/'" "Prowlarr") || PROWLARR_KEY=""
echo ""

# SABnzbd (different config format - INI file)
POD_NAME=$(kubectl get pods -n media -l app=sabnzbd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo "📦 SABnzbd: Extracting from pod $POD_NAME..."
    # Try multiple possible config file locations
    for config_file in /config/sabnzbd.ini /config/config.ini /config/config/config.ini; do
        if kubectl exec -n media "$POD_NAME" -- test -f "$config_file" 2>/dev/null; then
            SABNZBD_KEY=$(kubectl exec -n media "$POD_NAME" -- cat "$config_file" 2>/dev/null | grep -E "^api_key\s*=" | head -1 | sed 's/.*=\s*//' | tr -d ' ' || echo "")
            if [ -n "$SABNZBD_KEY" ]; then
                echo "✅ SABnzbd: Extracted from $config_file: ${SABNZBD_KEY:0:10}..."
                break
            fi
        fi
    done
    if [ -z "$SABNZBD_KEY" ]; then
        echo "⚠️  SABnzbd: API key not found (may need to check UI: Config → General → API Key)"
    fi
else
    echo "⚠️  SABnzbd: Pod not running, skipping..."
fi
echo ""

# Lidarr (if running)
LIDARR_KEY=$(extract_api_key_from_pod "lidarr" "/config/config.xml" "grep '<ApiKey>' | sed 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/'" "Lidarr") || LIDARR_KEY=""
echo ""

# Bazarr (if running)
BAZARR_KEY=$(extract_api_key_from_pod "bazarr" "/config/config/config.xml" "grep '<api_key>' | sed 's/.*<api_key>\(.*\)<\/api_key>.*/\1/'" "Bazarr") || BAZARR_KEY=""
echo ""

# Jellyseerr (if running - different format, may need UI extraction)
POD_NAME=$(kubectl get pods -n media -l app=jellyseerr -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo "📦 Jellyseerr: Checking pod $POD_NAME..."
    # Jellyseerr API key is in database, harder to extract
    echo "⚠️  Jellyseerr: API key must be extracted from UI (Settings → Services)"
else
    echo "⚠️  Jellyseerr: Pod not running, skipping..."
fi
echo ""

# Get existing secret values to preserve
echo "Reading existing secret values..."
EXISTING_SONARR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_RADARR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.RADARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_PROWLARR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_SABNZBD=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.SABNZBD_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_LIDARR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.LIDARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_BAZARR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.BAZARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
EXISTING_JELLYSEERR=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.JELLYSEERR_API_KEY}' 2>/dev/null | base64 -d || echo "")

# Use extracted keys if found, otherwise keep existing values
SONARR_KEY=${SONARR_KEY:-$EXISTING_SONARR}
RADARR_KEY=${RADARR_KEY:-$EXISTING_RADARR}
PROWLARR_KEY=${PROWLARR_KEY:-$EXISTING_PROWLARR}
SABNZBD_KEY=${SABNZBD_KEY:-$EXISTING_SABNZBD}
LIDARR_KEY=${LIDARR_KEY:-$EXISTING_LIDARR}
BAZARR_KEY=${BAZARR_KEY:-$EXISTING_BAZARR}
JELLYSEERR_KEY=${JELLYSEERR_KEY:-$EXISTING_JELLYSEERR}

# Summary
echo "=========================================="
echo "API Keys Summary:"
echo "=========================================="
echo ""
[ -n "$SONARR_KEY" ] && echo "✅ Sonarr: ${SONARR_KEY:0:10}..." || echo "❌ Sonarr: NOT SET"
[ -n "$RADARR_KEY" ] && echo "✅ Radarr: ${RADARR_KEY:0:10}..." || echo "❌ Radarr: NOT SET"
[ -n "$PROWLARR_KEY" ] && echo "✅ Prowlarr: ${PROWLARR_KEY:0:10}..." || echo "❌ Prowlarr: NOT SET"
[ -n "$SABNZBD_KEY" ] && echo "✅ SABnzbd: ${SABNZBD_KEY:0:10}..." || echo "❌ SABnzbd: NOT SET"
[ -n "$LIDARR_KEY" ] && echo "✅ Lidarr: ${LIDARR_KEY:0:10}..." || echo "❌ Lidarr: NOT SET (not deployed)"
[ -n "$BAZARR_KEY" ] && echo "✅ Bazarr: ${BAZARR_KEY:0:10}..." || echo "❌ Bazarr: NOT SET (not deployed)"
[ -n "$JELLYSEERR_KEY" ] && echo "✅ Jellyseerr: ${JELLYSEERR_KEY:0:10}..." || echo "❌ Jellyseerr: NOT SET (not deployed or extract from UI)"
echo ""

# Update secret
echo "Updating starr-secrets Secret..."
kubectl create secret generic starr-secrets -n media \
  --from-literal=SONARR_API_KEY="${SONARR_KEY:-}" \
  --from-literal=RADARR_API_KEY="${RADARR_KEY:-}" \
  --from-literal=PROWLARR_API_KEY="${PROWLARR_KEY:-}" \
  --from-literal=SABNZBD_API_KEY="${SABNZBD_KEY:-}" \
  --from-literal=LIDARR_API_KEY="${LIDARR_KEY:-}" \
  --from-literal=BAZARR_API_KEY="${BAZARR_KEY:-}" \
  --from-literal=JELLYSEERR_API_KEY="${JELLYSEERR_KEY:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Secret updated successfully!"
echo ""

# Final verification
echo "=========================================="
echo "Verification:"
echo "=========================================="
echo ""
for key in SONARR_API_KEY RADARR_API_KEY PROWLARR_API_KEY SABNZBD_API_KEY LIDARR_API_KEY BAZARR_API_KEY JELLYSEERR_API_KEY; do
    VALUE=$(kubectl get secret starr-secrets -n media -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d || echo "")
    LEN=${#VALUE}
    if [ "$LEN" -gt 0 ]; then
        echo "✅ $key: Set (${LEN} chars)"
    else
        echo "⚠️  $key: Empty (service may not be deployed or needs manual extraction)"
    fi
done

echo ""
echo "=========================================="
echo "✅ API Key extraction complete!"
echo "=========================================="
echo ""
echo "Note: Services not yet deployed (Lidarr, Bazarr, Jellyseerr) will have empty keys."
echo "Extract their keys manually after deployment from their UIs."
echo ""

