# GHCR Pull Secret for Custom Images

Apps that use images from GitHub Container Registry (ghcr.io) need an imagePullSecret when the package is private. This applies to any app with a GitHub Actions build workflow.

## One-Time Setup

Create a PAT with **`read:packages`** scope only. Then run:

```bash
# All namespaces
GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh all

# Specific namespace(s)
GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh f1-predictor media
```

The script creates a secret named `ghcr-pull` in each namespace.

## App Requirements

Add to the deployment spec:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ghcr-pull
      containers:
      - name: my-app
        image: ghcr.io/brettswift/my-app:latest
```

## Adding a New App with Docker Build

1. Add a Dockerfile in `apps/<app>/`
2. Add a GitHub Actions workflow that builds and pushes to `ghcr.io/brettswift/<app>:latest`
3. Add `imagePullSecrets: - name: ghcr-pull` to the deployment
4. Run the script for the app's namespace: `GH_PULL_IMAGES_TOKEN=ghp_xxx ./scripts/create-ghcr-pull-secret.sh <namespace>`

## PAT Scope

| Scope | Purpose |
|-------|---------|
| `read:packages` | Pull images from private GHCR packages |

No other scopes needed. The build workflow uses `GITHUB_TOKEN` (automatic); the cluster only needs read access to pull.
