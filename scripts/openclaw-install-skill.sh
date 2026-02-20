#!/usr/bin/env bash
# Install an OpenClaw skill from ClawHub into the gateway's workspace.
# Usage: ./scripts/openclaw-install-skill.sh [skill-slug]
# Example: ./scripts/openclaw-install-skill.sh home-assistant
# If you get "Rate limit exceeded", wait 10–15 minutes and retry.

set -euo pipefail

SKILL="${1:-home-assistant}"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config-nas}"

INSTALL_CMD="npm install -g clawhub && mkdir -p /data/workspace && clawhub install ${SKILL} --no-input --workdir /data/workspace --force"

kubectl run -n openclaw clawhub-install --rm -i --restart=Never \
  --image=node:22-bookworm-slim \
  --overrides="{\"spec\":{\"containers\":[{\"name\":\"install\",\"image\":\"node:22-bookworm-slim\",\"command\":[\"sh\",\"-c\",\"${INSTALL_CMD}\"],\"volumeMounts\":[{\"name\":\"data\",\"mountPath\":\"/data\"}]}],\"volumes\":[{\"name\":\"data\",\"persistentVolumeClaim\":{\"claimName\":\"openclaw-data\"}}]}}"

echo "Done. Restart the gateway or start a new session to use the skill."
