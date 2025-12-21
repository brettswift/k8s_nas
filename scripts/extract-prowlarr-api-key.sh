#!/bin/bash
# Extract Prowlarr API Key and Update starr-secrets Secret
# Part of Story 1.2: Configure Sonarr-Prowlarr Integration

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

echo "🔑 Prowlarr API Key Extraction and Secret Update"
echo "================================================"
echo ""

# Check if Prowlarr pod is running
echo "Checking Prowlarr deployment status..."
POD_STATUS=$(kubectl get pods -n media -l app=prowlarr -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

if [ "$POD_STATUS" != "Running" ] && [ "$POD_STATUS" != "NotFound" ]; then
    echo "⚠️  Prowlarr pod is not running (status: $POD_STATUS)"
    echo "   Waiting for pod to be ready..."
    kubectl wait --for=condition=ready pod -l app=prowlarr -n media --timeout=300s || {
        echo "❌ Prowlarr pod did not become ready"
        exit 1
    }
elif [ "$POD_STATUS" == "NotFound" ]; then
    echo "❌ Prowlarr pod not found. Please ensure Prowlarr is deployed first."
    exit 1
fi

echo "✅ Prowlarr pod is running"
echo ""

# Method 1: Try extracting from existing server config
echo "Method 1: Checking for existing config on server..."
PROWLARR_CONFIG="/mnt/data/configs/prowlarr/config.xml"
PROWLARR_KEY=""

if ssh -o ConnectTimeout=5 bswift@10.0.0.20 "test -f $PROWLARR_CONFIG" 2>/dev/null; then
    echo "📁 Found existing Prowlarr config on server"
    PROWLARR_KEY=$(ssh bswift@10.0.0.20 "grep -oP '(?<=<ApiKey>)[^<]+' $PROWLARR_CONFIG 2>/dev/null | head -1" || echo "")
    if [ -n "$PROWLARR_KEY" ]; then
        echo "✅ Extracted API key from server config: ${PROWLARR_KEY:0:10}..."
    fi
fi

# Method 2: Extract from running pod config
if [ -z "$PROWLARR_KEY" ]; then
    echo ""
    echo "Method 2: Extracting from pod config..."
    POD_NAME=$(kubectl get pods -n media -l app=prowlarr -o jsonpath='{.items[0].metadata.name}')
    
    # Wait for config file to exist
    echo "   Waiting for config file to be created..."
    for i in {1..30}; do
        if kubectl exec -n media "$POD_NAME" -- test -f /config/config.xml 2>/dev/null; then
            break
        fi
        sleep 2
    done
    
    if kubectl exec -n media "$POD_NAME" -- test -f /config/config.xml 2>/dev/null; then
        PROWLARR_KEY=$(kubectl exec -n media "$POD_NAME" -- cat /config/config.xml 2>/dev/null | grep -oP '(?<=<ApiKey>)[^<]+' | head -1 || echo "")
        if [ -n "$PROWLARR_KEY" ]; then
            echo "✅ Extracted API key from pod config: ${PROWLARR_KEY:0:10}..."
        else
            echo "⚠️  Config file exists but API key not found (may need initial setup)"
        fi
    else
        echo "⚠️  Config file not yet created (Prowlarr may need initial configuration)"
    fi
fi

# If still no key, provide manual instructions
if [ -z "$PROWLARR_KEY" ]; then
    echo ""
    echo "❌ Could not extract API key automatically"
    echo ""
    echo "Please extract manually:"
    echo "1. Access Prowlarr UI: https://home.brettswift.com/prowlarr"
    echo "2. Navigate to: Settings → General → Security → API Key"
    echo "3. Copy the API key and run:"
    echo ""
    echo "   PROWLARR_KEY='<your-api-key>'"
    echo "   ./scripts/extract-prowlarr-api-key.sh"
    echo ""
    exit 1
fi

echo ""
echo "=========================================="
echo "Extracted Prowlarr API Key: ${PROWLARR_KEY:0:10}..."
echo "=========================================="
echo ""

# Get existing secret values to preserve
echo "Reading existing secret values..."
SONARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' 2>/dev/null | base64 -d || echo "")
RADARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.RADARR_API_KEY}' 2>/dev/null | base64 -d || echo "")

# Update secret
echo "Updating starr-secrets Secret..."
kubectl create secret generic starr-secrets -n media \
  --from-literal=SONARR_API_KEY="$SONARR_KEY" \
  --from-literal=RADARR_API_KEY="$RADARR_KEY" \
  --from-literal=PROWLARR_API_KEY="$PROWLARR_KEY" \
  --from-literal=LIDARR_API_KEY='' \
  --from-literal=BAZARR_API_KEY='' \
  --from-literal=JELLYSEERR_API_KEY='' \
  --from-literal=SABNZBD_API_KEY='' \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "✅ Secret updated successfully!"
echo ""

# Verify
echo "Verifying secret update..."
VERIFIED_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' | base64 -d)
if [ "$VERIFIED_KEY" == "$PROWLARR_KEY" ]; then
    echo "✅ Verification successful: PROWLARR_API_KEY matches extracted key"
else
    echo "⚠️  Verification failed: keys do not match"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Prowlarr API key extraction complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure Sonarr → Prowlarr connection (Task 2)"
echo "2. Configure Prowlarr → Sonarr application sync (Task 3)"
echo "3. Verify integration (Task 4)"
echo ""







