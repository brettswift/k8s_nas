# F1 Predictor

F1 prediction web app with separate dev and prod environments.

## Environments

| Environment | Branch | URL | Namespace |
|-------------|--------|-----|-----------|
| Prod (home) | live | https://f1.home.brettswift.com | f1-predictor |
| Dev | f1-dev | https://f1-dev.home.brettswift.com | f1-predictor-dev |
| Prod (external) | — | https://f1.brettswift.com | prod |

Images are tagged with the **short git hash** (e.g. `a1b2c3d`). See [DEPLOYMENT.md](./DEPLOYMENT.md) for the full build and deploy flow.

## Configuration

Environment variables:
- `ENVIRONMENT`: `dev` or `prod` - controls DEV badge display
- `API_BASE_URL`: External API base URL (empty for no external API)
- `USE_STUB_API`: `true` or `false` - use stub API for testing

## Image

Built by GitHub Actions, tagged with git SHA. See [DEPLOYMENT.md](./DEPLOYMENT.md) and [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md).

## DNS

Route53 entries are managed via external-dns annotations in the ingress manifests:

- Home prod: `f1.home.brettswift.com` → `home.brettswift.com` (CNAME)
- Dev: `f1-dev.home.brettswift.com` → `home.brettswift.com` (CNAME)
- External prod: `f1.brettswift.com` → `68.147.109.77` (A record)

### DNS Troubleshooting

If domains don't resolve:

1. **Route53** (external-dns should create it; if not, check external-dns logs):
   ```bash
   kubectl logs -n external-dns deployment/external-dns
   ```

2. **Local DNS** (router, Pi-hole, /etc/hosts): Add records pointing to the same IP as `home.brettswift.com` (e.g. `10.1.0.20`).
