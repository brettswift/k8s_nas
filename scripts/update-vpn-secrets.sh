#!/usr/bin/env bash
# Update VPN (IPVanish) secrets in media and qbittorrent namespaces, then restart
# deployments that use them. Run from a host that can reach the cluster.
#
# Usage:
#   OPENVPN_USER=your_ipvanish_username OPENVPN_PASSWORD=your_ipvanish_password \
#     ./scripts/update-vpn-secrets.sh
#
# Optional: NAMESPACES="media qbittorrent" (default: both)
# Optional: RESTART=no to skip rollout restart

set -euo pipefail

OPENVPN_USER="${OPENVPN_USER:-}"
OPENVPN_PASSWORD="${OPENVPN_PASSWORD:-}"
NAMESPACES="${NAMESPACES:-media qbittorrent}"
RESTART="${RESTART:-yes}"

if [[ -z "$OPENVPN_USER" || -z "$OPENVPN_PASSWORD" ]]; then
  echo "Usage: OPENVPN_USER=user OPENVPN_PASSWORD=pass ./scripts/update-vpn-secrets.sh"
  echo "Set OPENVPN_USER and OPENVPN_PASSWORD (IPVanish credentials)."
  exit 1
fi

for ns in $NAMESPACES; do
  echo "Updating vpn-secrets in namespace: $ns"
  kubectl create secret generic vpn-secrets \
    --namespace="$ns" \
    --from-literal=OPENVPN_USER="$OPENVPN_USER" \
    --from-literal=OPENVPN_PASSWORD="$OPENVPN_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -
done

if [[ "$RESTART" != "yes" ]]; then
  echo "Secrets updated. Skipping rollout (RESTART=no)."
  exit 0
fi

if kubectl get deployment sabnzbd -n media &>/dev/null; then
  echo "Restarting sabnzbd (media) to pick up VPN credentials..."
  kubectl rollout restart deployment/sabnzbd -n media
  kubectl rollout status deployment/sabnzbd -n media --timeout=120s
fi

if kubectl get deployment qbittorrent -n qbittorrent &>/dev/null; then
  echo "Restarting qbittorrent to pick up VPN credentials..."
  kubectl rollout restart deployment/qbittorrent -n qbittorrent
  kubectl rollout status deployment/qbittorrent -n qbittorrent --timeout=120s
fi

echo "Done. Check VPN container logs: kubectl logs -n media -l app=sabnzbd -c vpn -f"
