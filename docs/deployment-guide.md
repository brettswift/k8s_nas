# Deployment Guide

**Project:** k8s_nas  
**Last Updated:** 2025-11-01

## Overview

This guide covers deploying the k8s_nas infrastructure to production servers. The deployment process uses GitOps with ArgoCD for automated, declarative infrastructure management.

## Prerequisites

### Production Server Requirements

- **OS**: Ubuntu 20.04+ or Pop!_OS 22.04+ (recommended)
- **RAM**: Minimum 8GB, 16GB+ recommended
- **CPU**: 4+ cores recommended
- **Storage**: 500GB+ available space for media files
- **Network**: Static IP address, ports 80/443 accessible
- **DNS**: Domain name configured (e.g., `home.brettswift.com`)
- **Access**: Root/sudo access

### Software Requirements

- kubectl
- k3s
- Helm 3.x
- Git
- Docker (via k3s)

## Initial Server Setup

### 1. Server Preparation

**Update System:**
```bash
sudo apt update && sudo apt upgrade -y
```

**Install Prerequisites:**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. Install k3s

```bash
# Install k3s with disabled Traefik (using NGINX instead)
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Add k3s to PATH
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

# Set KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc

# Verify installation
kubectl get nodes
```

### 3. Clone Repository

```bash
# Clone repository (adjust URL if private)
git clone https://github.com/brettswift/k8s_nas.git
cd k8s_nas

# Make scripts executable
chmod +x start_k8s.sh stop_k8s.sh bootstrap/*.sh scripts/*.sh
```

### 4. Bootstrap Cluster

**Basic Bootstrap (Plugins Only):**
```bash
./start_k8s.sh --bootstrap
```

**Full Bootstrap with Istio:**
```bash
./start_k8s.sh --bootstrap-istio
```

This installs:
- ArgoCD
- cert-manager
- Istio (optional)
- NVIDIA Container Toolkit (if GPU available)
- Sets up ApplicationSets pattern

## ArgoCD Configuration

### 1. Access ArgoCD

**Port Forward (temporary):**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Access UI:**
- URL: `https://localhost:8080`
- Username: `admin`
- Password: Run `./get-argocd-password.sh` to retrieve

### 2. Configure Repository Access

**Add Repository in ArgoCD:**
```bash
# Via CLI
argocd repo add git@github.com:brettswift/k8s_nas.git \
  --ssh-private-key-path ~/.ssh/id_rsa \
  --name k8s_nas

# Or via UI:
# Settings > Repositories > Connect Repo
```

**Verify Repository Access:**
```bash
argocd repo list
```

### 3. Set Up Root Application

```bash
# Apply root application
kubectl apply -f root-application.yaml

# Or use argocd CLI
argocd app create root-app \
  --repo https://github.com/brettswift/k8s_nas.git \
  --path argocd \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd
```

## Application Deployment

### 1. Deploy Infrastructure

Infrastructure services are deployed via ArgoCD ApplicationSets:

```bash
# Apply ApplicationSets
kubectl apply -f argocd/applicationsets/

# Check sync status
argocd app list
```

**Infrastructure Components:**
- ArgoCD (self-managed)
- NGINX Ingress Controller
- cert-manager
- Prometheus + Grafana (monitoring)
- Istio (if enabled)

### 2. Deploy Media Services

```bash
# Media services ApplicationSet
kubectl apply -f argocd/applicationsets/media-services-appset.yaml

# Check deployment status
kubectl get pods -n media
argocd app list | grep media-services
```

**Media Services Include:**
- Starr stack (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr)
- Jellyfin (media server)
- qBittorrent (download client)
- Sabnzbd (Usenet client)
- Supporting services (VPN, Flaresolverr, Unpackerr)

### 3. Configure Services

**API Keys and Configuration:**
- Access services via `https://home.brettswift.com/<service>`
- Configure inter-service communication via service UIs
- API keys stored in service configurations

See `media-server-next-steps.md` for detailed service configuration.

## SSL Certificate Setup

### 1. Install cert-manager

```bash
# Already installed via bootstrap, but can verify:
kubectl get pods -n cert-manager
```

### 2. Set Up ClusterIssuer

**Create ClusterIssuer for Let's Encrypt:**
```bash
# See scripts/cert-manager-setup.sh for example
# Or use cert-manager blue-green test:
./scripts/cert-manager-blue-green-test.sh
```

### 3. Configure Ingress with TLS

Ingress resources automatically provision certificates via cert-manager annotations:

```yaml
annotations:
  cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

**Verify Certificates:**
```bash
kubectl get certificates -A
./scripts/monitor-certificates.sh
```

## Storage Configuration

### Production Storage Setup

**Host Path Volumes:**

Create directory structure on server:
```bash
sudo mkdir -p /mnt/data/{media,downloads,configs}
sudo chown -R 1000:1000 /mnt/data
```

**Update Deployments:**
Deployments reference hostPath volumes:
```yaml
volumes:
- name: media
  hostPath:
    path: /mnt/data/media
    type: Directory
```

**For Development:**
Uses `local-path` storage class (PVCs).

### Persistent Volume Claims

Each service has PVCs for configuration:

```bash
# Check PVCs
kubectl get pvc -n media

