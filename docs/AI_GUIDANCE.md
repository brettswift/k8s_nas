# General behaviour

**CRITICAL: This is a GitOps project. ALL changes must be made via Git commits and ArgoCD Applications. NO manual kubectl apply commands without explicit permission. Always commit changes to Git and let ArgoCD sync.**

- Do NOT spin up a local cluster. There is no local cluster; target the remote server at 10.1.0.20 only.
- Favor small, idempotent steps. Use `set -euo pipefail`. Never commit or echo secrets.
- One turn per objective: run, verify, and summarize results. Log outcomes in commit messages.
- **NEVER use `kubectl apply` directly on resources managed by ArgoCD. Always commit to Git and let ArgoCD sync.**

# AI Guidance for Kubernetes NAS Project

## Operating assumptions

- **Environment**: Single remote k3s server at 10.1.0.20 (internal IP), hostname `home-server` (no local k3d/k3s).
- **GitOps**: All infra changes via Git + ArgoCD Applications. Sync via ArgoCD, not via kubectl apply.
- **Safety**: Treat `new-argo` as current working branch; use feature branches and PRs to merge. Roll back via git revert if a change cannot be fixed within 10 attempts.
- **Ingress**: NGINX Ingress Controller is in use (not Traefik currently).
- **Certificates**: cert-manager with Let's Encrypt DNS-01 challenge via AWS Route53 for automated certificate management.

## Server access

- **Server**: `home-server` at 10.1.0.20 (internal IP), accessible via SSH
- **Kubeconfig**: `~/.kube/config-nas` (set `export KUBECONFIG=~/.kube/config-nas` before kubectl commands)
- **SSH**:

```bash
ssh bswift@10.1.0.20
# or if configured:
ssh nas
```

## Branch strategy

