# WireGuard + BBR implementation (feature branch)

This branch implements the throughput improvements in **docs/plans/2026-03-12-sabnzbd-throughput-improvements.md**.

## What’s in this branch

- **WireGuard** instead of OpenVPN for the SABnzbd VPN container (Gluetun).
- **Pod sysctl** `net.ipv4.tcp_congestion_control=bbr` for better throughput over the tunnel.

## Before you deploy

1. **Add WireGuard key to the cluster**
   - From the IPVanish dashboard or WireGuard config generator, get your **private key**.
   - Add it to the `vpn-secrets` Secret in the `media` namespace:
     ```bash
     kubectl patch secret vpn-secrets -n media -p '{"stringData":{"WIREGUARD_PRIVATE_KEY":"<your-private-key>"}}'
     ```
   - (You can keep or remove `OPENVPN_USER` / `OPENVPN_PASSWORD`; they are unused when `VPN_TYPE=wireguard`.)

2. **Optional: Gluetun IPVanish WireGuard**
   - If the container fails to start, check the [Gluetun wiki for IPVanish](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/ipvanish.md) and any WireGuard-specific docs for extra env vars (e.g. `WIREGUARD_ADDRESSES` from your WireGuard config).

3. **BBR sysctl on k3s**
   - If the pod is rejected with a sysctl error, allowlist it on the kubelet, e.g.:
     `--allowed-unsafe-sysctls=net.ipv4.tcp_congestion_control`
   - Or use the **node-level** BBR option in the plan (sysctl on the host instead of the pod).

## Deploy

- Push this branch and point the media-services app (or your deploy) at it, or merge to `live` and let ArgoCD sync.
- After deploy, confirm WireGuard: `kubectl exec -n media deploy/sabnzbd -c vpn -- wg show`
- Run a download and check speed; compare to OpenVPN if you have a baseline.

## Rollback

Revert to the branch that uses OpenVPN (e.g. `live` before this merge) and sync. Restore OpenVPN credentials in `vpn-secrets` if you removed them.
