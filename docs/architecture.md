# k8s_nas Architecture Documentation

**Generated:** 2025-11-01  
**Project:** k8s_nas  
**Architecture Type:** Infrastructure as Code / GitOps Platform

## Executive Summary

k8s_nas is a Kubernetes-based media server infrastructure platform that provides a complete media management and streaming ecosystem. The architecture follows GitOps principles with declarative configuration management, automated deployment via ArgoCD, and path-based service routing through NGINX Ingress.

The system has been migrated from a docker-compose setup to a fully Kubernetes-native architecture, maintaining the same service functionality while adding enterprise-grade features like automatic reconciliation, rollback capabilities, and centralized monitoring.

## Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Orchestration** | Kubernetes (k3s) | Latest | Container orchestration |
| **GitOps** | ArgoCD | Stable | Declarative application delivery |
| **Ingress** | NGINX Ingress Controller | - | HTTP/HTTPS routing |
| **Service Mesh** | Istio | 1.19.0 | Advanced routing (optional) |
| **Certificates** | cert-manager | v1.13.0 | Automated TLS |
| **Monitoring** | Prometheus | Latest | Metrics collection |
| **Visualization** | Grafana | Latest | Dashboards |
| **Config Management** | Kustomize | - | Manifest templating |
| **Storage** | local-path / hostPath | - | Persistent storage |

## Architecture Pattern

**GitOps-Driven Microservices Platform**

### Key Characteristics:

1. **Declarative Configuration**: All infrastructure defined in YAML manifests
2. **Git as Source of Truth**: Git repository is the single source of truth
3. **Automated Reconciliation**: ArgoCD continuously syncs desired state
4. **Namespace Isolation**: Services organized by namespace (media, monitoring, homepage)
5. **Path-Based Routing**: All services accessible via single domain with paths
6. **Label-Driven Deployment**: Cluster labels control service enablement

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Git Repository                           │
│              (github.com/brettswift/k8s_nas)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Git Sync
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     ArgoCD (GitOps)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ ApplicationSet│  │ ApplicationSet│  │ ApplicationSet│     │
│  │ Infrastructure│  │ Media Services│  │  Monitoring   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼─────────────────┼────────────┘
          │                  │                 │
          ▼                  ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (k3s)                        │
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Infrastructure│  │ Media Services│  │  Monitoring   │     │
│  │  Namespace    │  │   Namespace  │  │   Namespace   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         NGINX Ingress Controller                     │   │
│  │  Routes: https://home.brettswift.com/<service>       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Access                           │
│         https://home.brettswift.com/<service>                │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### 1. GitOps Layer (ArgoCD)

**Components:**
- **ApplicationSets**: Generate ArgoCD Applications dynamically
- **AppProjects**: Define RBAC and resource permissions
- **Root Application**: Entry point for GitOps workflow

**Deployment Flow:**
1. Developer commits changes to Git repository
2. ArgoCD detects changes (polling or webhook)
3. ApplicationSet generates/updates Applications
4. ArgoCD syncs desired state to cluster
5. Kubernetes applies changes

#### 2. Infrastructure Layer

**Core Services:**
- **ArgoCD**: GitOps controller and UI
- **NGINX Ingress Controller**: HTTP/HTTPS routing
- **cert-manager**: Automated TLS certificate management
- **Istio** (optional): Service mesh for advanced routing

**Monitoring Stack:**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards

#### 3. Application Layer (Media Services)

**Starr Stack** (Media Management):
- **Sonarr**: TV series management
- **Radarr**: Movie management
- **Lidarr**: Music management
- **Bazarr**: Subtitle management
- **Prowlarr**: Indexer management
- **Jellyseerr**: Content request management

**Download Services:**
- **qBittorrent**: BitTorrent client (VPN-enabled)
- **Sabnzbd**: Usenet client
- **Flaresolverr**: CAPTCHA solver
- **Unpackerr**: Archive extraction

**Media Server:**
- **Jellyfin**: Media streaming server

**Supporting Services:**
- **VPN (Gluetun)**: Network isolation for downloads
- **Homepage**: Service dashboard

## Data Architecture

### Storage Strategy

**PersistentVolumeClaims (PVCs):**
- Configuration data: `/config` mounted from PVCs
- Each service has its own PVC for configuration
- Storage class: `local-path` (development) or hostPath (production)

**Host Path Volumes:**
- Media files: `/mnt/data/media`
- Downloads: `/mnt/data/downloads`
- Configurations: `/mnt/data/configs/<service>`

**Volume Organization:**
```
/mnt/data/
├── media/           # Media library (movies, TV, music)
├── downloads/        # Download staging area
└── configs/          # Service configurations
    ├── sonarr/
    ├── radarr/
    ├── jellyfin/
    └── ...
```

### Inter-Service Communication

**Internal Communication (Cluster DNS):**
- Services communicate via Kubernetes Service DNS
- Format: `<service-name>.<namespace>.svc.cluster.local:<port>`
- Example: `sonarr.media.svc.cluster.local:8989`

**Shared Configuration:**
- `common-configmap.yaml` contains service URLs and common environment variables
- Services reference ConfigMap for inter-service URLs

**Example Service URLs (from ConfigMap):**
- `SONARR_URL`: `http://sonarr.media.svc.cluster.local:8989`
- `RADARR_URL`: `http://radarr.media.svc.cluster.local:7878`
- `QBITTORRENT_URL`: `http://qbittorrent.qbittorrent.svc.cluster.local:8080`

