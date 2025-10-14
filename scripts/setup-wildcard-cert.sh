#!/bin/bash

# Wildcard Certificate Setup Script
# This script sets up a wildcard certificate for *.brettswift.com using DNS challenge

set -e

echo "🌐 Setting up wildcard certificate for *.brettswift.com..."

# Check if AWS credentials are available
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check if we can assume the brettswift-mgmt role
echo "🔑 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'assume brettswift-mgmt' first."
    exit 1
fi

# Create ClusterIssuer for Let's Encrypt with DNS challenge
echo "📝 Creating Let's Encrypt ClusterIssuer with DNS challenge..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: brettswift@gmail.com
    privateKeySecretRef:
      name: letsencrypt-dns
    solvers:
    - dns01:
        route53:
          region: us-west-2
          accessKeyID: \${AWS_ACCESS_KEY_ID}
          secretAccessKeySecretRef:
            name: route53-credentials
            key: secret-access-key
EOF

# Create secret for Route53 credentials
echo "🔐 Creating Route53 credentials secret..."
kubectl create secret generic route53-credentials \
  --from-literal=secret-access-key=\${AWS_SECRET_ACCESS_KEY} \
  --namespace=cert-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Create wildcard certificate
echo "🎯 Creating wildcard certificate for *.brettswift.com..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: brettswift-com-wildcard
  namespace: argocd
spec:
  secretName: brettswift-com-wildcard-tls
  issuerRef:
    name: letsencrypt-dns
    kind: ClusterIssuer
  dnsNames:
    - "*.brettswift.com"
    - "brettswift.com"
  renewBefore: 30d
EOF

echo "✅ Wildcard certificate setup complete!"
echo "📋 Certificate will be automatically renewed every 60 days"
echo "🔍 Check certificate status with: kubectl get certificates -A"
echo "📝 Update your IngressRoutes to use 'brettswift-com-wildcard-tls' secret"
