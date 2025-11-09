#!/bin/bash
# Extract API Keys from Starr Services
# This script helps extract API keys from running services via their UIs or config files

set -e

echo "🔑 API Key Extraction Helper"
echo "============================"
echo ""

# Method 1: Extract from service UI (manual)
echo "Method 1: Extract from Service UI (Recommended)"
echo "-----------------------------------------------"
echo ""
echo "For each running service, access the UI and get the API key:"
echo ""
echo "1. Sonarr: https://home.brettswift.com/sonarr"
echo "   → Settings → General → Security → API Key"
echo ""
echo "2. Radarr: https://home.brettswift.com/radarr"
echo "   → Settings → General → Security → API Key"
echo ""
echo "3. Sabnzbd: https://home.brettswift.com/sabnzbd"
echo "   → Config → General → API Key"
echo ""
echo ""

# Method 2: Try to extract from config files on server
echo "Method 2: Extract from Config Files (if accessible)"
echo "---------------------------------------------------"
echo ""
echo "Attempting to read API keys from service config files..."

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

# Function to extract API key from config.xml
extract_key_from_config() {
    local service=$1
    local config_path=$2
    
    if ssh bswift@10.0.0.20 "test -f $config_path" 2>/dev/null; then
        echo "Found config for $service, extracting API key..."
        ssh bswift@10.0.0.20 "grep -oP '(?<=<ApiKey>)[^<]+' $config_path 2>/dev/null | head -1" || echo ""
    else
        echo "Config file not found: $config_path"
        echo ""
    fi
}

# Try to extract keys from config files
echo "Checking config files on server..."
echo ""

SONARR_KEY=""
RADARR_KEY=""
SABNZBD_KEY=""

# Sonarr config
SONARR_CONFIG="/mnt/data/configs/sonarr/config.xml"
if ssh -o ConnectTimeout=5 bswift@10.0.0.20 "test -f $SONARR_CONFIG" 2>/dev/null; then
    echo "📁 Sonarr config found"
    SONARR_KEY=$(ssh bswift@10.0.0.20 "grep -oP '(?<=<ApiKey>)[^<]+' $SONARR_CONFIG 2>/dev/null | head -1" || echo "")
    if [ -n "$SONARR_KEY" ]; then
        echo "✅ Sonarr API Key extracted: ${SONARR_KEY:0:10}..."
    else
        echo "⚠️  Could not extract Sonarr API key from config"
    fi
else
    echo "⚠️  Sonarr config not accessible"
fi
echo ""

# Radarr config
RADARR_CONFIG="/mnt/data/configs/radarr/config.xml"
if ssh -o ConnectTimeout=5 bswift@10.0.0.20 "test -f $RADARR_CONFIG" 2>/dev/null; then
    echo "📁 Radarr config found"
    RADARR_KEY=$(ssh bswift@10.0.0.20 "grep -oP '(?<=<ApiKey>)[^<]+' $RADARR_CONFIG 2>/dev/null | head -1" || echo "")
    if [ -n "$RADARR_KEY" ]; then
        echo "✅ Radarr API Key extracted: ${RADARR_KEY:0:10}..."
    else
        echo "⚠️  Could not extract Radarr API key from config"
    fi
else
    echo "⚠️  Radarr config not accessible"
fi
echo ""

# Sabnzbd config (different format - INI file)
SABNZBD_CONFIG="/mnt/data/configs/sabnzbd/config.ini"
if ssh -o ConnectTimeout=5 bswift@10.0.0.20 "test -f $SABNZBD_CONFIG" 2>/dev/null; then
    echo "📁 Sabnzbd config found"
    SABNZBD_KEY=$(ssh bswift@10.0.0.20 "grep -E '^api_key\s*=' $SABNZBD_CONFIG 2>/dev/null | cut -d'=' -f2 | tr -d ' '" || echo "")
    if [ -n "$SABNZBD_KEY" ]; then
        echo "✅ Sabnzbd API Key extracted: ${SABNZBD_KEY:0:10}..."
    else
        echo "⚠️  Could not extract Sabnzbd API key from config"
    fi
else
    echo "⚠️  Sabnzbd config not accessible"
fi
echo ""

# Summary
echo "=========================================="
echo "Extracted Keys Summary:"
echo "=========================================="
echo ""
[ -n "$SONARR_KEY" ] && echo "✅ Sonarr: $SONARR_KEY" || echo "❌ Sonarr: NOT EXTRACTED"
[ -n "$RADARR_KEY" ] && echo "✅ Radarr: $RADARR_KEY" || echo "❌ Radarr: NOT EXTRACTED"
[ -n "$SABNZBD_KEY" ] && echo "✅ Sabnzbd: $SABNZBD_KEY" || echo "❌ Sabnzbd: NOT EXTRACTED"
echo ""

# Offer to create secret if keys extracted
if [ -n "$SONARR_KEY" ] || [ -n "$RADARR_KEY" ] || [ -n "$SABNZBD_KEY" ]; then
    echo "📝 Keys extracted! To create the secret, run:"
    echo ""
    echo "kubectl create secret generic starr-secrets -n media \\"
    [ -n "$SONARR_KEY" ] && echo "  --from-literal=SONARR_API_KEY='$SONARR_KEY' \\" || echo "  --from-literal=SONARR_API_KEY='' \\"
    [ -n "$RADARR_KEY" ] && echo "  --from-literal=RADARR_API_KEY='$RADARR_KEY' \\" || echo "  --from-literal=RADARR_API_KEY='' \\"
    [ -n "$SABNZBD_KEY" ] && echo "  --from-literal=SABNZBD_API_KEY='$SABNZBD_KEY' \\" || echo "  --from-literal=SABNZBD_API_KEY='' \\"
    echo "  --dry-run=client -o yaml | kubectl apply -f -"
    echo ""
    echo "Or use the create-secret script that will be generated."
else
    echo "⚠️  No keys extracted automatically."
    echo "Please extract keys manually from service UIs and run the create-secret script."
fi


