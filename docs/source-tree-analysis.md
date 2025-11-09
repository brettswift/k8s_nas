# Source Tree Analysis

**Generated:** 2025-11-01  
**Project:** k8s_nas  
**Type:** Infrastructure (Kubernetes/GitOps)

## Complete Directory Tree

```
k8s_nas/
├── apps/                                    # Application manifests
│   ├── homepage/                            # Homepage dashboard service
│   │   └── base/                            # Base Kustomize configuration
│   │       ├── configmap.yaml              # Homepage configuration
│   │       ├── deployment.yaml             # Homepage deployment
│   │       ├── ingress.yaml                # Ingress routing
│   │       ├── kustomization.yaml          # Kustomize manifest
│   │       ├── namespace.yaml              # Namespace definition
│   │       ├── service.yaml                # Service definition
│   │       └── serviceaccount.yaml          # ServiceAccount + RBAC
│   ├── infrastructure/                     # Core infrastructure services
│   │   ├── argocd/                         # ArgoCD configuration
│   │   │   ├── ingress.yaml                # ArgoCD ingress
│   │   │   └── kustomization.yaml          # Kustomize config
│   │   ├── kustomization.yaml              # Infrastructure root Kustomize
│   │   ├── monitoring/                     # Monitoring stack (Prometheus/Grafana)
│   │   │   ├── grafana-configmap.yaml      # Grafana configuration
│   │   │   ├── grafana-dashboard-config.yaml  # Dashboard provisioning
│   │   │   ├── grafana-dashboard-configmap.yaml  # Dashboard definitions
│   │   │   ├── grafana-deployment.yaml     # Grafana deployment
│   │   │   ├── grafana-ingress.yaml        # Grafana ingress
│   │   │   ├── grafana-service.yaml        # Grafana service
│   │   │   ├── kustomization.yaml          # Kustomize config
│   │   │   ├── namespace.yaml              # Monitoring namespace
│   │   │   ├── prometheus-configmap.yaml   # Prometheus config
│   │   │   ├── prometheus-deployment.yaml  # Prometheus deployment
│   │   │   ├── prometheus-ingress.yaml     # Prometheus ingress
│   │   │   ├── prometheus-service.yaml     # Prometheus service
│   │   │   └── prometheus-serviceaccount.yaml  # Prometheus RBAC
│   │   ├── nginx/                          # NGINX Ingress configuration
│   │   │   └── argocd-ingress.yaml         # ArgoCD ingress via NGINX
│   │   └── nvidia-device-plugin/           # GPU support
│   │       ├── daemonset.yaml              # NVIDIA device plugin DaemonSet
│   │       └── kustomization.yaml          # Kustomize config
│   ├── media-services/                     # Media server applications
│   │   ├── jellyfin/                       # Jellyfin media server
│   │   │   ├── configmap.yaml              # Jellyfin configuration
│   │   │   ├── deployment.yaml             # Jellyfin deployment
│   │   │   ├── ingress-redirect.yaml       # Redirect ingress
│   │   │   ├── ingress.yaml                # Main ingress
│   │   │   ├── kustomization.yaml          # Kustomize config
│   │   │   └── network.xml                 # Network configuration
│   │   ├── kustomization.yaml              # Media services root Kustomize
│   │   ├── qbittorrent/                    # qBittorrent download client
│   │   │   ├── deployment.yaml              # qBittorrent deployment
│   │   │   ├── ingress.yaml                # Ingress routing
│   │   │   ├── kustomization.yaml          # Kustomize config
│   │   │   └── service.yaml                # Service definition
│   │   └── starr/                          # Starr media management stack
│   │       ├── bazarr-deployment.yaml      # Bazarr (subtitles)
│   │       ├── bazarr-ingress.yaml         # Bazarr ingress
│   │       ├── common-configmap.yaml       # Shared configuration
│   │       ├── flaresolverr-deployment.yaml # Flaresolverr (CAPTCHA)
│   │       ├── flaresolverr-ingress.yaml   # Flaresolverr ingress
│   │       ├── jellyseerr-deployment.yaml  # Jellyseerr (requests)
│   │       ├── jellyseerr-ingress.yaml     # Jellyseerr ingress
│   │       ├── kustomization.yaml          # Kustomize config
│   │       ├── lidarr-deployment.yaml      # Lidarr (music)
│   │       ├── lidarr-ingress.yaml         # Lidarr ingress
│   │       ├── namespace.yaml              # Media namespace
│   │       ├── prowlarr-deployment.yaml     # Prowlarr (indexers)
│   │       ├── prowlarr-ingress.yaml       # Prowlarr ingress
│   │       ├── pvcs.yaml                   # PersistentVolumeClaims
│   │       ├── radarr-deployment.yaml       # Radarr (movies)
│   │       ├── radarr-ingress.yaml         # Radarr ingress
│   │       ├── sabnzbd-deployment.yaml      # Sabnzbd (Usenet)
│   │       ├── sabnzbd-ingress.yaml        # Sabnzbd ingress
│   │       ├── sonarr-deployment.yaml       # Sonarr (TV series)
│   │       ├── sonarr-ingress.yaml          # Sonarr ingress
│   │       ├── unpackerr-deployment.yaml    # Unpackerr (extraction)
│   │       └── vpn-deployment.yaml          # VPN service (Gluetun)
│   └── sample-hello/                       # Example application
│       ├── base/                           # Base configuration
│       │   ├── configmap.yaml              # ConfigMap
│       │   ├── deployment.yaml             # Deployment
│       │   ├── ingress.yaml                # Ingress
│       │   ├── kustomization.yaml          # Kustomize config
│       │   ├── namespace.yaml               # Namespace
│       │   └── service.yaml                 # Service
│       └── overlays/                        # Environment overlays
│           ├── dev/                        # Development overlay
│           │   └── kustomization.yaml      # Dev Kustomize
│           └── prod/                        # Production overlay
│               └── kustomization.yaml      # Prod Kustomize
├── argocd/                                  # ArgoCD GitOps configuration
│   ├── applicationsets/                     # ApplicationSet definitions
│   │   ├── argocd-infrastructure-appset.yaml  # ArgoCD infrastructure
│   │   ├── homepage-appset.yaml             # Homepage ApplicationSet
│   │   ├── jellyfin-appset.yaml             # Jellyfin ApplicationSet
│   │   ├── media-services-appset.yaml       # Media services ApplicationSet
│   │   ├── monitoring-appset.yaml          # Monitoring ApplicationSet
│   │   ├── qbit-appset.yaml                 # qBittorrent ApplicationSet
│   │   └── sample-hello-appset.yaml         # Sample app ApplicationSet
│   ├── argocd-ingress.yaml                  # ArgoCD ingress config
│   ├── nas.yaml                             # NAS ArgoCD project
│   ├── projects/                            # ArgoCD AppProject definitions
│   │   ├── admin.yaml                       # Admin project
│   │   ├── apps.yaml                        # Apps project
│   │   └── infrastructure.yaml               # Infrastructure project
│   └── root-app.yaml                        # Root ArgoCD application
├── bootstrap/                               # Cluster bootstrap scripts
│   ├── bootstrap.sh                         # Main bootstrap script
│   ├── install_istio.sh                    # Istio installation
│   └── k8s_plugins.sh                       # Plugin installation
├── bmad/                                    # BMAD framework rules (AI assistance)
│   ├── _cfg/                                # Configuration metadata
│   ├── bmm/                                 # BMM module
│   └── core/                                # Core BMAD module
├── certificates/                            # Certificate storage (gitignored)
├── docs/                                    # Project documentation
│   ├── experiments/                         # Experimental documentation
│   ├── stories/                             # User stories
│   ├── AI_GUIDANCE.md                       # AI assistant guidance
│   ├── PRD.md                               # Product Requirements Document
│   └── bmm-workflow-status.yaml             # Workflow status tracking
├── environments/                            # Environment configurations
│   ├── dev/                                 # Development environment
│   │   └── cluster-config.yaml             # Dev cluster config
│   └── server/                              # Production server configs
├── scripts/                                 # Operational scripts
│   ├── argocd-local-user.sh                # ArgoCD user management
│   ├── cert-manager-blue-green-test.sh      # Certificate testing
│   ├── cert-manager-setup.sh                # Certificate setup
│   ├── fetch-kubeconfig.sh                  # Kubeconfig retrieval
│   ├── inventory-argocd.sh                  # ArgoCD inventory
│   ├── migrate-starr-configs.sh             # Starr config migration
│   ├── monitor-certificates.sh              # Certificate monitoring
│   ├── qa-tests.sh                          # QA testing
│   ├── setup-wildcard-cert.sh               # Wildcard cert setup
│   └── update-starr-deployments.sh          # Starr deployment updates
├── .cursor/                                 # Cursor IDE configuration
├── BOOTSTRAP.md                             # Bootstrap documentation
├── docker-compose.yml                       # Legacy docker-compose config (reference)
├── get-argocd-password.sh                    # ArgoCD password helper
├── JELLYFIN_TODO.md                         # Jellyfin-specific TODOs
├── local-argocd-access.sh                   # Local ArgoCD access
├── media-server-next-steps.md               # Next steps documentation
├── migrate-jellyfin-data.sh                # Jellyfin migration script
├── MIGRATING_STARR.md                       # Starr migration guide
├── README.md                                # Project README
├── root-application.yaml                    # Root ArgoCD application
├── start_k8s.sh                             # Start cluster script
└── stop_k8s.sh                              # Stop cluster script
```

