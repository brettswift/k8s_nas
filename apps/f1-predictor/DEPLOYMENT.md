# F1 Predictor Deployment

End-to-end documentation of the dev/prod deployment flow, build process, and ArgoCD setup.

## Overview

| Environment | Branch | URL | Namespace | ArgoCD App |
|-------------|--------|-----|-----------|------------|
| Prod (home) | live | https://f1.home.brettswift.com | f1-predictor | f1-predictor |
| Dev | f1-dev | https://f1-dev.home.brettswift.com | f1-predictor-dev | f1-predictor-dev |
| Prod (external) | — | https://f1.brettswift.com | prod | — |

## Image Tagging (Git SHA)

Images are tagged with the **short git hash** (e.g. `a1b2c3d`), not `:latest` or `:dev`. This:

- Ensures dev and prod run the same code when you promote (merge f1-dev → live)
- Forces deploy to fail (ImagePullBackOff) until the build completes, then succeeds
- Avoids ArgoCD syncing before the image exists

## Build Flow

1. **Trigger:** Push to `live` or `f1-dev` when these paths change:
   - `apps/f1-predictor/Dockerfile`
   - `apps/f1-predictor/requirements.txt`
   - `apps/f1-predictor/src/**`

2. **Workflow** (`.github/workflows/build-f1-predictor.yml`):
   - Extracts short SHA from the triggering commit
   - Updates the overlay's `newTag` in `kustomization.yaml` and pushes
   - ArgoCD syncs on that push → deployment tries to pull `image:SHA` → ImagePullBackOff
   - Builds image, tags with SHA, pushes to GHCR
   - Kubernetes retries → image exists → pod starts

3. **Order matters:** Manifest is updated first, then build. ArgoCD sees the new tag before the image exists, so deploy fails until the build completes.

## ArgoCD

- **f1-predictor:** `apps/f1-predictor/overlays/home`, branch `live`
- **f1-predictor-dev:** `apps/f1-predictor/overlays/dev`, branch `f1-dev`

Each app points directly at its overlay path and branch. No shared root kustomization.

## Promoting Dev → Prod

1. Merge `f1-dev` into `live`
2. Build workflow runs on the merge commit
3. Updates `overlays/home` with the new SHA
4. ArgoCD syncs, deploys the same code that was in dev

## Overlays

- **overlays/home:** Prod for home lab (f1.home.brettswift.com)
- **overlays/dev:** Dev (f1-dev.home.brettswift.com)
- **overlays/prod:** External prod (f1.brettswift.com, different cluster)

Each overlay has `images:` in kustomization to override the base image tag. The build workflow updates `newTag` with the SHA.

## DNS

Managed via external-dns annotations in ingress manifests. Uses **A records** (direct IP) so f1 subdomains don't inherit wrong IP from home.brettswift.com CNAME chain:

- Home prod: `f1.home.brettswift.com` → `68.147.109.77` (A record)
- Dev: `f1-dev.home.brettswift.com` → `68.147.109.77` (A record)
- External prod: `f1.brettswift.com` → `68.147.109.77` (A record)

Update the `target` annotation in each overlay if your server uses a different public IP.

## GHCR

- One-time setup: create `ghcr-pull` secret in each namespace (see [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md))
- Images: `ghcr.io/brettswift/f1-predictor:<sha>`
- GHCR storage and bandwidth are free for container images

## Manual Build

Actions → Build f1-predictor image → Run workflow → select branch.

## ImagePullBackOff

Kubernetes image pull backoff is hard-coded in the kubelet (0, 10, 20, 40, 80, 160, 300s) and cannot be configured from the deployment. To avoid pull failures, ensure the build runs before ArgoCD syncs (the workflow updates the manifest first, then builds). Dev overlay uses `:latest` until the first build on f1-dev runs.
