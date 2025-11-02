# k8s_nas Project Documentation Index

**Generated:** 2025-11-01  
**Project:** k8s_nas  
**Type:** Infrastructure (Kubernetes/GitOps)  
**Repository Structure:** Monolith

---

## Project Overview

k8s_nas is a Kubernetes-based Network Attached Storage (NAS) media server infrastructure that provides a complete media management and streaming ecosystem. The project uses GitOps principles with ArgoCD for declarative, automated infrastructure management.

**Quick Reference:**
- **Type:** Infrastructure as Code / GitOps Platform
- **Primary Technology:** Kubernetes (k3s), ArgoCD, NGINX Ingress
- **Architecture Pattern:** GitOps-Driven Microservices Platform
- **Repository Type:** Monolith
- **Entry Point:** `start_k8s.sh` (cluster initialization)

---

## Generated Documentation

### Core Documentation

- **[Project Overview](./project-overview.md)**  
  High-level project summary, technology stack, and architecture overview.

- **[Architecture Documentation](./architecture.md)**  
  Comprehensive system architecture, component design, data flow, and integration patterns.

- **[Source Tree Analysis](./source-tree-analysis.md)**  
  Complete directory structure with annotations, critical folders, and integration points.

- **[Development Guide](./development-guide.md)**  
  Local development setup, workflow, testing, debugging, and common tasks.

- **[Deployment Guide](./deployment-guide.md)**  
  Production deployment procedures, server setup, SSL configuration, and maintenance.

### Existing Documentation

- **[PRD.md](../PRD.md)** - Product Requirements Document
- **[AI_GUIDANCE.md](./AI_GUIDANCE.md)** - AI assistant guidance for this project
- **[BOOTSTRAP.md](../BOOTSTRAP.md)** - Production server bootstrap guide
- **[MIGRATING_STARR.md](../MIGRATING_STARR.md)** - Migration guide from docker-compose
- **[media-server-next-steps.md](../media-server-next-steps.md)** - Service configuration next steps

---

## Getting Started

### For Developers

1. **Read [Development Guide](./development-guide.md)** for local setup
2. **Start Local Cluster:** `./start_k8s.sh`
3. **Access ArgoCD:** `kubectl port-forward svc/argocd-server -n argocd 8080:443`
4. **Review [Architecture Documentation](./architecture.md)** for system design

### For DevOps/Deployment

1. **Read [Deployment Guide](./deployment-guide.md)** for production setup
2. **Follow [BOOTSTRAP.md](../BOOTSTRAP.md)** for server initialization
3. **Configure Services:** See `media-server-next-steps.md`
4. **Set Up Monitoring:** Prometheus/Grafana in `apps/infrastructure/monitoring/`

### For Project Managers

1. **Read [Project Overview](./project-overview.md)** for high-level understanding
2. **Review [PRD.md](../PRD.md)** for product requirements
3. **Check [Source Tree Analysis](./source-tree-analysis.md)** for project structure

---

## Key Architecture Components

### Infrastructure Services
- **ArgoCD**: GitOps controller and UI
- **NGINX Ingress**: HTTP/HTTPS routing
- **cert-manager**: Automated TLS certificates
- **Istio** (optional): Service mesh

### Media Services
- **Starr Stack**: Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr
- **Jellyfin**: Media streaming server
- **Download Clients**: qBittorrent, Sabnzbd
- **Supporting Services**: VPN, Flaresolverr, Unpackerr

### Monitoring Stack
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards

---

## Quick Links

### Common Tasks

**Start Local Development:**
```bash
./start_k8s.sh
```

**Access ArgoCD:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# URL: https://localhost:8080
```

**Check Service Status:**
```bash
kubectl get pods -A
```

**View Documentation:**
- Architecture: [architecture.md](./architecture.md)
- Development: [development-guide.md](./development-guide.md)
- Deployment: [deployment-guide.md](./deployment-guide.md)

---

## Project Structure

```
k8s_nas/
├── apps/              # Application manifests
├── argocd/            # GitOps configuration
├── bootstrap/         # Cluster initialization
├── scripts/           # Operational utilities
├── docs/              # Documentation (this directory)
└── environments/      # Environment configs
```

See [Source Tree Analysis](./source-tree-analysis.md) for complete structure.

---

## Technology Stack Summary

| Category | Technology | Purpose |
|----------|-----------|---------|
| Orchestration | Kubernetes (k3s) | Container orchestration |
| GitOps | ArgoCD | Declarative deployment |
| Ingress | NGINX Ingress | HTTP/HTTPS routing |
| Certificates | cert-manager | Automated TLS |
| Monitoring | Prometheus + Grafana | Observability |
| Config Management | Kustomize | Manifest templating |

---

## AI-Assisted Development

This documentation is designed for AI-assisted development workflows. When working on this project:

1. **Reference this index** for overall project structure
2. **Use Architecture Documentation** for system design context
3. **Follow Development Guide** for local workflow
4. **Check Deployment Guide** for production procedures

### For Brownfield PRD Workflow

When creating a PRD for new features:
- Start with [Architecture Documentation](./architecture.md) for existing system context
- Reference [Source Tree Analysis](./source-tree-analysis.md) for code organization
- Use [Development Guide](./development-guide.md) for development workflow
- Review service manifests in `apps/` for configuration patterns

---

## Support and Resources

### Internal Documentation
- [AI_GUIDANCE.md](./AI_GUIDANCE.md) - AI assistant guidance
- [experiments/](./experiments/) - Experimental documentation

### External Resources
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)

---

**Last Updated:** 2025-11-01  
**Documentation Version:** 1.0  
**Project Status:** Active Development

