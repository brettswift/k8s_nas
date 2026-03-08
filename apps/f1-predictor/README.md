# F1 Predictor

Image built by GitHub Actions → `ghcr.io/brettswift/f1-predictor:latest`. Code only, no manual node steps.

## One-time: GHCR pull secret (private package)

```bash
GITHUB_PAT=ghp_xxx ./scripts/create-ghcr-pull-secret.sh f1-predictor
```

PAT needs `read:packages` scope. Or make the package public: GitHub → Packages → f1-predictor → Package settings → Change visibility.