## Critical Folders

### 1. `apps/` - Application Manifests
**Purpose:** Contains all Kubernetes application manifests organized by service category.

**Key Subdirectories:**
- **`infrastructure/`**: Core platform services (ArgoCD, monitoring, ingress)
- **`media-services/`**: Media server applications (Starr stack, Jellyfin, qBittorrent)
- **`homepage/`**: Service dashboard
- **`sample-hello/`**: Example application with dev/prod overlays

**Pattern:** Uses Kustomize for configuration management with base configurations and optional overlays.

### 2. `argocd/` - GitOps Configuration
**Purpose:** ArgoCD ApplicationSets and project definitions for GitOps deployment.

**Key Files:**
- **`applicationsets/`**: ApplicationSet definitions that drive GitOps deployments
- **`projects/`**: ArgoCD AppProject definitions (RBAC and permissions)
- **`root-app.yaml`**: Root ArgoCD application

**Pattern:** ApplicationSets use label selectors and generators to automatically create ArgoCD Applications.

### 3. `bootstrap/` - Cluster Initialization
**Purpose:** Scripts for initializing Kubernetes cluster and installing required plugins.

**Scripts:**
- `bootstrap.sh`: Main bootstrap orchestrator
- `k8s_plugins.sh`: Installs cert-manager, Istio, NVIDIA toolkit
- `install_istio.sh`: Istio service mesh installation

