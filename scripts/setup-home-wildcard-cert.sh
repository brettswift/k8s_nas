#!/bin/bash

# Wildcard Certificate Setup Script for *.home.brettswift.com
# This script sets up a wildcard certificate for *.home.brettswift.com using DNS challenge

set -e

echo "🌐 Setting up wildcard certificate for *.home.brettswift.com..."

# Check if cert-manager is installed
if ! kubectl get crd certificates.cert-manager.io &> /dev/null; then
    echo "❌ cert-manager is not installed. Please run bootstrap/k8s_plugins.sh first."
    exit 1
else
    echo "✅ cert-manager already installed"
    
    # Wait for cert-manager to be ready if not already
    if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n cert-manager --timeout=10s &> /dev/null; then
        echo "⏳ Waiting for cert-manager to be ready..."
        kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n cert-manager --timeout=300s
    fi
fi

# Verify AWS credentials are available in environment
# Prerequisite: Run 'assume brettswift-mgmt' before executing this script
echo "🔑 Verifying AWS credentials..."
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ AWS credentials not found in environment."
    echo "   Please run 'assume brettswift-mgmt' first to get temporary credentials."
    exit 1
fi

# Verify credentials work
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials invalid or expired. Please run 'assume brettswift-mgmt' again."
    exit 1
fi

echo "✅ AWS credentials verified"

# Create secret for Route53 credentials (needed for ClusterIssuer)
# Uses environment variables set by 'assume brettswift-mgmt'
echo "🔐 Creating Route53 credentials secret..."
kubectl create secret generic route53-credentials \
  --from-literal=secret-access-key="${AWS_SECRET_ACCESS_KEY}" \
  ${AWS_SESSION_TOKEN:+--from-literal=session-token="${AWS_SESSION_TOKEN}"} \
  --namespace=cert-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Wait for ClusterIssuer to be created by GitOps (if it doesn't exist yet)
echo "⏳ Waiting for ClusterIssuer to be created by GitOps..."
MAX_WAIT=60
WAIT_COUNT=0
while ! kubectl get clusterissuer letsencrypt-dns-home &> /dev/null && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  echo "   ClusterIssuer not found, waiting... ($WAIT_COUNT/$MAX_WAIT seconds)"
  sleep 5
  WAIT_COUNT=$((WAIT_COUNT + 5))
done

if ! kubectl get clusterissuer letsencrypt-dns-home &> /dev/null; then
  echo "⚠️  ClusterIssuer not found after waiting. It may need to be created by GitOps first."
  echo "    Run this script again after ArgoCD syncs the infrastructure."
  exit 1
fi

# Patch ClusterIssuer with accessKeyID (required for Route53 DNS challenge)
# This patch is idempotent and needed because accessKeyID can't be in Git
echo "🔧 Updating ClusterIssuer with AWS access key ID..."
CURRENT_ACCESS_KEY=$(kubectl get clusterissuer letsencrypt-dns-home -o jsonpath='{.spec.acme.solvers[0].dns01.route53.accessKeyID}' 2>/dev/null || echo "")

if [ "$CURRENT_ACCESS_KEY" = "$AWS_ACCESS_KEY_ID" ]; then
  echo "✅ ClusterIssuer already has correct accessKeyID"
else
  # Use merge patch to ensure accessKeyID is set
  kubectl patch clusterissuer letsencrypt-dns-home --type=merge -p="{\"spec\":{\"acme\":{\"solvers\":[{\"dns01\":{\"route53\":{\"accessKeyID\":\"${AWS_ACCESS_KEY_ID}\"}}}]}}}" 2>&1 || \
  kubectl get clusterissuer letsencrypt-dns-home -o json | \
    jq ".spec.acme.solvers[0].dns01.route53.accessKeyID = \"${AWS_ACCESS_KEY_ID}\"" | \
    kubectl replace -f - 2>&1
  
  echo "✅ ClusterIssuer patched with access key ID"
fi


echo ""
echo "✅ Setup complete! Summary:"
echo "   - Route53 credentials secret: ✅"
echo "   - ClusterIssuer accessKeyID: ✅"
echo ""
echo "📝 GitOps Configuration:"
echo "   - apps/infrastructure/cert-manager/clusterissuer.yaml (managed by ArgoCD)"
echo "   - apps/infrastructure/cert-manager/certificate.yaml (managed by ArgoCD)"
echo ""
echo "🔄 DR Note:"
echo "   This script is idempotent and can be re-run safely."
echo "   On fresh install, run this after GitOps creates the ClusterIssuer."
echo "   The accessKeyID patch will persist even if GitOps syncs (merge strategy)."
echo ""
echo "⏳ To monitor certificate issuance:"
echo "   kubectl get certificate -n media -w"

