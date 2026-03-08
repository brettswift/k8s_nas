# F1 Predictor

Image built by GitHub Actions → `ghcr.io/brettswift/f1-predictor:latest`. See [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md) for one-time setup.

## Access

- **Subdomain:** https://f1.home.brettswift.com
- **Path:** https://home.brettswift.com/f1-predictor

## DNS Troubleshooting

If `f1.home.brettswift.com` doesn't resolve:

1. **Route53** (external-dns should create it; if not, run manually):
   ```bash
   ./scripts/create-f1-dns.sh
   ```

2. **Local DNS** (router, Pi-hole, /etc/hosts): Add a record pointing `f1.home.brettswift.com` to the same IP as `home.brettswift.com` (e.g. `10.1.0.20`).