- **new-argo**: Current working branch for ArgoCD Applications pattern
- **main**: production deployments (legacy)
- **dev_***: Feature branches for specific services
- **feat/***: Feature work; open PRs as appropriate

## ArgoCD usage

- **Access**: https://home.brettswift.com/argocd (via NGINX ingress)
- **Pattern**: Using ArgoCD Applications (not ApplicationSets) - see `argocd/applicationsets/` directory
- **Root Application**: `root-application` manages all other Applications
- **Sync Policy**: Most applications have automated sync with prune and selfHeal enabled
- Manage applications via Git commits; enable/disable services through Git-controlled values and labels.
- **NEVER manually apply resources managed by ArgoCD** - always commit to Git and let ArgoCD sync.
- **Do not advance local `live`** during deployments. Keep local `live` at a known rollback point.
- **Deploy by pushing feature branch directly to remote `live`** (for example, `git push origin <feature-branch>:live`) while staying on the feature branch locally.
- **If local `live` is moved by mistake**, immediately reset it back to the pre-deploy commit.

## Developer and QA workflow

- **Developer**: implement changes via edits/commits; avoid breaking production. If a change causes issues, attempt up to 10 automated fixes; otherwise roll back cleanly.
- **QA**: verify prior steps and new features using a function-based shell test script (e.g., `scripts/qa-tests.sh`). Each test is a function; call the relevant test at the bottom. New features must add corresponding tests and re-run the full script.

## Network and DNS (critical for contributors)

- **All IPs are local/private.** The cluster and ingress are at 10.1.0.20. DNS (Route53 via external-dns) resolves hostnames to this private IP. **Nothing is pointed at a public IP.** Services are only reachable from your local network / machine (e.g. on the same LAN or VPN), not from the public internet.
- **New subdomain ingresses:** Use both external-dns annotations so the record is a CNAME to the main hostname (consistent with other services): `external-dns.alpha.kubernetes.io/hostname: <subdomain>.home.brettswift.com` and `external-dns.alpha.kubernetes.io/target: home.brettswift.com`. Without `target`, external-dns creates an A record to the ingress IP (still the same local IP); with `target`, it creates a CNAME to `home.brettswift.com`.

## Current Infrastructure

- **Kubernetes**: k3s v1.33.6+k3s1 on Pop!_OS 24.04 LTS
- **Ingress**: NGINX Ingress Controller
- **Certificates**: cert-manager with Let's Encrypt DNS-01 via Route53
- **Certificate**: `home-brettswift-com-dns` Certificate in `kube-system` namespace, secret `home-brettswift-com-tls`
- **Domain**: `home.brettswift.com` (main), `jellyseerr.home.brettswift.com` (subdomain)

## Current ArgoCD Applications

- `root-application`: Manages all other Applications
- `argocd-config`: ArgoCD's own infrastructure (ingress, config)
- `infrastructure`: cert-manager, monitoring components
- `homepage`: Homepage dashboard
- `media-services`: Starr apps (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, SABnzbd)
- `jellyfin`: Jellyfin media server
- `qbittorrent`: qBittorrent with VPN (gluetun)
- `monitoring`: Prometheus, Grafana

## Stateful apps (PVCs) with ArgoCD auto-sync

**Problem seen 2026-04-18:** `travel-planner` had a PVC manifest in Git but it was **not** listed in `kustomization.yaml` resources while the app used `automated: { prune: true, selfHeal: true }`. A later commit added `pvc.yaml` to `kustomization`. ArgoCD reconciled drift against a manually-created PVC on **`local-path`**, which **replaced** the claim and **wiped** the SQLite volume.

**Rules for agents**

- From the **first** commit of a stateful app, include every PVC in `kustomization.yaml` resources (or do not use a PVC until it is fully wired). Never “add PVC to kustomize later” without a backup and a migration plan.
- **`local-path`**: deleting the PVC deletes the underlying host directory — data is not recoverable from the cluster alone.
- **Intentional wipe:** scale deployment to 0 → backup if needed → `kubectl delete pvc …` → let GitOps recreate → restore data → scale up. Do not rely on ArgoCD prune to “clean up” data PVCs.

**travel-planner-data** uses annotations so ArgoCD will **not** prune or delete the PVC on sync; you can still remove it explicitly with `kubectl` when you intend to reset the database.

## Application image refresh (multi-repo)

This cluster runs **custom images** built in **separate app repositories** (for example `travel-planner`, `f1-predictor`). `k8s_nas` holds manifests; it usually does **not** commit a new digest for every app release when using a **mutable tag** (`:latest`, `:dev`, `:live`) plus **`imagePullPolicy: Always`**.

### End-to-end flow (numbered)

1. **App repo:** Merge (or push) to the branch your GitHub Actions workflow watches (often `main`). CI builds and pushes the image to GHCR.
2. **Registry:** The tag you use in the Deployment manifest now points at a **new digest** behind the same tag string.
3. **Kubernetes:** Pods do not automatically restart when only the digest changes. Either:
   - **ArgoCD PostSync Job (`image-refresh`)** — polls GHCR for the manifest digest, compares to the running pod’s `imageID`, and runs `kubectl rollout restart` when they differ; or
   - **Manual:** `kubectl rollout restart deployment/<name> -n <namespace>` after you confirm the new image exists.
4. **GitOps:** Ensure the app’s `kustomization.yaml` actually **lists** `image-refresh-hook.yaml` and `image-refresh-rbac.yaml` if you rely on that pattern; otherwise the hook never runs.
5. **Verify:** ArgoCD app healthy, `kubectl rollout status deployment/<name> -n <namespace>`, and optionally `kubectl logs job/image-refresh -n <namespace>` (job name may vary after hook recreation).

### Per-app reference

| App (example) | Namespace (typical) | Deployment | Image (see manifest) | PostSync `image-refresh` in kustomize |
| --- | --- | --- | --- | --- |
| travel-planner | `travel-planner` | `travel-planner` | `ghcr.io/brettswift/travel-planner:latest` | Must be in [`apps/travel-planner/base/kustomization.yaml`](../apps/travel-planner/base/kustomization.yaml) |
| f1-predictor | `f1-predictor` / `f1-predictor-dev` | (see overlay) | `ghcr.io/...` `:live` / `:dev` | Yes — see [`apps/f1-predictor/DEPLOYMENT.md`](../apps/f1-predictor/DEPLOYMENT.md) |

Add rows for other services as they gain the same pattern.

### Troubleshooting

- The hook script often **exits 0** even when GHCR auth fails or the digest cannot be read — **read the Job logs**, not only the exit code.
- **`ghcr-pull`** (or equivalent) must exist in the **same namespace** as the Job when the registry is private.
- If CI finishes **after** the hook’s poll window, trigger an **ArgoCD Refresh** on the Application or run a **manual rollout restart**.
- **Design references:** [`docs/GUIDE_PUBLISHING_NEW_SITE.md`](GUIDE_PUBLISHING_NEW_SITE.md), [`docs/plans/f1-predictor-event-driven-image-refresh.md`](plans/f1-predictor-event-driven-image-refresh.md).

## Notes

- Keep documentation concise and actionable. Prefer links to details in repository directories (e.g., `argocd/`, `apps/`, `environments/`).
- All configuration and operational changes must land via Git and be reconciled by ArgoCD.
- **GitOps Workflow**: Edit files → Commit → Push → ArgoCD auto-syncs (or manually trigger sync via ArgoCD UI/CLI)
