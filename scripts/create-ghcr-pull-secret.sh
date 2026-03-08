#!/bin/bash
# Create imagePullSecret for private GHCR packages. Use for any app that pulls from ghcr.io.
# Requires: PAT with read:packages scope.
#
# Usage:
#   GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh <namespace>
#   GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh f1-predictor media
#
# Multiple namespaces: pass each as an argument.

set -e

if [ -z "$GH_PULL_IMAGES_TOKEN" ]; then
  echo "Set GH_PULL_IMAGES_TOKEN (PAT with read:packages scope)"
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "Usage: GH_PULL_IMAGES_TOKEN=ghp_xxx $0 <namespace> [namespace ...]"
  exit 1
fi

for NAMESPACE in "$@"; do
  kubectl create secret docker-registry ghcr-pull \
    --docker-server=ghcr.io \
    --docker-username=brettswift \
    --docker-password="$GH_PULL_IMAGES_TOKEN" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "Created ghcr-pull secret in $NAMESPACE"
done
