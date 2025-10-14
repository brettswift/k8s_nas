#!/bin/bash

# Certificate Manager Setup Script
# This script sets up cert-manager for automatic Let's Encrypt certificate renewal

set -e

echo "🔐 Setting up cert-manager for automatic certificate renewal..."

# Install cert-manager
echo "📦 Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Wait for cert-manager to be ready
echo "⏳ Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Create ClusterIssuer for Let's Encrypt
echo "🌐 Creating Let's Encrypt ClusterIssuer..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: brettswift@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

# Create ClusterIssuer for Let's Encrypt staging (for testing)
echo "🧪 Creating Let's Encrypt staging ClusterIssuer..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: brettswift@gmail.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: traefik
EOF

echo "✅ cert-manager setup complete!"
echo "📋 Next steps:"
echo "1. Update your IngressRoute to use cert-manager for certificate management"
echo "2. Certificates will be automatically renewed every 60 days"
echo "3. Check certificate status with: kubectl get certificates -A"
