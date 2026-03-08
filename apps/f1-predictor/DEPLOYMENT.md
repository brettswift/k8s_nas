# F1 Predictor Deployment

Build process, ArgoCD setup, and deployment details. For the full dev→prod workflow (PR flow, testing, promote), see [WORKFLOW.md](./WORKFLOW.md).

## Overview

| Environment | Branch | URL | Namespace | ArgoCD App |
|-------------|--------|-----|-----------|------------|
| Dev | f1-dev | https://f1.home.brettswift.com | f1-predictor-dev | f1-predictor-dev |
| Prod | live | https://f1.brettswift.com | f1-predictor | f1-predictor |

## Image Tagging (Git SHA)

Images are tagged with the **short git hash** (e.g. `a1b2c3d`), never `:latest` or `:dev`. Overlays use placeholder `sha-required` until the build workflow sets the real SHA. This:

- Ensures dev and prod run the same code when you promote (merge f1-dev → live)
- Forces deploy to fail (ImagePullBackOff) until the build completes, then succeeds
- Avoids ArgoCD syncing before the image exists

## Build Flow

Separate workflows per environment:

| Branch | Workflow | Trigger |
|--------|----------|---------|
| live | `build-f1-predictor-prod.yml` | Any change under `apps/f1-predictor/**` except `overlays/prod/kustomization.yaml` |
| f1-dev | `build-f1-predictor-dev.yml` | Any push to f1-dev except `overlays/dev/kustomization.yaml` |

1. **Trigger:** Push to `live` or `f1-dev` (path filters avoid loops when the workflow pushes manifest updates).

2. **Workflow steps:**
   - Extracts short SHA from the triggering commit
   - Updates the overlay's `newTag` in `kustomization.yaml` and pushes
   - ArgoCD syncs on that push → deployment tries to pull `image:SHA` → ImagePullBackOff
   - Builds image, tags with SHA, pushes to GHCR
   - Kubernetes retries → image exists → pod starts

3. **Order matters:** Manifest is updated first, then build. ArgoCD sees the new tag before the image exists, so deploy fails until the build completes.

## ArgoCD

- **f1-predictor:** `apps/f1-predictor/overlays/prod`, branch `live`
- **f1-predictor-dev:** `apps/f1-predictor/overlays/dev`, branch `f1-dev`

Each app points directly at its overlay path and branch.

## Promoting Dev → Prod

1. Merge `f1-dev` into `live`
2. Build workflow runs on the merge commit
3. Updates `overlays/prod` with the new SHA
4. ArgoCD syncs, deploys the same code that was in dev

## Overlays

- **overlays/dev:** Dev (f1.home.brettswift.com, CNAME to home.brettswift.com)
- **overlays/prod:** Prod (f1.brettswift.com, external-dns discovers)

Each overlay has `images:` in kustomization to override the base image tag. The build workflow updates `newTag` with the SHA.

## DNS

Managed via external-dns annotations in ingress manifests:

- **Dev:** `f1.home.brettswift.com` → CNAME to `home.brettswift.com`
- **Prod:** `f1.brettswift.com` → external-dns discovers ingress IP

## TLS

- **Dev:** `home-brettswift-com-tls` (covers `*.home.brettswift.com`)
- **Prod:** `brettswift-com-tls` (wildcard `*.brettswift.com`)

## GHCR

- One-time setup: create `ghcr-pull` secret in each namespace: `f1-predictor`, `f1-predictor-dev` (see [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md))
- Images: `ghcr.io/brettswift/f1-predictor:<sha>`
- GHCR storage and bandwidth are free for container images

## Manual Build

- **Prod:** Actions → Build f1-predictor prod image → Run workflow
- **Dev:** Actions → Build f1-predictor dev image → Run workflow

## ImagePullBackOff

Kubernetes image pull backoff is hard-coded in the kubelet (0, 10, 20, 40, 80, 160, 300s) and cannot be configured. To get the hash on f1-dev: push any change to `apps/f1-predictor/` (except the dev overlay kustomization) to trigger the build. The workflow updates the manifest with the SHA, then builds.
