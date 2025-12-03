#!/bin/bash

# Setup External DNS credentials in route53-credentials secret
# This adds the access-key-id to the existing secret (which only has secret-access-key)
# Run this after: assume brettswift-mgmt

set -e

echo "🔑 Setting up External DNS credentials..."

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

# Check if secret exists
if ! kubectl get secret route53-credentials -n cert-manager &>/dev/null; then
  echo "❌ route53-credentials secret not found in cert-manager namespace"
  echo "   Please create it first with: kubectl create secret generic route53-credentials -n cert-manager --from-literal=secret-access-key=..."
  exit 1
fi

# Check if access-key-id already exists
EXISTING_KEY=$(kubectl get secret route53-credentials -n cert-manager -o jsonpath='{.data.access-key-id}' 2>/dev/null | base64 -d 2>/dev/null || echo "")

if [ "$EXISTING_KEY" = "$ACCESS_KEY_ID" ]; then
  echo "✅ Secret already has correct access-key-id"
  exit 0
fi

# Add access-key-id to the secret
echo "📝 Adding access-key-id to route53-credentials secret..."
kubectl patch secret route53-credentials -n cert-manager --type=json \
  -p="[{\"op\": \"add\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$ACCESS_KEY_ID" | base64)\"}]" 2>/dev/null || \
kubectl patch secret route53-credentials -n cert-manager --type=json \
  -p="[{\"op\": \"replace\", \"path\": \"/data/access-key-id\", \"value\": \"$(echo -n "$ACCESS_KEY_ID" | base64)\"}]"

echo "✅ External DNS credentials configured!"
echo ""
echo "External DNS will now automatically create Route53 records for any Ingress/IngressRoute"
echo "with the annotation: external-dns.alpha.kubernetes.io/hostname"

