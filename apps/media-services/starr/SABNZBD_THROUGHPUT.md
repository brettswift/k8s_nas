# SABnzbd download throughput

Traffic path: **SABnzbd → Gluetun (OpenVPN) → VPN exit → usenet server**. The VPN tunnel is often the bottleneck.

## What we tuned in the deployment

- **Gluetun CPU request** raised to 500m so the VPN container isn’t starved under load (OpenVPN is CPU-bound in a single tunnel).

## Biggest lever: SABnzbd server connections

In **SABnzbd UI** → **Config** → **Servers** → [your usenet server]:

- Set **Connections** to the limit your provider allows (often 20–50). More connections = more parallel streams and usually higher throughput.
- Enable **SSL** if your provider supports it (can reduce overhead).
- Leave **Config** → **General** → **Download Speed** at **0** (unlimited).

## If it’s still slow

- **VPN server**: Try another **SERVER_COUNTRIES** (or a specific server if your provider supports it) in the Gluetun env; some exits are more congested.
- **MTU**: We keep **OPENVPN_MSSFIX=1280** for stability. You can try adding **OPENVPN_MTU=1400** in the VPN container env for a bit more throughput; remove it if TLS/key sync errors come back.
- **WireGuard**: If your VPN provider supports WireGuard, Gluetun can use it and often gives better throughput than OpenVPN. You’d switch the deployment to WireGuard env vars (see Gluetun wiki for your provider).
- **Storage**: Downloads go to the pod’s `/data` (hostPath). If that’s a slow or network-backed disk, it can cap write speed.
