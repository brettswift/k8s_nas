#!/bin/bash
# Extract all API keys from k8s services for znb360 Android app
# Run this on the k8s server (10.1.0.20)
# Usage: ./get-all-api-keys.sh

set -e

echo "🔑 Extracting API Keys from k8s Services"
echo "========================================="
echo ""

# Function to extract API key from pod config
extract_api_key_from_pod() {
    local namespace=$1
    local app_label=$2
    local config_path=$3
    local key_pattern=$4
    
    POD_NAME=$(kubectl get pods -n "$namespace" -l app="$app_label" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD_NAME" ]; then
        echo "❌ Pod not found: $app_label in $namespace"
        return 1
    fi
    
    if kubectl exec -n "$namespace" "$POD_NAME" -- test -f "$config_path" 2>/dev/null; then
        KEY=$(kubectl exec -n "$namespace" "$POD_NAME" -- cat "$config_path" 2>/dev/null | grep -oP "$key_pattern" | head -1 || echo "")
        if [ -n "$KEY" ]; then
            echo "$KEY"
            return 0
        fi
    fi
    return 1
}

# Function to extract from INI file
extract_api_key_from_ini() {
    local namespace=$1
    local app_label=$2
    local config_path=$3
    local key_name=$4
    
    POD_NAME=$(kubectl get pods -n "$namespace" -l app="$app_label" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -z "$POD_NAME" ]; then
        echo "❌ Pod not found: $app_label in $namespace"
        return 1
    fi
    
    if kubectl exec -n "$namespace" "$POD_NAME" -- test -f "$config_path" 2>/dev/null; then
        KEY=$(kubectl exec -n "$namespace" "$POD_NAME" -- grep -E "^${key_name}\s*=" "$config_path" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")
        if [ -n "$KEY" ]; then
            echo "$KEY"
            return 0
        fi
    fi
    return 1
}

# Extract keys
echo "Extracting API keys from running services..."
echo ""

# Sonarr
echo -n "Sonarr: "
SONARR_KEY=$(extract_api_key_from_pod "media" "sonarr" "/config/config.xml" '(?<=<ApiKey>)[^<]+' || echo "")
if [ -n "$SONARR_KEY" ]; then
    echo "$SONARR_KEY"
else
    echo "NOT FOUND"
fi

# Radarr
echo -n "Radarr: "
RADARR_KEY=$(extract_api_key_from_pod "media" "radarr" "/config/config.xml" '(?<=<ApiKey>)[^<]+' || echo "")
if [ -n "$RADARR_KEY" ]; then
    echo "$RADARR_KEY"
else
    echo "NOT FOUND"
fi

# Lidarr
echo -n "Lidarr: "
LIDARR_KEY=$(extract_api_key_from_pod "media" "lidarr" "/config/config.xml" '(?<=<ApiKey>)[^<]+' || echo "")
if [ -n "$LIDARR_KEY" ]; then
    echo "$LIDARR_KEY"
else
    echo "NOT FOUND"
fi

# Bazarr
echo -n "Bazarr: "
BAZARR_KEY=$(extract_api_key_from_pod "media" "bazarr" "/config/config.yaml" 'api_key:\s*([a-f0-9]{32})' || echo "")
if [ -z "$BAZARR_KEY" ]; then
    BAZARR_KEY=$(extract_api_key_from_pod "media" "bazarr" "/config/config.yaml" 'apikey:\s*([a-f0-9]{32})' || echo "")
fi
if [ -n "$BAZARR_KEY" ]; then
    echo "$BAZARR_KEY"
else
    echo "NOT FOUND"
fi

# Prowlarr
echo -n "Prowlarr: "
PROWLARR_KEY=$(extract_api_key_from_pod "media" "prowlarr" "/config/config.xml" '(?<=<ApiKey>)[^<]+' || echo "")
if [ -n "$PROWLARR_KEY" ]; then
    echo "$PROWLARR_KEY"
else
    echo "NOT FOUND"
fi

# Jellyseerr
echo -n "Jellyseerr: "
JELLYSEERR_KEY=$(extract_api_key_from_pod "media" "jellyseerr" "/config/config.json" '"apiKey"\s*:\s*"([^"]+)"' || echo "")
if [ -n "$JELLYSEERR_KEY" ]; then
    echo "$JELLYSEERR_KEY"
else
    echo "NOT FOUND"
fi

# SABnzbd
echo -n "SABnzbd: "
SABNZBD_KEY=$(extract_api_key_from_ini "media" "sabnzbd" "/config/sabnzbd.ini" "api_key" || echo "")
if [ -n "$SABNZBD_KEY" ]; then
    echo "$SABNZBD_KEY"
else
    echo "NOT FOUND"
fi

# qBittorrent (no API key, uses username/password)
echo -n "qBittorrent: "
QBT_USER="admin"
QBT_PASS=$(kubectl get secret qbittorrent-secrets -n qbittorrent -o jsonpath='{.data.WEBUI_PASSWORD}' 2>/dev/null | base64 -d || echo "")
if [ -n "$QBT_PASS" ]; then
    echo "Username: $QBT_USER, Password: $QBT_PASS"
else
    echo "NOT FOUND"
fi

echo ""
echo "=========================================="
echo "Summary for znb360:"
echo "=========================================="
echo ""
[ -n "$SONARR_KEY" ] && echo "Sonarr API: $SONARR_KEY"
[ -n "$RADARR_KEY" ] && echo "Radarr API: $RADARR_KEY"
[ -n "$LIDARR_KEY" ] && echo "Lidarr API: $LIDARR_KEY"
[ -n "$BAZARR_KEY" ] && echo "Bazarr API: $BAZARR_KEY"
[ -n "$PROWLARR_KEY" ] && echo "Prowlarr API: $PROWLARR_KEY"
[ -n "$JELLYSEERR_KEY" ] && echo "Jellyseerr API: $JELLYSEERR_KEY"
[ -n "$SABNZBD_KEY" ] && echo "SABnzbd API: $SABNZBD_KEY"
[ -n "$QBT_USER" ] && [ -n "$QBT_PASS" ] && echo "qBittorrent: $QBT_USER / $QBT_PASS"
echo ""

