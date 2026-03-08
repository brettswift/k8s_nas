# F1 Predictor: Event-Driven Image Refresh

**Status:** Implemented  
**Date:** 2026-02-15

## Overview

Deploy f1-predictor using **mutable tags** (`:dev` and `:live`) and an **ArgoCD PostSync hook** to detect new images and trigger a rollout restart. No git commits from GHA; builds push to a fixed tag and the hook compares registry digest to the running pod.

## Goals

- No GHA manifest commits (no `contents: write`, no push to repo)
- Dev and prod use fixed tags: `:dev` and `:live`
- New image is picked up after sync via PostSync hook (poll registry digest → restart deployment if changed)
- Hook always exits 0; delete policy `BeforeHookCreation` so the next sync replaces the Job

## Design

### 1. GHA Workflows

- **build-f1-predictor-dev.yml:** Trigger on any push to `f1-dev`. Build and push only `ghcr.io/brettswift/f1-predictor:dev`. No `paths-ignore`, no `contents: write`, no git steps.
- **build-f1-predictor-prod.yml:** Trigger on push to `live` with changes under `apps/f1-predictor/**`. Build and push only `:live`.

### 2. Overlays

- **overlays/dev:** `newTag: dev` (permanent). Resources include `image-refresh-hook.yaml`, `image-refresh-rbac.yaml`.
- **overlays/prod:** `newTag: live` (permanent). Same hook + RBAC.

### 3. PostSync Hook + RBAC

- **RBAC (per overlay):** ServiceAccount `image-refresh`, Role (deployments: get, patch), RoleBinding.
- **Hook Job:**
  - Annotations: `argocd.argoproj.io/hook: PostSync`, `argocd.argoproj.io/hook-delete-policy: BeforeHookCreation`
  - Image: `bitnami/kubectl:latest`
  - Env: `IMAGE`, `TAG`, `DEPLOYMENT`
  - Script: get current deployment pod `imageID` digest; loop up to ~20× (15s sleep); curl GHCR manifest for `$TAG`, parse `Docker-Content-Digest`; if digest differs from running, run `kubectl rollout restart deployment/$DEPLOYMENT` then `kubectl rollout status ...`; always exit 0.
  - `activeDeadlineSeconds: 330`, `backoffLimit: 0`

### 4. Base Deployment

- `imagePullPolicy: Always` so that after a restart the new image is pulled.

### 5. GHCR Auth (Private Package)

If the GHCR package is private, the hook’s manifest API call may return 401. Provide a secret with a PAT (`read:packages`) and set `GITHUB_TOKEN` in the hook Job’s env from that secret; the script uses it for `Authorization: Bearer` when present.

## Implemented Artifacts

| Item          | Location                                                                                    |
|---------------|---------------------------------------------------------------------------------------------|
| Dev workflow  | `.github/workflows/build-f1-predictor-dev.yml`                                              |
| Prod workflow | `.github/workflows/build-f1-predictor-prod.yml`                                             |
| Dev overlay   | `apps/f1-predictor/overlays/dev/` (kustomization, image-refresh-hook, image-refresh-rbac)   |
| Prod overlay  | `apps/f1-predictor/overlays/prod/` (kustomization, image-refresh-hook, image-refresh-rbac)  |
| Docs          | `apps/f1-predictor/WORKFLOW.md`, `apps/f1-predictor/DEPLOYMENT.md`                          |

## Related

- [F1 Predictor Deployment](../../apps/f1-predictor/DEPLOYMENT.md) – build flow, ArgoCD, hook behavior, GHCR
- [F1 Predictor Workflow](../../apps/f1-predictor/WORKFLOW.md) – dev→prod workflow and troubleshooting
