#!/bin/bash
# Configure Sonarr-Prowlarr Integration via API
# This script automates the configuration steps from CONFIGURE_STARR_INTEGRATIONS.md

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

echo "🔗 Configuring Sonarr-Prowlarr Integration via API"
echo "=================================================="
echo ""

# Get API keys from secret
echo "Reading API keys from starr-secrets..."
SONARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d)
PROWLARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' | base64 -d)

if [ -z "$SONARR_KEY" ] || [ -z "$PROWLARR_KEY" ]; then
    echo "❌ Error: API keys not found in starr-secrets"
    echo "   Please ensure SONARR_API_KEY and PROWLARR_API_KEY are set"
    exit 1
fi

echo "✅ API keys retrieved"
echo ""

# Service URLs (internal Kubernetes DNS)
SONARR_URL="http://sonarr.media.svc.cluster.local:8989"
PROWLARR_URL="http://prowlarr.media.svc.cluster.local:9696"

echo "Step 1: Configuring Sonarr → Prowlarr Indexer"
echo "-----------------------------------------------"

# Check if Prowlarr indexer already exists in Sonarr
echo "Checking for existing Prowlarr indexer in Sonarr..."
EXISTING=$(kubectl run -it --rm check-prowlarr --image=curlimages/curl:latest --restart=Never --namespace=media -- \
    curl -s "${SONARR_URL}/api/v3/indexer?apikey=${SONARR_KEY}" 2>/dev/null | \
    grep -o '"implementation":"Prowlarr"' | head -1 || echo "")

if [ -n "$EXISTING" ]; then
    echo "⚠️  Prowlarr indexer already exists in Sonarr"
    echo "   Skipping Sonarr configuration"
else
    echo "Adding Prowlarr indexer to Sonarr..."
    
    # Create Prowlarr indexer configuration
    INDEXER_CONFIG=$(cat <<EOF
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
      "type": "select",
      "selectOptions": [
        {"value": "disabled", "name": "Disabled"},
        {"value": "addOnly", "name": "Add Only"},
        {"value": "fullSync", "name": "Full Sync"}
      ]
    }
  ]
}
EOF
)

    # Add indexer via API
    RESPONSE=$(kubectl run -it --rm add-prowlarr-indexer --image=curlimages/curl:latest --restart=Never --namespace=media -- \
        curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${SONARR_KEY}" \
        -d "${INDEXER_CONFIG}" \
        "${SONARR_URL}/api/v3/indexer" 2>&1 | tail -2)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Prowlarr indexer added to Sonarr successfully"
    else
        echo "⚠️  Failed to add Prowlarr indexer (HTTP $HTTP_CODE)"
        echo "   Response: $(echo "$RESPONSE" | head -1)"
        echo "   You may need to configure this manually via Sonarr UI"
    fi
fi

echo ""
echo "Step 2: Configuring Prowlarr → Sonarr Application"
echo "--------------------------------------------------"

# Check if Sonarr application already exists in Prowlarr
echo "Checking for existing Sonarr application in Prowlarr..."
EXISTING_APP=$(kubectl run -it --rm check-sonarr-app --image=curlimages/curl:latest --restart=Never --namespace=media -- \
    curl -s "${PROWLARR_URL}/api/v1/applications?apikey=${PROWLARR_KEY}" 2>/dev/null | \
    grep -o '"name":"Sonarr"' | head -1 || echo "")

if [ -n "$EXISTING_APP" ]; then
    echo "⚠️  Sonarr application already exists in Prowlarr"
    echo "   Skipping Prowlarr configuration"
else
    echo "Adding Sonarr application to Prowlarr..."
    
    # Create Sonarr application configuration
    APP_CONFIG=$(cat <<EOF
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
      "type": "select",
      "selectOptions": [
        {"value": "disabled", "name": "Disabled"},
        {"value": "addOnly", "name": "Add Only"},
        {"value": "addAndRemoveOnly", "name": "Add and Remove Only"},
        {"value": "fullSync", "name": "Full Sync"}
      ]
    }
  ]
}
EOF
)

    # Add application via API
    RESPONSE=$(kubectl run -it --rm add-sonarr-app --image=curlimages/curl:latest --restart=Never --namespace=media -- \
        curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: ${PROWLARR_KEY}" \
        -d "${APP_CONFIG}" \
        "${PROWLARR_URL}/api/v1/applications" 2>&1 | tail -2)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    
    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Sonarr application added to Prowlarr successfully"
    else
        echo "⚠️  Failed to add Sonarr application (HTTP $HTTP_CODE)"
        echo "   Response: $(echo "$RESPONSE" | head -1)"
        echo "   You may need to configure this manually via Prowlarr UI"
    fi
fi

echo ""
echo "=========================================="
echo "✅ Configuration Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify integration in Sonarr: Settings → Indexers"
echo "2. Verify integration in Prowlarr: Settings → Apps"
echo "3. Add indexers in Prowlarr (they will sync to Sonarr automatically)"
echo "4. Test TV show search in Sonarr"
echo ""
echo "For manual configuration, see: CONFIGURE_STARR_INTEGRATIONS.md"
echo ""

