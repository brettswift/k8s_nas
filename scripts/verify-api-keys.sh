#!/bin/bash
# Verify API Keys by Testing Service API Calls
# Tests authentication using extracted API keys

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

echo "🔍 Verifying API Keys via Service API Calls"
echo "==========================================="
echo ""

# Get API keys from secret
SONARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d)
RADARR_KEY=$(kubectl get secret starr-secrets -n media -o jsonpath='{.data.RADARR_API_KEY}' | base64 -d)

# Test Sonarr API
echo "Testing Sonarr API..."
SONARR_URL="http://sonarr.media.svc.cluster.local:8989"
if kubectl run -it --rm curl-test-sonarr --image=curlimages/curl:latest --restart=Never --namespace=media -- curl -s -o /dev/null -w "%{http_code}" "${SONARR_URL}/api/v3/system/status?apikey=${SONARR_KEY}" 2>/dev/null | grep -q "200"; then
    echo "✅ Sonarr API key verified - authentication successful"
else
    echo "⚠️  Sonarr API key test returned non-200 status"
    echo "   Testing without key (should fail)..."
    if kubectl run -it --rm curl-test-sonarr-fail --image=curlimages/curl:latest --restart=Never --namespace=media -- curl -s -o /dev/null -w "%{http_code}" "${SONARR_URL}/api/v3/system/status" 2>/dev/null | grep -q "401\|403"; then
        echo "   ✅ Confirmed: API requires authentication"
    fi
fi
echo ""

# Test Radarr API
echo "Testing Radarr API..."
RADARR_URL="http://radarr.media.svc.cluster.local:7878"
if kubectl run -it --rm curl-test-radarr --image=curlimages/curl:latest --restart=Never --namespace=media -- curl -s -o /dev/null -w "%{http_code}" "${RADARR_URL}/api/v3/system/status?apikey=${RADARR_KEY}" 2>/dev/null | grep -q "200"; then
    echo "✅ Radarr API key verified - authentication successful"
else
    echo "⚠️  Radarr API key test returned non-200 status"
    echo "   Testing without key (should fail)..."
    if kubectl run -it --rm curl-test-radarr-fail --image=curlimages/curl:latest --restart=Never --namespace=media -- curl -s -o /dev/null -w "%{http_code}" "${RADARR_URL}/api/v3/system/status" 2>/dev/null | grep -q "401\|403"; then
        echo "   ✅ Confirmed: API requires authentication"
    fi
fi
echo ""

echo "=========================================="
echo "Verification Complete"
echo "=========================================="

