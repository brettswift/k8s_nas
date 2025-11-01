#!/bin/bash
# Containerized Starr Integration Configuration Script
# This script runs in a Kubernetes Job to automatically configure integrations

set -e

echo "🔗 Starr Integration Configurator"
echo "=================================="
echo "Started: $(date)"
echo ""

# Configuration from environment (set by ConfigMap/Secret)
NAMESPACE="${NAMESPACE:-media}"
SONARR_URL="${SONARR_URL:-http://sonarr.media.svc.cluster.local:8989}"
RADARR_URL="${RADARR_URL:-http://radarr.media.svc.cluster.local:7878}"
PROWLARR_URL="${PROWLARR_URL:-http://prowlarr.media.svc.cluster.local:9696}"

# Get API keys from mounted secret (via environment variables)
SONARR_KEY="${SONARR_API_KEY}"
RADARR_KEY="${RADARR_API_KEY}"
PROWLARR_KEY="${PROWLARR_API_KEY}"

# Validate API keys are available
if [ -z "$SONARR_KEY" ] || [ -z "$PROWLARR_KEY" ]; then
    echo "❌ Error: Required API keys not found"
    echo "   SONARR_API_KEY: ${SONARR_KEY:+✅} ${SONARR_KEY:-❌}"
    echo "   PROWLARR_API_KEY: ${PROWLARR_KEY:+✅} ${PROWLARR_KEY:-❌}"
    exit 1
fi

echo "✅ API keys loaded"
echo ""

# Function to check if service is ready
check_service_ready() {
    local service_url=$1
    local api_key=$2
    local service_name=$3
    
    echo "Checking $service_name availability..."
    local status=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "X-Api-Key: ${api_key}" \
        "${service_url}/api/v3/system/status" 2>/dev/null || echo "000")
    
    if [ "$status" = "200" ]; then
        echo "✅ $service_name is ready"
        return 0
    else
        echo "⚠️  $service_name not ready (HTTP $status)"
        return 1
    fi
}

# Wait for services to be ready (with timeout)
wait_for_services() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_service_ready "$SONARR_URL" "$SONARR_KEY" "Sonarr" && \
           check_service_ready "$PROWLARR_URL" "$PROWLARR_KEY" "Prowlarr"; then
            return 0
        fi
        echo "   Waiting for services... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ Services not ready after $max_attempts attempts"
    return 1
}

# Check if Prowlarr indexer exists in Sonarr
check_prowlarr_indexer() {
    local indexers=$(curl -s \
        -H "X-Api-Key: ${SONARR_KEY}" \
        "${SONARR_URL}/api/v3/indexer" 2>/dev/null || echo "[]")
    
    echo "$indexers" | jq -e '.[] | select(.implementation == "Prowlarr")' > /dev/null 2>&1
}

# Add Prowlarr indexer to Sonarr
configure_sonarr_prowlarr() {
    echo ""
    echo "Step 1: Configuring Sonarr → Prowlarr Indexer"
    echo "-----------------------------------------------"
    
    if check_prowlarr_indexer; then
        echo "✅ Prowlarr indexer already exists in Sonarr"
        return 0
    fi
    
    echo "Adding Prowlarr indexer to Sonarr..."
    
    local indexer_config=$(cat <<EOF
{
  "name": "Prowlarr",
  "implementation": "Prowlarr",
  "implementationName": "Prowlarr",
  "configContract": "ProwlarrSettings",
  "enableRss": true,
  "enableAutomaticSearch": true,
  "enableInteractiveSearch": true,
  "supportsRss": true,
  "supportsSearch": true,
  "protocol": "torrent",
  "priority": 25,
  "fields": [
    {
      "order": 0,
      "name": "baseUrl",
      "label": "Prowlarr URL",
      "value": "${PROWLARR_URL}",
      "type": "textbox"
    },
    {
      "order": 1,
      "name": "apiKey",
      "label": "API Key",
      "value": "${SONARR_KEY}",
      "type": "textbox"
    },
    {
      "order": 2,
      "name": "syncLevel",
      "label": "Sync Level",
      "value": "fullSync",
      "type": "select"
    }
  ]
}
EOF
)

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${SONARR_KEY}" \
        -d "${indexer_config}" \
        "${SONARR_URL}/api/v3/indexer" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        echo "✅ Prowlarr indexer added to Sonarr successfully"
        return 0
    else
        echo "⚠️  Failed to add Prowlarr indexer (HTTP $http_code)"
        echo "   Response: $body"
        return 1
    fi
}

