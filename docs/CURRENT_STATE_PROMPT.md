# Current State Prompt for New AI Session

Copy this prompt into a new AI session to provide context about the current state of the k8s_nas project:

---

## Current Project State

I'm working on a Kubernetes NAS project using k3s with GitOps via ArgoCD. Here's the current state:

### Server & Access
- **Server**: `home-server` at 10.1.0.20 (internal IP)
- **Kubeconfig**: `~/.kube/config-nas` (must set `export KUBECONFIG=~/.kube/config-nas`)
- **SSH**: `ssh bswift@10.1.0.20` or `ssh nas` (if configured)
- **Git Repo**: `git@github.com:brettswift/k8s_nas.git`
- **Current Branch**: `new-argo`

### Infrastructure
- **Kubernetes**: k3s v1.33.6+k3s1 on Pop!_OS 24.04 LTS
- **Ingress**: NGINX Ingress Controller (not Traefik)
- **Certificates**: cert-manager with Let's Encrypt DNS-01 via AWS Route53
- **Certificate**: `home-brettswift-com-dns` in `kube-system` namespace, secret `home-brettswift-com-tls`
- **Domain**: `home.brettswift.com` (main), `jellyseerr.home.brettswift.com` (subdomain)

### ArgoCD Applications (all synced and healthy except qbittorrent)
- `root-application`: Manages all Applications (Synced, Healthy)
- `argocd-config`: ArgoCD infrastructure (Synced, Healthy)
- `infrastructure`: cert-manager, monitoring (Synced, Healthy)
- `homepage`: Homepage dashboard (Synced, Healthy)
- `media-services`: Starr apps - Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, SABnzbd (Synced, Healthy)
- `jellyfin`: Jellyfin media server (Synced, Healthy)
- `qbittorrent`: qBittorrent with VPN/gluetun (Synced, Progressing)
- `monitoring`: Prometheus, Grafana (Synced, Healthy)

### Services & Ingress Routes
All services accessible via `home.brettswift.com`:
- `/` - Homepage
- `/argocd` - ArgoCD UI
- `/jellyfin` - Jellyfin media server
- `/sonarr`, `/radarr`, `/lidarr`, `/bazarr`, `/prowlarr`, `/sabnzbd` - Starr apps
- `/qbittorrent` - qBittorrent
- `/grafana`, `/prometheus` - Monitoring
- `jellyseerr.home.brettswift.com` - Jellyseerr

### Current Issues / Work in Progress
1. **qBittorrent**: Application is "Progressing" - may need PVC or configuration check
2. **Homepage**: Some widgets showing JavaScript errors (Developer, Social, Entertainment sections) - "TypeError: Failed to construct 'URL': Invalid URL"
3. **Jellyseerr**: May need Jellyfin connection configured (use `http://jellyfin:80`)

### Critical GitOps Rules
- **NEVER use `kubectl apply` on resources managed by ArgoCD**
- Always commit changes to Git and let ArgoCD sync
- All changes must go through Git → ArgoCD workflow
- Use `git add`, `git commit`, `git push` then ArgoCD will auto-sync (or manually trigger sync)

### Key Files
- ArgoCD Applications: `argocd/applicationsets/*.yaml`
- Application manifests: `apps/` directory
- Infrastructure: `apps/infrastructure/`
- Homepage config: `apps/homepage/base/config/`

---

Use this context to understand the current state and help with any issues or new features.

