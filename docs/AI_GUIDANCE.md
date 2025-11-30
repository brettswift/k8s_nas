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

## Developer and QA workflow

- **Developer**: implement changes via edits/commits; avoid breaking production. If a change causes issues, attempt up to 10 automated fixes; otherwise roll back cleanly.
- **QA**: verify prior steps and new features using a function-based shell test script (e.g., `scripts/qa-tests.sh`). Each test is a function; call the relevant test at the bottom. New features must add corresponding tests and re-run the full script.

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

## Notes

- Keep documentation concise and actionable. Prefer links to details in repository directories (e.g., `argocd/`, `apps/`, `environments/`).
- All configuration and operational changes must land via Git and be reconciled by ArgoCD.
- **GitOps Workflow**: Edit files → Commit → Push → ArgoCD auto-syncs (or manually trigger sync via ArgoCD UI/CLI)
