# k8s_nas Project Overview

**Author:** Brett  
**Date:** 2025-11-01  
**Project Type:** Infrastructure (Kubernetes/GitOps)  
**Repository Type:** Monolith  

## Executive Summary

k8s_nas is a Kubernetes-based Network Attached Storage (NAS) media server infrastructure project that has been migrated from a docker-compose setup to a GitOps-managed Kubernetes deployment. The project manages a complete media server stack including media management services (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr), download clients (qBittorrent, Sabnzbd), media server (Jellyfin), and supporting infrastructure services (VPN, Unpackerr, Flaresolverr).

The infrastructure follows a GitOps-first approach where all changes are managed through ArgoCD ApplicationSets, enabling declarative infrastructure management and automatic synchronization from Git repositories.

## Technology Stack Summary

| Category | Technology | Version/Details | Justification |
|----------|-----------|-----------------|---------------|
| Container Orchestration | Kubernetes (k3s) | Latest | Lightweight, production-ready Kubernetes distribution |
| GitOps | ArgoCD | Stable | Declarative application delivery and sync |
| Ingress | NGINX Ingress Controller | - | Path-based routing for services |
| Service Mesh | Istio | 1.19.0 | Optional service mesh for advanced routing |
| Certificate Management | cert-manager | v1.13.0 | Automated SSL certificate provisioning |
| Monitoring | Prometheus | Latest | Metrics collection |
| Visualization | Grafana | Latest | Metrics visualization and dashboards |
| Configuration Management | Kustomize | - | Kubernetes configuration management |
| Container Runtime | containerd | - | Via k3s |
| GPU Support | NVIDIA Container Toolkit | - | GPU acceleration for media processing |

## Architecture Type

**Infrastructure/Platform as Code (IaC/PaC)**

This project follows infrastructure-as-code principles with:
- **Declarative Configuration**: All infrastructure defined in YAML manifests
- **GitOps Pattern**: ArgoCD ApplicationSets for automated deployment
- **Namespace Isolation**: Separate namespaces for different service categories
- **Label-Driven Deployment**: Cluster labels control which services are deployed
- **Path-Based Routing**: All services accessible via `https://home.brettswift.com/<service>`

## Repository Structure

This is a **monolith** repository containing all infrastructure and application manifests organized by function:

- **`apps/`**: Application manifests organized by category
  - `infrastructure/`: Core infrastructure services (ArgoCD, monitoring, ingress)
  - `media-services/`: Media management and streaming services
  - `homepage/`: Service dashboard/landing page
  - `sample-hello/`: Example/demo application
- **`argocd/`**: ArgoCD configuration
  - `applicationsets/`: GitOps ApplicationSet definitions
  - `projects/`: ArgoCD project definitions
- **`bootstrap/`**: Cluster setup and initialization scripts
- **`scripts/`**: Operational and maintenance scripts
- **`docs/`**: Project documentation
- **`environments/`**: Environment-specific configurations (dev, server)

## Key Architectural Components

### 1. GitOps Deployment Model
- **ArgoCD ApplicationSets**: Label-driven application deployment
- **Branch Strategy**: `dev` for local development, `main` for production
- **Automated Sync**: Self-healing deployments with automatic reconciliation

### 2. Service Categories

**Infrastructure Services:**
- ArgoCD (GitOps controller)
- NGINX Ingress Controller
- cert-manager (TLS certificates)
- Prometheus + Grafana (monitoring)

**Media Services (Starr Stack):**
- Sonarr (TV series management)
- Radarr (Movie management)
- Lidarr (Music management)
- Bazarr (Subtitle management)
- Prowlarr (Indexer management)
- Jellyseerr (Request management)
- Jellyfin (Media server)
- qBittorrent (BitTorrent client with VPN)
- Sabnzbd (Usenet client)
- Flaresolverr (CAPTCHA solver)
- Unpackerr (Archive extraction)

### 3. Network Architecture
- **Path-based routing** via NGINX Ingress
- **VPN isolation** for download services (qBittorrent)
- **Cluster-internal service communication** via Kubernetes Service DNS
- **TLS termination** at ingress level with cert-manager

### 4. Storage Architecture
- **PersistentVolumeClaims** for service configuration and data
- **hostPath volumes** for media files (production)
- **local-path storage class** for local development

## Deployment Environments

1. **Development (`dev` branch)**: Local k3s/k3d cluster for testing
2. **Production (`main` branch)**: Remote server at 10.0.0.20

## Links to Detailed Documentation

- [Architecture Documentation](./architecture.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)
- [Deployment Guide](./deployment-guide.md)








