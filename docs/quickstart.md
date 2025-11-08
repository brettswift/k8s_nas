---
title: Quickstart
---

# Quickstart: k8s_nas

Get the media platform running fast, understand what it deploys, and where to look next.

---

## What this repo manages

- **GitOps with Argo CD**: ApplicationSets deploy infrastructure and apps from this repo.
- **Infrastructure**: cert-manager, NVIDIA device plugin, optional monitoring/ingress (via separate AppSets).
- **Media services**: Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr, Jellyfin, qBittorrent, SABnzbd, Unpackerr, Flaresolverr.
- **Routing**: NGINX Ingress (or your cluster’s default), host/path-based ingress rules.

Key locations:

- `argocd/applicationsets/`: AppSets for infrastructure and media services.
- `apps/infrastructure/`: infra components (Argo-managed).
- `apps/media-services/`: media stack (Starr, Jellyfin, etc.).
- `scripts/`: operational helpers (inventory, verify, migrate, etc.).

Note: Argo CD and monitoring may be managed via dedicated AppSets; `apps/infrastructure/kustomization.yaml` intentionally excludes some stacks to avoid cyclical management.

---

## Prerequisites

- Kubernetes cluster (k3s/k8s).
- `kubectl` with cluster access.
- Optional: NVIDIA GPU on the host if you intend to use GPU workloads.
- Git access for Argo CD to read this repo (PAT or SSH deploy key).

---

## Bring up the cluster (local/dev flow)

```bash
# Start a local cluster and install Argo CD
./start_k8s.sh
```

This script:
- Installs Argo CD into `argocd` namespace.
- Applies Argo CD projects and the root Application pointing to `argocd/applicationsets/`.
- Optionally runs `bootstrap/bootstrap.sh` to install base plugins.

Argo CD access (local port-forward):

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080  (admin / initial password from the secret)
```

---

## Configure Argo CD repo access (CRITICAL for private repos)

If this repository is private, register repo credentials in Argo CD. See `BOOTSTRAP.md` for full options. Example (HTTPS with PAT):

```bash
kubectl -n argocd create secret generic repo-github-pat \
  --from-literal=username=bswift \
  --from-literal=password="${GITHUB_TOKEN}"
```

Then apply a Repository CR to point Argo CD at this repo (see `BOOTSTRAP.md`).

---

## GitOps deployment flow

- Argo CD watches the branch defined in the AppSets (e.g., `dev_starr`).
- AppSets create Applications for:
  - `apps/infrastructure` (cert-manager, device plugins, etc.)
  - `apps/media-services` (Sonarr/Radarr/etc.)
  - Optional stacks (homepage, monitoring, qbit-only, samples)
- Sync is automated with prune + self-heal.

Tip: If your main development happens on `main`, ensure `targetRevision` in the AppSets matches. Current samples use `dev_starr`.

---

## After Argo syncs: verify services

```bash
kubectl get pods -A
```

Ingress URLs (typical):

- Sonarr: `/sonarr`
- Radarr: `/radarr`
- Lidarr: `/lidarr`
- Prowlarr: `/prowlarr`
- Bazarr: `/bazarr`
- Jellyseerr: `/jellyseerr`
- Jellyfin: `/jellyfin`
- qBittorrent: `/qbittorrent`
- SABnzbd: `/sabnzbd`

Exact hosts/paths depend on ingress configuration in `argocd/argocd-ingress.yaml` and app-specific ingress manifests.

---

## Required config: media root folders and integrations

1) Configure media root folders (must be done before adding content):
- Sonarr: `/data/media/series`
- Radarr: `/data/media/movies`

2) Configure service integrations (indexers, download clients, subtitles, etc.).

Follow this guide next:

- [Configure Starr Integrations](./configure-starr-integrations.md)

Secrets quick reference:

- `starr-secrets` holds the API keys. Use the provided scripts in `scripts/` to extract/verify keys.

---

## Troubleshooting

- If Argo apps show repo auth errors: configure the Repository credentials (PAT/SSH) per `BOOTSTRAP.md`.
- If SABnzbd shows 403 in Sonarr/Radarr: ensure URL Base `/sabnzbd` is set (see integration guide).
- If downloads don’t import: verify path mappings and mounts (usenet/torrent folders) and see the integration guide notes.

---

## Where to go next

- Architecture overview: [Architecture Clarifications](./architecture-clarifications.md)
- Deployment details: [Deployment Guide](./deployment-guide.md)
- Source structure: [Source Tree Analysis](./source-tree-analysis.md)

**Happy hacking.**


