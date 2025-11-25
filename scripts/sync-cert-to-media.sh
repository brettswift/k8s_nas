#!/bin/bash
# Manually sync the certificate secret to the media namespace
# This is a temporary fix if the cert-sync cronjob isn't working

set -e

SOURCE_NS="argocd"
TARGET_NS="media"
SECRET_NAME="home-brettswift-com-tls"

echo "🔐 Syncing certificate secret to media namespace..."
echo ""

# Check if source secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$SOURCE_NS" >/dev/null 2>&1; then
    echo "❌ Error: Secret '$SECRET_NAME' does not exist in namespace '$SOURCE_NS'"
    echo ""
    echo "The certificate may not have been created yet. Check:"
    echo "  kubectl get certificate -n $SOURCE_NS"
    echo "  kubectl describe certificate home-brettswift-com-dns -n $SOURCE_NS"
    exit 1
fi

# Check if target namespace exists
if ! kubectl get namespace "$TARGET_NS" >/dev/null 2>&1; then
    echo "⚠️  Namespace '$TARGET_NS' does not exist. Creating it..."
    kubectl create namespace "$TARGET_NS"
fi

# Sync the secret
echo "Copying secret from $SOURCE_NS to $TARGET_NS..."
kubectl get secret "$SECRET_NAME" -n "$SOURCE_NS" -o yaml | \
  sed "s/namespace: $SOURCE_NS/namespace: $TARGET_NS/" | \
  sed '/^  uid:/d' | \
  sed '/^  resourceVersion:/d' | \
  sed '/^  selfLink:/d' | \
  kubectl apply -f -

echo ""
echo "✅ Certificate secret synced successfully!"
echo ""
echo "Verify with:"
echo "  kubectl get secret $SECRET_NAME -n $TARGET_NS"

