# SABnzbd Network Throughput Improvements

**Status:** Plan only (not implemented)
**Date:** 2026-03-12

## Current State

Traffic path: **SABnzbd → Gluetun (OpenVPN UDP) → tun0 → IPVanish → usenet server**

Observed from live pod:

| Layer | MTU / MSS |
|-------|-----------|
| eth0 (Flannel VXLAN overlay) | 1450 |
| tun0 (OpenVPN tunnel) | **1255** |
| TCP advmss on tun0 routes | **1195** |

- `OPENVPN_MSSFIX=1280` clamps TCP MSS to keep the tunnel stable (previously caused TLS key sync errors when higher)
- TCP congestion control: `cubic` (the Linux default)
- VPN CPU at idle: 4m (well under the 500m request — not currently CPU-starved)
- OpenVPN is single-threaded userspace encryption

---

## Recommendations (highest to lowest impact)

### 1. Switch to WireGuard (biggest win)

IPVanish supports WireGuard. Gluetun supports it out of the box.

**Why it helps:**
- WireGuard runs in the kernel, is multi-threaded, and uses ChaCha20 which is significantly faster than OpenVPN's AES on ARM/x86 without AES-NI acceleration
- WireGuard overhead is ~60 bytes per packet vs ~50 + UDP framing for OpenVPN, but because there is no MSS clamping needed the effective MTU jumps from **1255 → ~1390** (1450 − 60)
- No more fragmentation/PMTUD issues that forced `MSSFIX=1280` in the first place
- Lower latency per packet → more effective use of usenet SSL connections

**Gluetun env var changes** (replace OpenVPN vars):

```yaml
- name: VPN_TYPE
  value: "wireguard"
- name: WIREGUARD_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: vpn-secrets
      key: WIREGUARD_PRIVATE_KEY
# Optional: explicit MTU. 1390 = eth0(1450) - WireGuard overhead(60)
- name: VPN_INTERFACE
  value: "wg0"
- name: WIREGUARD_MTU
  value: "1390"
```

Remove: `OPENVPN_PROTOCOL`, `OPENVPN_USER`, `OPENVPN_PASSWORD`, `OPENVPN_MSSFIX`

You need to generate a WireGuard private key from the IPVanish dashboard or their WireGuard config generator and add it to the `vpn-secrets` k8s Secret.

> **Note:** Gluetun's IPVanish WireGuard support fetches server endpoints automatically when `VPN_SERVICE_PROVIDER=ipvanish` and `VPN_TYPE=wireguard`. Check the [Gluetun wiki for IPVanish](https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/ipvanish.md) for the exact required env vars before implementing.

---

### 2. Enable BBR congestion control

TCP `cubic` (current) backs off aggressively on packet loss. VPN tunnels have more jitter and occasional loss, so `cubic` under-utilizes available bandwidth.

`bbr` maintains throughput better across the VPN's variable RTT.

**Option A — node-level (persistent, affects all pods):**

```bash
ssh nas
echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee /etc/sysctl.d/99-bbr.conf
sudo sysctl -p /etc/sysctl.d/99-bbr.conf
```

**Option B — pod sysctl (k8s-native, scoped to this pod):**

Add to the pod spec under `securityContext`:

```yaml
spec:
  securityContext:
    sysctls:
    - name: net.ipv4.tcp_congestion_control
      value: bbr
```

> The vpn container already runs privileged with `NET_ADMIN`, so the node-level approach is simpler and more reliable. Option B requires the sysctl to be allowlisted on the kubelet (`--allowed-unsafe-sysctls`), which it may not be by default on k3s.

---

### 3. Raise Gluetun CPU request (if WireGuard not adopted)

If staying on OpenVPN, the 500m CPU request is appropriate but worth confirming it's not being throttled under actual download load. The 4m observed is at idle. Under a heavy usenet session with 20–50 SSL connections, OpenVPN can saturate a single core.

To observe under load:
```bash
kubectl top pod -n media sabnzbd-<pod> --containers
```

If vpn hits the 2000m limit, increase it or switch to WireGuard.

---

### 4. SABnzbd server connections (in-app, no manifest change)

Already documented in `SABNZBD_THROUGHPUT.md` but worth re-emphasizing: MTU improvements above mean less fragmentation overhead per SSL stream, so the connection count matters more.

- SABnzbd UI → Config → Servers → set Connections to your provider's max (typically 20–50)
- Enable SSL on the server connection
- Leave Download Speed at 0 (unlimited)

---

## Implementation Order

1. **WireGuard first** — generates the largest MTU improvement and eliminates the need for MSSFIX. Test on a feature branch, push to live, verify with `kubectl exec ... -- wg show` and a download speed test.
2. **BBR** — node-level sysctl, one-liner, immediate effect. Do this alongside or right after.
3. **Server connections** — in-app config, no deploy needed.

## Rollback

```bash
# Restore OpenVPN config
git push origin <previous-branch>:live
```

For BBR, revert sysctl on the node:
```bash
sudo sysctl net.ipv4.tcp_congestion_control=cubic
sudo rm /etc/sysctl.d/99-bbr.conf
```