# Check if Sonarr application exists in Prowlarr
check_sonarr_application() {
    local apps=$(curl -s \
        -H "X-Api-Key: ${PROWLARR_KEY}" \
        "${PROWLARR_URL}/api/v1/applications" 2>/dev/null || echo "[]")
    
    echo "$apps" | jq -e '.[] | select(.name == "Sonarr")' > /dev/null 2>&1
}

# Add Sonarr application to Prowlarr
configure_prowlarr_sonarr() {
    echo ""
    echo "Step 2: Configuring Prowlarr → Sonarr Application"
    echo "--------------------------------------------------"
    
    if check_sonarr_application; then
        echo "✅ Sonarr application already exists in Prowlarr"
        return 0
    fi
    
    echo "Adding Sonarr application to Prowlarr..."
    
    local app_config=$(cat <<EOF
{
  "name": "Sonarr",
  "syncLevel": "addAndRemoveOnly",
  "implementation": "Sonarr",
  "implementationName": "Sonarr",
  "configContract": "SonarrSettings",
  "fields": [
    {
      "order": 0,
      "name": "baseUrl",
      "label": "Sonarr Server URL",
      "value": "${SONARR_URL}",
      "type": "textbox"
    },
    {
      "order": 1,
      "name": "apiKey",
      "label": "API Key",
      "value": "${SONARR_KEY}",
      "type": "textbox"
    },
    {
      "order": 2,
      "name": "syncAppIndexers",
      "label": "Sync App Indexers",
      "value": true,
      "type": "checkbox"
    },
    {
      "order": 3,
      "name": "appIndexersSyncLevel",
      "label": "App Indexers Sync Level",
      "value": "addAndRemoveOnly",
      "type": "select"
    }
  ]
}
EOF
)

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${PROWLARR_KEY}" \
        -d "${app_config}" \
        "${PROWLARR_URL}/api/v1/applications" 2>/dev/null || echo -e "\n000")
    
    local http_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        echo "✅ Sonarr application added to Prowlarr successfully"
        return 0
    else
        echo "⚠️  Failed to add Sonarr application (HTTP $http_code)"
        echo "   Response: $body"
        return 1
    fi
}

# Main execution
main() {
    echo "Waiting for services to be ready..."
    if ! wait_for_services; then
        echo "❌ Services not ready, exiting"
        exit 1
    fi
    
    echo ""
    echo "Starting configuration..."
    
    local sonarr_success=false
    local prowlarr_success=false
    
    # Configure Sonarr → Prowlarr
    if configure_sonarr_prowlarr; then
        sonarr_success=true
    fi
    
    # Configure Prowlarr → Sonarr
    if configure_prowlarr_sonarr; then
        prowlarr_success=true
    fi
    
    echo ""
    echo "=========================================="
    if [ "$sonarr_success" = true ] && [ "$prowlarr_success" = true ]; then
        echo "✅ Configuration Complete!"
        echo "=========================================="
        echo ""
        echo "Summary:"
        echo "  - Sonarr → Prowlarr: ✅ Configured"
        echo "  - Prowlarr → Sonarr: ✅ Configured"
        echo ""
        echo "Integration is ready to use."
        exit 0
    else
        echo "⚠️  Configuration Partially Complete"
        echo "=========================================="
        echo ""
        echo "Summary:"
        echo "  - Sonarr → Prowlarr: $([ "$sonarr_success" = true ] && echo "✅" || echo "❌")"
        echo "  - Prowlarr → Sonarr: $([ "$prowlarr_success" = true ] && echo "✅" || echo "❌")"
        echo ""
        echo "Some configurations failed. Check logs above for details."
        echo "Job will be retried on next execution."
        exit 1
    fi
}

# Run main function
main

