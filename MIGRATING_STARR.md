# Migrating *arr Apps from Docker Compose to Kubernetes

## Overview
This guide outlines the migration of media management applications (*arr apps) from the existing docker-compose setup to Kubernetes using GitOps with ArgoCD.

## Migration Guidelines

### 1. Reference Docker Compose Configuration
- Use `docker-compose.yml` as the source of truth for application configuration
- Extract environment variables, volumes, health checks, and networking requirements
- Convert Traefik labels to NGINX Ingress annotations
- Maintain the same base path routing (`/sonarr`, `/radarr`, etc.)

### 2. Applications to Migrate
**Media Management:**
- Sonarr (Series management)
- Radarr (Movies management) 
- Lidarr (Music management)
- Bazarr (Subtitles management)
- Jellyseerr (Content recommendations)
- Prowlarr (Indexers management)

**Download Management:**
- qBittorrent (BitTorrent client)
- Sabnzbd (Usenet client)
- Flaresolverr (CAPTCHA solver)

**Supporting Services:**
- VPN (for qBittorrent network isolation)
- Unpackerr (Archive extraction)

### 3. Infrastructure Requirements
- **Ingress Controller**: Use NGINX (not Traefik) for routing
- **Base Paths**: All apps must serve from their respective paths (`/sonarr`, `/radarr`, etc.)
- **TLS**: Use existing `home-brettswift-com-tls` secret
- **Networking**: qBittorrent must use VPN network namespace

### 4. Deployment Strategy
- **GitOps**: All changes via `feat/starr` branch
- **ArgoCD**: Use ApplicationSets for consistent deployment
- **Replication**: Use Kubernetes ReplicaSets for high availability
- **Configuration**: Use ConfigMaps for environment variables and inter-service communication

### 5. Configuration Management
- Extract existing configs from target server where possible
- Use ConfigMaps for environment variables
- Configure inter-service API keys and URLs via environment variables
- Maintain existing data volumes and permissions

### 6. Homepage Integration
- Update existing homepage ConfigMap with new service URLs
- Add widgets for each *arr application
- Maintain existing homepage functionality

### 7. Branch Strategy
- **feat/starr**: Primary development branch for all *arr applications
- **main**: Minimal changes to add ApplicationSets that reference feat/starr
- **Deployment**: Only via GitOps, no direct kubectl apply commands

### 8. Service Dependencies
- Configure API keys between services (Sonarr ↔ Radarr ↔ Prowlarr)
- Set up proper service discovery within Kubernetes
- Maintain existing data sharing between applications

### 9. Security Considerations
- Use existing TLS certificates
- Maintain VPN isolation for qBittorrent
- Preserve existing authentication mechanisms
- Use Kubernetes secrets for sensitive data

### 10. Testing Strategy
- Verify each application is accessible via its base path
- Test inter-service communication
- Validate data persistence
- Confirm homepage integration

## Implementation Order
1. Create namespace and basic structure
2. Migrate supporting services (VPN, Unpackerr)
3. Migrate download clients (qBittorrent, Sabnzbd)
4. Migrate indexers (Prowlarr, Flaresolverr)
5. Migrate media management (Sonarr, Radarr, Lidarr, Bazarr)
6. Migrate request management (Jellyseerr)
7. Update homepage configuration
8. Create ArgoCD ApplicationSets
9. Test and validate all services

## Success Criteria
- All applications accessible via their respective base paths
- Inter-service communication working
- Data persistence maintained
- Homepage showing all services
- ArgoCD showing all applications as synced
- No broken dependencies or missing configurations
