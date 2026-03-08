# F1 Predictor

F1 prediction web app with separate dev and prod environments.

## Environments

| Environment | URL | Ingress | Namespace |
|-------------|-----|---------|-----------|
| Dev | https://f1.home.brettswift.com | `overlays/dev/ingress.yaml` | `f1-predictor-dev` |
| Prod | https://f1.brettswift.com | `overlays/prod/ingress.yaml` | `f1-predictor-prod` |

**Dev environment** displays a "DEV" badge in the header. Prod does not.

## Deployment

### Dev (f1.home.brettswift.com)
```bash
kubectl apply -k overlays/dev/
```

### Prod (f1.brettswift.com)
```bash
kubectl apply -k overlays/prod/
```

### ArgoCD
Two separate ArgoCD applications should be created:
- **f1-predictor-dev**: Path `apps/f1-predictor/overlays/dev`
- **f1-predictor-prod**: Path `apps/f1-predictor/overlays/prod`

## Configuration

Environment variables:
- `ENVIRONMENT`: `dev` or `prod` - controls DEV badge display
- `API_BASE_URL`: External API base URL (empty for no external API)
- `USE_STUB_API`: `true` or `false` - use stub API for testing

## Image

Image built by GitHub Actions → `ghcr.io/brettswift/f1-predictor:latest`. See [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md) for one-time setup.

## DNS

Route53 entries are managed via external-dns annotations in the ingress manifests:
- Dev: `f1.home.brettswift.com` → `home.brettswift.com`
- Prod: `f1.brettswift.com` → `home.brettswift.com`

The public IP assumes port forwarding is configured on the router.

### DNS Troubleshooting

If domains don't resolve:

1. **Route53** (external-dns should create it; if not, check external-dns logs):
   ```bash
   kubectl logs -n external-dns deployment/external-dns
   ```

2. **Local DNS** (router, Pi-hole, /etc/hosts): Add records pointing to the same IP as `home.brettswift.com` (e.g. `10.1.0.20`).
