#!/bin/bash

# Update Route53 credentials in the base secret (cert-manager namespace)
# The sync cronjob and ArgoCD hook will automatically replicate to other namespaces
# Run this after: assume brettswift-mgmt

set -e

SECRET_NAME="route53-credentials"
NAMESPACE="cert-manager"

echo "🔑 Updating Route53 credentials in base secret ($NAMESPACE namespace)..."
echo "   This will be automatically synced to other namespaces (e.g., external-dns)"
echo ""

# Get AWS credentials (from environment or prompt)
echo "Enter AWS Access Key ID:"
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  read -r AWS_ACCESS_KEY_ID
else
  echo "  (using AWS_ACCESS_KEY_ID from environment)"
fi

echo "Enter AWS Secret Access Key:"
if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  read -s AWS_SECRET_ACCESS_KEY
  echo ""
else
  echo "  (using AWS_SECRET_ACCESS_KEY from environment)"
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "❌ Both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are required"
  exit 1
fi

# Check if secret exists
if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "📝 Creating new secret..."
  kubectl create secret generic "$SECRET_NAME" \
    --from-literal=access-key-id="$AWS_ACCESS_KEY_ID" \
    --from-literal=secret-access-key="$AWS_SECRET_ACCESS_KEY" \
    --namespace="$NAMESPACE"
  echo "✅ Secret created!"
else
  echo "📝 Updating existing secret..."
  # Update both keys
  kubectl patch secret "$SECRET_NAME" -n "$NAMESPACE" --type=json \
    -p="[
      {\"op\": \"add\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$AWS_ACCESS_KEY_ID" | base64)\"},
      {\"op\": \"add\", \"path\": \"/data/secret-access-key\", \"value\": \"$(echo -n "$AWS_SECRET_ACCESS_KEY" | base64)\"}
    ]" 2>/dev/null || \
  kubectl patch secret "$SECRET_NAME" -n "$NAMESPACE" --type=json \
    -p="[
      {\"op\": \"replace\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$AWS_ACCESS_KEY_ID" | base64)\"},
      {\"op\": \"replace\", \"path\": \"/data/secret-access-key\", \"value\": \"$(echo -n "$AWS_SECRET_ACCESS_KEY" | base64)\"}
    ]"
  echo "✅ Secret updated!"
fi

echo ""
echo "🔄 Sync status:"
echo "   - ArgoCD PostSync hook will sync immediately on next ArgoCD sync"
echo "   - CronJob will sync every 6 hours (schedule: 0 */6 * * *)"
echo ""
echo "To trigger immediate sync manually:"
echo "  kubectl create job --from=cronjob/sync-route53-credentials manual-sync-\$(date +%s) -n cert-manager"

