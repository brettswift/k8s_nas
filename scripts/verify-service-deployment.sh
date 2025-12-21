#!/bin/bash
# Verify service deployment - checks ArgoCD sync and pod status
# Usage: ./scripts/verify-service-deployment.sh <namespace> <app-name>

set -euo pipefail

NAMESPACE="${1:-}"
APP_NAME="${2:-}"

if [ -z "$NAMESPACE" ] || [ -z "$APP_NAME" ]; then
    echo "Usage: $0 <namespace> <app-name>"
    echo "Example: $0 media sonarr"
    exit 1
fi

echo "=========================================="
echo "Verifying: $NAMESPACE/$APP_NAME"
echo "=========================================="

# Check ArgoCD sync status
echo ""
echo "📊 ArgoCD Status:"
ARGOCD_APP=$(kubectl get applications -n argocd -o json | jq -r ".items[] | select(.spec.destination.namespace == \"$NAMESPACE\" and (.metadata.name | contains(\"$APP_NAME\"))) | .metadata.name" | head -1)

if [ -n "$ARGOCD_APP" ]; then
    SYNC_STATUS=$(kubectl get application "$ARGOCD_APP" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH_STATUS=$(kubectl get application "$ARGOCD_APP" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    echo "  Application: $ARGOCD_APP"
    echo "  Sync Status: $SYNC_STATUS"
    echo "  Health Status: $HEALTH_STATUS"
    
    if [ "$SYNC_STATUS" != "Synced" ]; then
        echo "  ⚠️  WARNING: Application is not synced!"
    fi
    if [ "$HEALTH_STATUS" != "Healthy" ]; then
        echo "  ⚠️  WARNING: Application is not healthy!"
    fi
else
    echo "  ⚠️  No ArgoCD application found"
fi

# Check pod status
echo ""
echo "🔄 Pod Status:"
PODS=$(kubectl get pods -n "$NAMESPACE" -l app="$APP_NAME" -o json 2>/dev/null || echo '{"items":[]}')
POD_COUNT=$(echo "$PODS" | jq -r '.items | length')

if [ "$POD_COUNT" -eq 0 ]; then
    # Try alternative label selectors
    PODS=$(kubectl get pods -n "$NAMESPACE" -o json 2>/dev/null | jq -r ".items[] | select(.metadata.name | contains(\"$APP_NAME\"))" | jq -s '.')
    POD_COUNT=$(echo "$PODS" | jq -r '. | length')
fi

if [ "$POD_COUNT" -eq 0 ]; then
    echo "  ❌ No pods found for $APP_NAME in $NAMESPACE"
    exit 1
fi

echo "$PODS" | jq -r '.items[] | "  \(.metadata.name): \(.status.phase) - Ready: \(.status.containerStatuses[0].ready // false)"'

# Check if all pods are ready
READY_COUNT=$(echo "$PODS" | jq -r '[.items[] | select(.status.containerStatuses[0].ready == true)] | length')
TOTAL_COUNT=$(echo "$PODS" | jq -r '.items | length')

echo ""
if [ "$READY_COUNT" -eq "$TOTAL_COUNT" ] && [ "$TOTAL_COUNT" -gt 0 ]; then
    echo "✅ All pods are ready ($READY_COUNT/$TOTAL_COUNT)"
    exit 0
else
    echo "⚠️  Not all pods are ready ($READY_COUNT/$TOTAL_COUNT)"
    exit 1
fi

