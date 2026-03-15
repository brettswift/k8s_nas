#!/bin/bash
# Create imagePullSecret for private GHCR packages. Use for any app that pulls from ghcr.io.
# Requires: PAT with read:packages scope.
#
# Usage:
#   GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh all
#   GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh <namespace>
#   GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh f1-predictor media

set -e

if [ -z "$GH_PULL_IMAGES_TOKEN" ]; then
  echo "Set GH_PULL_IMAGES_TOKEN (PAT with read:packages scope)"
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: GH_PULL_IMAGES_TOKEN=ghp_xxx $0 all | <namespace> [namespace ...]"
  exit 1
fi

if [ "$1" = "all" ]; then
  echo "Listing namespaces..."
  NAMESPACES=$(kubectl get namespaces --request-timeout=10s -o jsonpath='{.items[*].metadata.name}') || {
    echo "kubectl get namespaces failed. Check: kubectl config current-context; kubectl cluster-info"
    exit 1
  }
  echo "Found: $NAMESPACES"
else
  NAMESPACES="$*"
fi

for NAMESPACE in $NAMESPACES; do
  echo -n "Creating ghcr-pull in $NAMESPACE... "
  if kubectl create secret docker-registry ghcr-pull \
    --docker-server=ghcr.io \
    --docker-username=brettswift \
    --docker-password="$GH_PULL_IMAGES_TOKEN" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f - -n "$NAMESPACE"; then
    echo "ok"
  else
    echo "failed (skipped)"
  fi
done