## API Design

### External APIs (Ingress)

All services exposed via path-based routing:

| Service | Path | Port | Purpose |
|---------|------|------|---------|
| Homepage | `/` | 3000 | Service dashboard |
| Sonarr | `/sonarr` | 8989 | TV management |
| Radarr | `/radarr` | 7878 | Movie management |
| Lidarr | `/lidarr` | 8686 | Music management |
| Bazarr | `/bazarr` | 6767 | Subtitle management |
| Prowlarr | `/prowlarr` | 9696 | Indexer management |
| Jellyseerr | `/jellyseerr` | 5055 | Request management |
| Jellyfin | `/jellyfin` | 8096 | Media server |
| qBittorrent | `/qbittorrent` | 8080 | BitTorrent client |
| Sabnzbd | `/sabnzbd` | 8081 | Usenet client |
| Flaresolverr | `/flaresolverr` | 8191 | CAPTCHA solver |
| Prometheus | `/prometheus` | 9090 | Metrics |
| Grafana | `/grafana` | 3000 | Dashboards |
| ArgoCD | `/argocd` | 443 | GitOps UI |

### Internal APIs (Service-to-Service)

Services communicate via Kubernetes Service DNS:
- REST APIs for Starr services
- qBittorrent API for download management
- Jellyfin API for media management

## Component Structure

### Application Organization

**Pattern: Kustomize-Based Structure**

```
apps/
├── <service-category>/
│   ├── <service-name>/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   ├── configmap.yaml (optional)
│   │   └── kustomization.yaml
│   └── kustomization.yaml (category root)
```

**Benefits:**
- Reusable base configurations
- Environment overlays (dev/prod)
- DRY principle (Don't Repeat Yourself)

### Service Definitions

Each service typically includes:
1. **Namespace**: Logical isolation
2. **Deployment**: Pod specifications
3. **Service**: Cluster-internal networking
4. **Ingress**: External access routing
5. **ConfigMap**: Configuration data
6. **PVC**: Persistent storage for configs
7. **Health Checks**: Liveness and readiness probes

## Source Tree

See [Source Tree Analysis](./source-tree-analysis.md) for complete directory structure.

**Key Directories:**
- `apps/`: Application manifests
- `argocd/`: GitOps configuration
- `bootstrap/`: Cluster initialization
- `scripts/`: Operational utilities

## Development Workflow

1. **Local Development**:
   - Start cluster: `./start_k8s.sh`
   - Make changes to manifests
   - Test locally on `dev` branch
   - Commit and push

2. **GitOps Deployment**:
   - ArgoCD watches repository
   - Changes automatically synced to cluster
   - Self-healing ensures desired state

3. **Production Deployment**:
   - Merge to `main` branch
   - ArgoCD syncs to production cluster
   - Monitoring verifies deployment

See [Development Guide](./development-guide.md) for detailed instructions.

## Deployment Architecture

### Environment Strategy

**Development (`dev` branch):**
- Local k3d cluster (macOS) or k3s (Linux)
- Minimal resource requirements
- Local-path storage

**Production (`main` branch):**
- Remote server at 10.0.0.20
- Full resource allocation
- HostPath storage for media files
- Production-grade certificates

### Deployment Process

1. **Bootstrap**: `bootstrap/bootstrap.sh`
   - Install cert-manager
   - Install Istio (optional)
   - Install ArgoCD

2. **Application Deployment**:
   - ArgoCD ApplicationSets create Applications
   - Applications sync from Git
   - Kubernetes applies manifests

3. **Continuous Sync**:
   - ArgoCD polls Git or uses webhooks
   - Automatic reconciliation
   - Self-healing on drift

See [Deployment Guide](./deployment-guide.md) for detailed steps.

## Testing Strategy

### Health Checks

All services include:
- **Liveness Probes**: Restart unhealthy containers
- **Readiness Probes**: Route traffic only to ready pods

### Monitoring

- **Prometheus**: Scrapes metrics from services
- **Grafana**: Visualizes metrics and alerts
- **Service Discovery**: Automatic detection of scrape targets

### Validation

- **Manifest Validation**: `kubectl apply --dry-run`
- **ArgoCD Sync Status**: Monitor Application sync status
- **QA Tests**: `scripts/qa-tests.sh` for integration testing

## Security Architecture

### Authentication & Authorization

- **ArgoCD RBAC**: Project-based access control
- **Kubernetes RBAC**: ServiceAccount-based permissions
- **Ingress TLS**: cert-manager automated certificates

### Network Security

- **Namespace Isolation**: Services isolated by namespace
- **VPN Isolation**: Download services via VPN (Gluetun)
- **Service Mesh** (optional): Istio for advanced policies

### Secrets Management

- **Kubernetes Secrets**: Stored as encrypted in etcd
- **cert-manager**: Manages TLS certificates
- **ArgoCD Secrets**: Git repository credentials

## Scalability Considerations

### Horizontal Scaling

- **Replicas**: Services configured with `replicas: 1` (adjustable)
- **Resource Limits**: CPU/memory limits prevent resource exhaustion
- **Horizontal Pod Autoscaler**: Can be added for automatic scaling

### Vertical Scaling

- **Resource Requests/Limits**: Defined per service
- **Storage**: PVCs can be expanded if supported

### Performance Optimization

- **Health Checks**: Prevent routing to unhealthy pods
- **Resource Limits**: Prevent single service from consuming all resources
- **Monitoring**: Identify bottlenecks via Prometheus/Grafana

