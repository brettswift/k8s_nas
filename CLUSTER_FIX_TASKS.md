# Cluster Fix Tasks - Complete System Restoration

**Started:** 2025-11-24  
**Goal:** Get entire cluster up, synced, and working with proper certificates and dev_starr branch configuration

## Task Status Legend
- ⬜ Not Started
- 🔄 In Progress  
- ✅ Completed
- ❌ Blocked/Failed

---

## Phase 1: Certificate Management

### 1.1 Check Existing Certificate Status
- ⬜ Verify what certificates exist in cluster
- ⬜ Check if old working certificate can be found/restored
- ⬜ Determine if DNS-01 challenge setup is needed

### 1.2 Set Up Proper Certificate (DNS-01 Challenge)
- ⬜ Verify AWS credentials are working
- ⬜ Check if ClusterIssuer for DNS-01 exists
- ⬜ Create/update Route53 credentials secret
- ⬜ Create/update Certificate resource for DNS-01
- ⬜ Verify certificate is issued successfully
- ⬜ Sync certificate secret to all namespaces that need it

### 1.3 Remove Self-Signed Certificate
- ⬜ Remove temporary self-signed certificates
- ⬜ Ensure all ingresses use proper certificate

---

## Phase 2: Branch Configuration (dev_starr)

### 2.1 Audit Current Branch Configuration
- ⬜ List all ArgoCD applications and their target branches
- ⬜ Identify which should be on dev_starr vs main
- ⬜ Document current state

### 2.2 Update Applications to dev_starr
- ⬜ Update argocd-infrastructure to dev_starr (if needed)
- ⬜ Update homepage to dev_starr (if needed)
- ⬜ Update infrastructure to dev_starr (if needed)
- ⬜ Update monitoring to dev_starr (if needed)
- ⬜ Update qbit to dev_starr (if needed)
- ⬜ Update sample-hello to dev_starr (if needed)
- ⬜ Verify jellyfin is on dev_starr
- ⬜ Verify media-services is on dev_starr

### 2.3 Verify Branch Exists
- ⬜ Check if dev_starr branch exists in git
- ⬜ Ensure all required manifests are on dev_starr branch
- ⬜ Push any missing changes to dev_starr

---

## Phase 3: Application Sync Status

### 3.1 Check All Application Status
- ⬜ List all ArgoCD applications
- ⬜ Identify OutOfSync applications
- ⬜ Identify Missing applications
- ⬜ Document sync issues

### 3.2 Fix OutOfSync Applications
- ⬜ Fix argocd-infrastructure sync issues
- ⬜ Fix infrastructure sync issues
- ⬜ Fix jellyfin sync issues
- ⬜ Fix media-services sync issues
- ⬜ Fix qbit sync issues
- ⬜ Fix monitoring sync issues
- ⬜ Fix any other OutOfSync applications

### 3.3 Fix Missing Applications
- ⬜ Create/fix missing infrastructure application
- ⬜ Create/fix missing jellyfin application
- ⬜ Create/fix missing media-services application
- ⬜ Create/fix missing qbit application
- ⬜ Fix any other missing applications

---

## Phase 4: Service Deployment Verification

### 4.1 Verify All Namespaces Exist
- ⬜ Verify media namespace exists
- ⬜ Verify qbittorrent namespace exists
- ⬜ Verify monitoring namespace exists
- ⬜ Verify all required namespaces exist

### 4.2 Verify Jellyfin Deployment
- ⬜ Verify Jellyfin pod is running
- ⬜ Verify Jellyfin service is ClusterIP
- ⬜ Verify Jellyfin ingress is configured
- ⬜ Verify Jellyfin is accessible via HTTPS
- ⬜ Test Jellyfin web interface

### 4.3 Verify Media Services (STARR)
- ⬜ Verify Sonarr is deployed and running
- ⬜ Verify Radarr is deployed and running
- ⬜ Verify Prowlarr is deployed and running
- ⬜ Verify Lidarr is deployed and running
- ⬜ Verify Bazarr is deployed and running
- ⬜ Verify Jellyseerr is deployed and running
- ⬜ Verify Sabnzbd is deployed and running
- ⬜ Verify Flaresolverr is deployed and running
- ⬜ Verify Unpackerr is deployed and running
- ⬜ Verify VPN/Gluetun is deployed and running

### 4.4 Verify Other Services
- ⬜ Verify qBittorrent is deployed and running
- ⬜ Verify Homepage is deployed and running
- ⬜ Verify ArgoCD is accessible
- ⬜ Verify monitoring services are running

---

## Phase 5: Ingress and Routing

### 5.1 Verify All Ingresses
- ⬜ List all ingresses in cluster
- ⬜ Verify all ingresses have TLS configured
- ⬜ Verify all ingresses use correct certificate secret
- ⬜ Test accessibility of all services via HTTPS

### 5.2 Fix Ingress Issues
- ⬜ Fix any ingresses missing TLS
- ⬜ Fix any ingresses with wrong certificate
- ⬜ Fix any routing issues

---

## Phase 6: Storage and PVCs

### 6.1 Verify All PVCs
- ⬜ List all PVCs in cluster
- ⬜ Verify all PVCs are bound
- ⬜ Fix any pending PVCs

### 6.2 Fix Storage Issues
- ⬜ Fix any PVCs with wrong storage class
- ⬜ Fix any PVCs referencing non-existent PVs
- ⬜ Ensure all services have required storage

---

## Phase 7: Final Verification

### 7.1 Cluster Health Check
- ⬜ All pods running
- ⬜ All services accessible
- ⬜ All ingresses working
- ⬜ All certificates valid
- ⬜ All applications synced

### 7.2 Documentation Update
- ⬜ Update any relevant documentation
- ⬜ Document any changes made
- ⬜ Update status files

---

## Notes
- AWS credentials obtained via: `assume brettswift-mgmt`
- Target branch for most services: `dev_starr`
- Certificate method: DNS-01 challenge (HTTP-01 won't work on private network)
- All changes should go through GitOps (ArgoCD)

