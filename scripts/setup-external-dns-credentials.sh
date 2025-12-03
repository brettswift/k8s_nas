#!/bin/bash

# Setup Route53 credentials in the base secret (cert-manager namespace)
# The sync cronjob will automatically replicate it to other namespaces (e.g., external-dns)
# Run this after: assume brettswift-mgmt

set -e

echo "🔑 Setting up Route53 credentials in base secret (cert-manager namespace)..."
echo "   The sync cronjob will automatically replicate to other namespaces"
echo ""

# Get access key ID from ClusterIssuer (if it's set)
ACCESS_KEY_ID=$(kubectl get clusterissuer letsencrypt-dns-home -o jsonpath='{.spec.acme.solvers[0].dns01.route53.accessKeyID}' 2>/dev/null || echo "")

if [ -z "$ACCESS_KEY_ID" ]; then
  echo "⚠️  Access key ID not found in ClusterIssuer"
  echo "   Please provide your AWS Access Key ID:"
  read -r ACCESS_KEY_ID
fi

if [ -z "$ACCESS_KEY_ID" ]; then
  echo "❌ Access key ID is required"
  exit 1
fi

# Check if base secret exists in cert-manager namespace
if ! kubectl get secret route53-credentials -n cert-manager &>/dev/null; then
  echo "❌ route53-credentials secret not found in cert-manager namespace"
  echo "   Please create it first with: kubectl create secret generic route53-credentials -n cert-manager --from-literal=secret-access-key=..."
  exit 1
fi

# Check if access-key-id already exists and matches
EXISTING_KEY=$(kubectl get secret route53-credentials -n cert-manager -o jsonpath='{.data.access-key-id}' 2>/dev/null | base64 -d 2>/dev/null || echo "")

if [ "$EXISTING_KEY" = "$ACCESS_KEY_ID" ]; then
  echo "✅ Base secret already has correct access-key-id"
  echo ""
  echo "The sync cronjob will replicate this to other namespaces automatically."
  echo "Next sync: $(kubectl get cronjob sync-route53-credentials -n cert-manager -o jsonpath='{.spec.schedule}' 2>/dev/null || echo 'check cronjob status')"
  exit 0
fi

# Add/update access-key-id in the base secret (cert-manager namespace)
echo "📝 Adding/updating access-key-id in base secret (cert-manager namespace)..."
kubectl patch secret route53-credentials -n cert-manager --type=json \
  -p="[{\"op\": \"add\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$ACCESS_KEY_ID" | base64)\"}]" 2>/dev/null || \
kubectl patch secret route53-credentials -n cert-manager --type=json \
  -p="[{\"op\": \"replace\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$ACCESS_KEY_ID" | base64)\"}]"

echo "✅ Base secret updated in cert-manager namespace!"
echo ""
echo "The sync cronjob (sync-route53-credentials) will automatically replicate this"
echo "to other namespaces (e.g., external-dns) within the next sync cycle."
echo ""
echo "To trigger immediate sync, you can manually run:"
echo "  kubectl create job --from=cronjob/sync-route53-credentials manual-sync-\$(date +%s) -n cert-manager"