# PVCs use local-path storage class
kubectl get storageclass
```

## Monitoring Setup

### Prometheus Configuration

**Verify Prometheus:**
```bash
kubectl get pods -n monitoring
kubectl port-forward svc/prometheus -n monitoring 9090:9090
# Access: http://localhost:9090
```

**Prometheus Scraping:**
- Automatically discovers pods with `prometheus.io/scrape: "true"` annotation
- Configurable via `prometheus-configmap.yaml`

### Grafana Setup

**Access Grafana:**
```bash
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Access: http://localhost:3000
# Default credentials: admin/admin
```

**Configure Datasource:**
- Prometheus datasource pre-configured via ConfigMap
- Dashboards provisioned automatically

**Add Custom Dashboards:**
- Place dashboard JSON in `apps/infrastructure/monitoring/`
- Reference in `grafana-dashboard-configmap.yaml`

## Network Configuration

### Ingress Setup

**NGINX Ingress Controller:**
```bash
# Verify ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resources
kubectl get ingress -A
```

**Path-Based Routing:**
All services accessible via:
- `https://home.brettswift.com/<service>`
- Example: `https://home.brettswift.com/sonarr`

### DNS Configuration

**Point Domain to Server:**
```
A Record: home.brettswift.com → <server-ip>
```

**Verify DNS:**
```bash
dig home.brettswift.com
nslookup home.brettswift.com
```

## Service Integration

### Inter-Service Communication

Services communicate via Kubernetes Service DNS:
- Format: `<service-name>.<namespace>.svc.cluster.local:<port>`
- Example: `sonarr.media.svc.cluster.local:8989`

**Shared Configuration:**
`apps/media-services/starr/common-configmap.yaml` contains:
- Service URLs
- Common environment variables
- Hostname configuration

### API Key Configuration

**Required API Keys:**
1. Access each service UI
2. Extract API keys from service settings
3. Configure inter-service communication:
   - Sonarr → Prowlarr, qBittorrent
   - Radarr → Prowlarr, qBittorrent
   - Prowlarr → Indexers
   - Jellyseerr → Sonarr, Radarr, Jellyfin

**Configuration Process:**
See `media-server-next-steps.md` for detailed steps.

## Backup and Recovery

### Configuration Backups

**Backup ConfigMaps and Secrets:**
```bash
# Backup all ConfigMaps
kubectl get configmap -A -o yaml > configmaps-backup.yaml

# Backup Secrets (note: values base64 encoded)
kubectl get secret -A -o yaml > secrets-backup.yaml
```

**Backup PVC Data:**
```bash
# Backup service configurations
kubectl get pvc -n media -o name | xargs -I {} kubectl exec -n media {} -- tar czf - /config > {}-backup.tar.gz
```

### Disaster Recovery

**Restore Configuration:**
```bash
kubectl apply -f configmaps-backup.yaml
kubectl apply -f secrets-backup.yaml
```

**Restore Data:**
```bash
kubectl cp backup.tar.gz <pod-name>:/config -n media
kubectl exec -n media <pod-name> -- tar xzf /config/backup.tar.gz -C /config
```

## Maintenance

### Update Services

**Via GitOps:**
1. Update image tags in manifests
2. Commit and push to Git
3. ArgoCD automatically syncs

**Manual Update:**
```bash
kubectl set image deployment/sonarr sonarr=docker.io/linuxserver/sonarr:latest -n media
```

### Cluster Maintenance

**Drain Node (if multi-node):**
```bash
kubectl drain <node-name> --ignore-daemonsets
```

**Update k3s:**
```bash
# Stop k3s
sudo systemctl stop k3s

# Update k3s
curl -sfL https://get.k3s.io | sh -

# Restart k3s
sudo systemctl start k3s
```

### Log Management

**View Logs:**
```bash
# Service logs
kubectl logs -n media deployment/sonarr

# ArgoCD logs
kubectl logs -n argocd deployment/argocd-server
```

**Log Rotation:**
Configured via k3s log rotation (systemd/journald).

## Troubleshooting

### Services Not Starting

```bash
# Check pod status
kubectl get pods -n media

# Describe pod for errors
kubectl describe pod <pod-name> -n media

# Check events
kubectl get events -n media --sort-by='.lastTimestamp'
```

### ArgoCD Sync Issues

```bash
# Check Application status
argocd app list

# Force refresh
argocd app get <app-name>
argocd app sync <app-name>

# Check repository connection
argocd repo list
```

### Certificate Issues

```bash
# Check certificate status
kubectl get certificates -A

# Check certificate requests
kubectl get certificaterequests -A

# Monitor certificates
./scripts/monitor-certificates.sh
```

### Network Issues

```bash
# Check ingress
kubectl get ingress -A

# Test service internally
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://sonarr.media.svc.cluster.local:8989/ping
```

## Production Checklist

- [ ] Server prepared with required software
- [ ] k3s installed and cluster running
- [ ] Repository cloned and accessible
- [ ] Bootstrap script executed successfully
- [ ] ArgoCD accessible and configured
- [ ] Repository added to ArgoCD
- [ ] Root application synced
- [ ] Infrastructure services deployed
- [ ] Media services deployed
- [ ] SSL certificates provisioned
- [ ] DNS configured and resolving
- [ ] Storage volumes mounted
- [ ] Services accessible via ingress
- [ ] Inter-service communication configured
- [ ] API keys configured
- [ ] Monitoring operational
- [ ] Backups configured

## Next Steps

After deployment:
1. Configure service API keys (see `media-server-next-steps.md`)
2. Set up service integrations
3. Configure monitoring alerts
4. Establish backup schedule
5. Document production-specific configurations

## Additional Resources

- [Development Guide](./development-guide.md) - Local development setup
- [Architecture Documentation](./architecture.md) - System design
- [Project Overview](./project-overview.md) - High-level overview
- `BOOTSTRAP.md` - Detailed bootstrap instructions
- `MIGRATING_STARR.md` - Migration from docker-compose








