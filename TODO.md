# TODO - k8s_nas Project

## Next Steps (Immediate Priority)
- [ ] Set up cert-manager for automatic certificate renewal
- [ ] Migrate more services from docker-compose-nas2 using Traefik patterns
- [ ] Add monitoring and alerting for certificate expiry
- [ ] Scale up with more media services (Jellyfin, Sonarr, etc.)
- [ ] Test ArgoCD login with new password (admin/8480)

## Infrastructure & Deployment
- [ ] Use ReplicaSets for better pod management
- [ ] Add Lens cluster dashboard for Kubernetes management
- [ ] Add lightweight Grafana dashboard (alternative to Lens)
- [ ] Implement proper RBAC for cross-namespace service discovery
- [ ] Add monitoring and alerting stack (Prometheus + Grafana)
- [ ] Set up backup strategy for persistent volumes
- [ ] Implement proper secrets management (external-secrets-operator)

## Media Services
- [ ] Deploy Jellyfin media server
- [ ] Deploy Jellyseerr for media requests
- [ ] Deploy Sonarr for TV show management
- [ ] Deploy Radarr for movie management
- [ ] Deploy Bazarr for subtitle management
- [ ] Deploy qBittorrent for downloads
- [ ] Deploy Prowlarr for indexer management

## Home Lab Services
- [ ] Deploy Home Assistant
- [ ] Deploy Pi-hole or AdGuard Home for DNS filtering
- [ ] Deploy Portainer for container management
- [ ] Deploy Watchtower for automatic updates
- [ ] Deploy Uptime Kuma for monitoring
- [ ] Deploy Vaultwarden for password management

## Security & Networking
- [ ] Implement network policies for service isolation
- [x] Set up cert-manager for automatic SSL certificates
- [x] Configure proper ingress with TLS termination
- [ ] Implement pod security standards
- [ ] Set up Falco for runtime security monitoring

## Development & CI/CD
- [ ] Set up GitHub Actions for automated testing
- [x] Implement proper GitOps workflow with ArgoCD
- [ ] Add automated security scanning
- [ ] Set up development/staging environments
- [ ] Implement proper versioning strategy

## Documentation & Maintenance
- [ ] Create comprehensive setup documentation
- [ ] Document troubleshooting procedures
- [ ] Set up automated backups
- [ ] Create disaster recovery procedures
- [ ] Document service dependencies and requirements

## Performance & Optimization
- [ ] Implement resource quotas and limits
- [ ] Set up horizontal pod autoscaling
- [ ] Optimize container images for size and security
- [ ] Implement proper logging aggregation
- [ ] Set up performance monitoring and profiling

## User Experience
- [ ] Create custom Homepage themes
- [ ] Implement single sign-on (SSO) where possible
- [ ] Set up proper service discovery and health checks
- [ ] Create user-friendly service documentation
- [ ] Implement proper error handling and user feedback
