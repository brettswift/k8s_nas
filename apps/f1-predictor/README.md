# F1 Predictor

F1 prediction web app with dev and prod environments.

## Environments

| Environment | Branch | URL | Namespace |
|-------------|--------|-----|-----------|
| Dev | f1-dev | https://f1.home.brettswift.com | f1-predictor-dev |
| Prod | live | https://f1.brettswift.com | f1-predictor |

Images are tagged with the **short git hash** (e.g. `a1b2c3d`). See [WORKFLOW.md](./WORKFLOW.md) for the full dev→prod process and [DEPLOYMENT.md](./DEPLOYMENT.md) for build and deploy details.

## Configuration

Environment variables:

- `ENVIRONMENT`: `dev` or `prod` - controls DEV badge display
- `API_BASE_URL`: External API base URL (empty for no external API)
- `USE_STUB_API`: `true` or `false` - use stub API for testing

## Image

Built by GitHub Actions, tagged with git SHA. See [DEPLOYMENT.md](./DEPLOYMENT.md) and [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md).

## DNS

Managed via external-dns annotations in ingress manifests:

- **Dev:** `f1.home.brettswift.com` → CNAME to `home.brettswift.com`
- **Prod:** `f1.brettswift.com` → external-dns discovers ingress IP

### DNS Troubleshooting

If domains don't resolve:

1. **Route53** (external-dns should create it; if not, check external-dns logs):
   ```bash
   kubectl logs -n external-dns deployment/external-dns
   ```

2. **Local DNS** (router, Pi-hole, /etc/hosts): Add records pointing to the same IP as `home.brettswift.com` (e.g. `10.1.0.20`).

## TLS

- **Dev:** `home-brettswift-com-tls` (covers `*.home.brettswift.com`)
- **Prod:** `brettswift-com-tls` (wildcard `*.brettswift.com`)
