#!/bin/bash
set -euo pipefail

echo "Getting ArgoCD admin password from target server..."

# Set kubeconfig for k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Get the admin password
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

echo ""
echo "ArgoCD server status:"
kubectl get pods -n argocd

echo ""
echo "ArgoCD applications:"
kubectl get applications -n argocd
