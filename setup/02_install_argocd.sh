#!/bin/bash
set -euo pipefail

echo "Checking if ArgoCD namespace exists..."
if ! kubectl get namespace argocd &> /dev/null; then
    echo "Creating ArgoCD namespace..."
    kubectl create namespace argocd
else
    echo "ArgoCD namespace already exists"
fi

echo "Installing/Updating ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

echo "Port forwarding ArgoCD server..."
echo "Access ArgoCD UI at: http://localhost:8080"
kubectl port-forward svc/argocd-server -n argocd 8080:443 & 