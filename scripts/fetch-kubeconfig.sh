#!/usr/bin/env bash

set -euo pipefail

# Usage: scripts/fetch-kubeconfig.sh [ssh_host]
# Copies k3s kubeconfig from 10.0.0.20 (or provided host) and rewrites server to the host IP.

SSH_HOST="${1:-10.0.0.20}"
OUT_DIR="${HOME}/.kube"
OUT_FILE="${OUT_DIR}/config-nas"

mkdir -p "${OUT_DIR}"

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

echo "Fetching kubeconfig from ${SSH_HOST}..."
scp -q "${SSH_HOST}:/etc/rancher/k3s/k3s.yaml" "$tmpfile"

# Determine API server URL
SERVER_IP="${SSH_HOST}"
if [[ "$SERVER_IP" =~ ^[a-zA-Z] ]]; then
  # If alias provided (e.g., nas), resolve to IP if possible
  resolved_ip=$(getent hosts "$SERVER_IP" 2>/dev/null | awk '{print $1}' | head -n1 || true)
  SERVER_IP="${resolved_ip:-$SERVER_IP}"
fi

sed \
  -e "s#https://127.0.0.1:6443#https://${SERVER_IP}:6443#g" \
  -e "s#https://localhost:6443#https://${SERVER_IP}:6443#g" \
  "$tmpfile" > "$OUT_FILE"

echo "Wrote kubeconfig to: $OUT_FILE"
echo "Export and test:"
echo "  export KUBECONFIG=$OUT_FILE"
echo "  kubectl get nodes"










