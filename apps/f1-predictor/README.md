# F1 Predictor

F1 prediction web app with separate dev and prod environments.

## Environments

| Environment | Branch | URL | Namespace |
|-------------|--------|-----|-----------|
| Prod (home) | live | https://f1.home.brettswift.com | f1-predictor |
| Dev | f1-dev | https://f1-dev.home.brettswift.com | f1-predictor-dev |
| Prod (external) | — | https://f1.brettswift.com | prod |

**Dev** uses image tag `:dev`; prod uses `:latest`. ArgoCD deploys from branch.

## Deployment

### ArgoCD (GitOps)

- **f1-predictor**: `apps/f1-predictor/overlays/home`, branch `live`
- **f1-predictor-dev**: `apps/f1-predictor/overlays/dev`, branch `f1-dev`

To iterate on dev: create branch `f1-dev`, push changes. Build workflow pushes `:dev` image.

## Configuration

Environment variables:
- `ENVIRONMENT`: `dev` or `prod` - controls DEV badge display
- `API_BASE_URL`: External API base URL (empty for no external API)
- `USE_STUB_API`: `true` or `false` - use stub API for testing

## Image

Image built by GitHub Actions → `ghcr.io/brettswift/f1-predictor:latest`. See [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md) for one-time setup.

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
