#!/bin/bash
# Create or initialize starr-secrets Secret
# Part of initial setup - creates secret with empty keys if it doesn't exist
# Keys can be populated later - see CONFIGURE_STARR_INTEGRATIONS.md

set -e

KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"
export KUBECONFIG

NAMESPACE="${1:-media}"
SECRET_NAME="${2:-starr-secrets}"

echo "🔐 Creating/Initializing starr-secrets Secret"
echo "=============================================="
echo ""
echo "Namespace: $NAMESPACE"
echo "Secret name: $SECRET_NAME"
echo ""

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "⚠️  Namespace '$NAMESPACE' does not exist"
    echo "   Creating namespace..."
    kubectl create namespace "$NAMESPACE"
fi

# Check if secret already exists
if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "✅ Secret '$SECRET_NAME' already exists in namespace '$NAMESPACE'"
    echo ""
    echo "Current keys:"
    for key in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BAZARR_API_KEY PROWLARR_API_KEY SABNZBD_API_KEY JELLYSEERR_API_KEY; do
        value=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d || echo "")
        if [ -n "$value" ]; then
            echo "  ✅ $key: Set"
        else
            echo "  ⚠️  $key: Empty"
        fi
    done
    echo ""
    echo "To view keys, see CONFIGURE_STARR_INTEGRATIONS.md for the command"
    exit 0
fi

# Create secret with empty values (will be populated later)
echo "Creating secret with empty keys (to be populated later)..."
kubectl create secret generic "$SECRET_NAME" -n "$NAMESPACE" \
  --from-literal=SONARR_API_KEY="" \
  --from-literal=RADARR_API_KEY="" \
  --from-literal=LIDARR_API_KEY="" \
  --from-literal=BAZARR_API_KEY="" \
  --from-literal=PROWLARR_API_KEY="" \
  --from-literal=SABNZBD_API_KEY="" \
  --from-literal=JELLYSEERR_API_KEY=""

echo ""
echo "✅ Secret '$SECRET_NAME' created successfully in namespace '$NAMESPACE'"
echo ""
echo "Next steps:"
echo "1. Deploy Starr services via GitOps (ArgoCD)"
echo "2. Wait for services to initialize and generate API keys"
echo "3. Extract and populate keys: See CONFIGURE_STARR_INTEGRATIONS.md for the command"
echo ""

