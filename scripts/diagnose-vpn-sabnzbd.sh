#!/usr/bin/env bash
# Diagnose VPN/Sabnzbd: check secrets, pod status, and VPN container logs.
# Run from a host that can reach the cluster (e.g. on same network as 10.1.0.20 or via public DNS).
#
# Usage: ./scripts/diagnose-vpn-sabnzbd.sh
# Optional: NTFY_TOPIC=bswift_general and SEND_NTFY=1 to post summary to ntfy.sh

set -euo pipefail

NTFY_TOPIC="${NTFY_TOPIC:-bswift_general}"
SEND_NTFY="${SEND_NTFY:-0}"

echo "=== Pods (media namespace) ==="
kubectl get pods -n media -l app=sabnzbd -o wide 2>/dev/null || true

echo ""
echo "=== vpn-secrets in media (keys only; values are redacted) ==="
if kubectl get secret vpn-secrets -n media &>/dev/null; then
  kubectl get secret vpn-secrets -n media -o jsonpath='{.data}' | jq -r 'keys[]' 2>/dev/null || kubectl get secret vpn-secrets -n media -o jsonpath='{.data}' 2>/dev/null | head -c 80
  echo ""
  # Check if values are empty (base64 of empty string is empty)
  B64U=$(kubectl get secret vpn-secrets -n media -o jsonpath='{.data.OPENVPN_USER}' 2>/dev/null || true)
  if [[ -z "$B64U" || "$B64U" == "" ]]; then
    echo "WARNING: OPENVPN_USER is empty. Run: OPENVPN_USER=user OPENVPN_PASSWORD=pass ./scripts/update-vpn-secrets.sh"
  else
    echo "OPENVPN_USER is set (non-empty)."
  fi
else
  echo "WARNING: vpn-secrets not found in media. Create with: OPENVPN_USER=user OPENVPN_PASSWORD=pass ./scripts/update-vpn-secrets.sh"
fi

echo ""
echo "=== VPN container logs (sabnzbd pod, last 80 lines) ==="
SAB_POD=$(kubectl get pods -n media -l app=sabnzbd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "$SAB_POD" ]]; then
  kubectl logs -n media "$SAB_POD" -c vpn --tail=80 2>/dev/null || echo "Could not get logs (pod may be starting or name wrong)."
else
  echo "No sabnzbd pod found."
fi

echo ""
echo "=== Sabnzbd container logs (last 20 lines) ==="
if [[ -n "$SAB_POD" ]]; then
  kubectl logs -n media "$SAB_POD" -c sabnzbd --tail=20 2>/dev/null || true
fi

if [[ "$SEND_NTFY" == "1" && -n "$NTFY_TOPIC" ]]; then
  SUMMARY="Sabnzbd VPN diagnose: pod=$SAB_POD"
  [[ -n "$SAB_POD" ]] && SUMMARY="$SUMMARY, check logs above for VPN status"
  curl -s -o /dev/null -X POST -d "$SUMMARY" -H "Title: k8s-nas VPN diagnose" "https://ntfy.sh/$NTFY_TOPIC" 2>/dev/null || true
fi
