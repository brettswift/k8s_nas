#!/bin/bash
# One-time setup: create imagePullSecret for private GHCR packages.
# Requires: PAT with read:packages scope.
# Usage: GITHUB_PAT=ghp_xxx ./scripts/create-ghcr-pull-secret.sh

set -e
NAMESPACE="${1:-f1-predictor}"

if [ -z "$GITHUB_PAT" ]; then
  echo "Set GITHUB_PAT (PAT with read:packages scope)"
  exit 1
fi

kubectl create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=brettswift \
  --docker-password="$GITHUB_PAT" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created ghcr-pull secret in $NAMESPACE"
