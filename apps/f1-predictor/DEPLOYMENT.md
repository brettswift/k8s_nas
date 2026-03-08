# F1 Predictor Deployment

Build process, ArgoCD setup, and deployment details. For the full dev→prod workflow (PR flow, testing, promote), see [WORKFLOW.md](./WORKFLOW.md).

## Design: event-driven image refresh

Deployment uses **mutable tags** (`:dev` / `:live`) and an **ArgoCD PostSync hook** to roll out new images without GHA committing to the repo. The hook polls the GHCR manifest digest; when it differs from the running pod, it runs a rollout restart. Full design and implemented artifacts: [Event-driven image refresh plan](../../docs/plans/f1-predictor-event-driven-image-refresh.md).

## Overview

| Environment | Branch | URL | Namespace | ArgoCD App |
|-------------|--------|-----|-----------|------------|
| Dev | f1-dev | https://f1.home.brettswift.com | f1-predictor-dev | f1-predictor-dev |
| Prod | live | https://f1.brettswift.com | f1-predictor | f1-predictor |

## Image Tagging (mutable :dev / :live)

Images use fixed mutable tags; there are **no GHA commits** to the repo:

- **Dev:** `ghcr.io/brettswift/f1-predictor:dev`
- **Prod:** `ghcr.io/brettswift/f1-predictor:live`

Overlays set `newTag: dev` or `newTag: live` in kustomization. Each new build overwrites the same tag. The deployment uses `imagePullPolicy: Always` and a PostSync hook detects digest changes and triggers a rollout restart.

## Build Flow

Separate workflows per environment:

| Branch | Workflow | Trigger |
|--------|----------|---------|
| live | `build-f1-predictor-prod.yml` | Any change under `apps/f1-predictor/**` |
| f1-dev | `build-f1-predictor-dev.yml` | Any push to f1-dev |

1. **Trigger:** Push to `live` or `f1-dev` (and for prod, path must be under `apps/f1-predictor/**`).

2. **Workflow steps:** Checkout, build image, push to GHCR with tag `:dev` or `:live`. No manifest updates or git pushes.

3. **Deploy:** ArgoCD syncs the overlay (fixed tag). A **PostSync hook** Job runs: it polls the GHCR manifest for the tag, compares digest to the running pod; if different, it runs `kubectl rollout restart deployment/f1-predictor` and waits for rollout. Hook runs up to ~20×15s then exits 0; it is deleted before the next sync.

## ArgoCD

- **f1-predictor:** `apps/f1-predictor/overlays/prod`, branch `live`
- **f1-predictor-dev:** `apps/f1-predictor/overlays/dev`, branch `f1-dev`

Each app points directly at its overlay path and branch.

## Promoting Dev → Prod

1. Merge `f1-dev` into `live`
2. Build workflow runs and pushes `:live`
3. ArgoCD syncs; PostSync hook detects new digest and restarts the deployment

## Overlays

- **overlays/dev:** Dev (f1.home.brettswift.com, CNAME to home.brettswift.com)
- **overlays/prod:** Prod (f1.brettswift.com, external-dns discovers)

Each overlay has `images:` with fixed `newTag: dev` or `newTag: live`, plus an image-refresh PostSync hook and RBAC (ServiceAccount `image-refresh`, Role/RoleBinding for deployment get/patch).

## DNS

Managed via external-dns annotations in ingress manifests:

- **Dev:** `f1.home.brettswift.com` → CNAME to `home.brettswift.com`
- **Prod:** `f1.brettswift.com` → external-dns discovers ingress IP

## TLS

- **Dev:** `home-brettswift-com-tls` (covers `*.home.brettswift.com`)
- **Prod:** `brettswift-com-tls` (wildcard `*.brettswift.com`)

## GHCR

- One-time setup: create `ghcr-pull` secret in each namespace: `f1-predictor`, `f1-predictor-dev` (see [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md))
- Images: `ghcr.io/brettswift/f1-predictor:dev` and `ghcr.io/brettswift/f1-predictor:live`
- GHCR storage and bandwidth are free for container images

**PostSync hook and private GHCR:** The image-refresh hook calls the GHCR manifest API. If the package is private, that request may return 401. To fix: create a secret (e.g. `ghcr-token`) with a `GITHUB_TOKEN` or `CR_TOKEN` key (PAT with `read:packages`), and in the hook Job add an `env` entry that sets `GITHUB_TOKEN` from that secret. The script already uses `GITHUB_TOKEN` when present for the `Authorization: Bearer` header.

### Verifying the image-refresh hook

After an Argo CD sync, a PostSync Job runs once per overlay. To confirm it ran and what it did:

```bash
# Dev
kubectl logs job/image-refresh -n f1-predictor-dev

# Prod
kubectl logs job/image-refresh -n f1-predictor
```

**If the hook is working and no new image was pushed:** You may see no Job (it’s deleted before the next sync). Right after a sync you should see logs like:

- `Image refresh: checking brettswift/f1-predictor:dev vs deployment f1-predictor` (or `:live` in prod)
- Either:
  - `Digest unchanged, waiting (attempt 1/20)` … then after up to 20×15s: `No digest change detected within timeout; exiting 0`
  - Or, if the registry digest changed: `Digest changed (sha256:… -> sha256:…), triggering rollout restart` then `Rollout complete`

**If the hook can’t reach GHCR (e.g. private repo, no token):** You’ll see repeated `Could not get registry digest (attempt N), waiting…` and then `No digest change detected within timeout; exiting 0`. Add `GITHUB_TOKEN` from a secret as above.

**If no Job appears:** Sync may have failed earlier (e.g. project whitelist). Check Argo CD app sync status and sync errors.

**"No running pod yet" repeatedly:** The hook needs a pod with a resolved `imageID` (i.e. Running or at least past image pull). It will wait up to ~20×15s. After the next sync the hook will log `phase=` and `reason=` (e.g. `phase=Pending`, `reason=ContainerCreating` or `reason=ImagePullBackOff`). Fix the deployment so a pod reaches Running:

- **No pods at all:** Deployment not created or replica 0; check Argo CD sync.
- **phase=Pending, reason=ContainerCreating:** Image still pulling; wait or check `kubectl describe pod -n f1-predictor -l app=f1-predictor` for pull errors.
- **phase=Pending, reason=ImagePullBackOff:** Image missing or pull secret wrong. Ensure `ghcr.io/brettswift/f1-predictor:live` (or `:dev`) exists and the `ghcr-pull` secret exists in the namespace (see [GHCR Pull Secret](../../docs/GHCR_PULL_SECRET.md)).
- **CrashLoopBackOff:** App is exiting; check app logs.

Once a pod is Running, the next sync’s hook will see its digest and either report "Digest unchanged" or trigger a rollout restart.

## Manual Build

If the build did not auto-trigger, run manually:

- **Prod:** Actions → Build f1-predictor prod image → Run workflow
- **Dev:** Actions → Build f1-predictor dev image → Run workflow

## ImagePullBackOff

If the image does not exist yet (e.g. first deploy or build still running), wait for the workflow to finish; kubelet will retry. Check pods: `kubectl get pods -n f1-predictor-dev` or `-n f1-predictor`.