### 4. `scripts/` - Operational Scripts
**Purpose:** Maintenance, migration, and operational utilities.

**Categories:**
- **Certificate Management**: `cert-manager-setup.sh`, `setup-wildcard-cert.sh`, `monitor-certificates.sh`
- **Migration**: `migrate-starr-configs.sh`, `update-starr-deployments.sh`
- **ArgoCD Management**: `argocd-local-user.sh`, `inventory-argocd.sh`
- **Testing**: `qa-tests.sh`

### 5. `environments/` - Environment Configurations
**Purpose:** Environment-specific configurations (dev vs production).

**Structure:**
- `dev/`: Local development cluster configs
- `server/`: Production server configs

## Entry Points

1. **Cluster Startup**: `start_k8s.sh` - Initializes k3s/k3d cluster and ArgoCD
2. **Bootstrap**: `bootstrap/bootstrap.sh` - Installs plugins and infrastructure
3. **GitOps Root**: `root-application.yaml` or `argocd/root-app.yaml` - ArgoCD entry point
4. **Application Deployment**: `argocd/applicationsets/*.yaml` - ApplicationSet definitions

## Integration Points

### Between Services
- **Inter-service Communication**: Kubernetes Service DNS (e.g., `sonarr.media.svc.cluster.local:8989`)
- **Configuration Sharing**: `apps/media-services/starr/common-configmap.yaml` contains shared environment variables
- **Service Discovery**: Kubernetes native DNS-based service discovery

### Between Environments
- **Branch-based**: `dev` branch → development cluster, `main` branch → production
- **Overlays**: `apps/sample-hello/overlays/` demonstrates environment-specific configuration

### With External Systems
- **Git Repository**: ArgoCD syncs from `https://github.com/brettswift/k8s_nas.git`
- **DNS**: Services exposed via `home.brettswift.com` with path-based routing
- **Storage**: Host path volumes on production (`/mnt/data/*`)

## File Organization Patterns

1. **Kustomize Pattern**: Each application has a `kustomization.yaml` that references its resources
2. **Namespace Isolation**: Services organized by namespace (media, monitoring, homepage, etc.)
3. **ApplicationSet Pattern**: GitOps-driven deployment via ArgoCD ApplicationSets
4. **Common Config**: Shared configuration via ConfigMaps (`common-configmap.yaml` for Starr services)

## Notable Files

- **`docker-compose.yml`**: Reference for legacy docker-compose configuration (migration source)
- **`MIGRATING_STARR.md`**: Migration guide from docker-compose to Kubernetes
- **`BOOTSTRAP.md`**: Production server setup guide
- **`docs/PRD.md`**: Product Requirements Document




