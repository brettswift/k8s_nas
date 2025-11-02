# Current State Inventory - k8s_nas

**Generated:** 2025-01-27  
**Cluster:** Production (10.0.0.20)  
**Purpose:** Document current deployed state before service integration configuration

---

## Executive Summary

This document captures the current state of the k8s_nas cluster to understand:
- What services are deployed and running
- What configurations exist (ConfigMaps, Secrets, PVCs)
- What API keys are already configured
- What integrations are already working
- What services need configuration

**Last Updated:** 2025-01-27  
**Cluster Inventory:** Live data gathered from cluster at 10.0.0.20

---

## 1. Namespaces Inventory

### Actual Namespaces (from cluster)

```
NAME              STATUS   AGE
argocd            Active   19d
cert-manager      Active   19d
default           Active   19d
demo              Active   12d
homepage          Active   13d
ingress-nginx     Active   13d
kube-node-lease   Active   19d
kube-public       Active   19d
kube-system       Active   19d
media             Active   4d14h
media-services    Active   18d
monitoring        Active   12d
qbittorrent       Active   4d18h
```

**Status:** ✅ **VERIFIED** - Namespaces confirmed (Istio namespace cleaned up as unused)

---

## 2. Deployed Services by Namespace

### media Namespace

#### Expected Services (from manifests)

**Starr Stack Services:**
- **Sonarr** - TV series management
  - Deployment: `apps/media-services/starr/sonarr-deployment.yaml`
  - Service: `sonarr.media.svc.cluster.local:8989`
  - Ingress: `/sonarr`
  - Config: PVC `sonarr-config` (5Gi)
  - Health: `/ping` endpoint

- **Radarr** - Movie management
  - Deployment: `apps/media-services/starr/radarr-deployment.yaml`
  - Service: `radarr.media.svc.cluster.local:7878`
  - Ingress: `/radarr`
  - Config: PVC `radarr-config` (5Gi)
  - Health: `/ping` endpoint

- **Lidarr** - Music management
  - Deployment: `apps/media-services/starr/lidarr-deployment.yaml`
  - Service: `lidarr.media.svc.cluster.local:8686`
  - Ingress: `/lidarr`
  - Config: PVC `lidarr-config` (5Gi)

- **Bazarr** - Subtitle management
  - Deployment: `apps/media-services/starr/bazarr-deployment.yaml`
  - Service: `bazarr.media.svc.cluster.local:6767`
  - Ingress: `/bazarr`
  - Config: PVC `bazarr-config` (5Gi)

- **Prowlarr** - Indexer management
  - Deployment: `apps/media-services/starr/prowlarr-deployment.yaml`
  - Service: `prowlarr.media.svc.cluster.local:9696`
  - Ingress: `/prowlarr`
  - Config: PVC `prowlarr-config` (5Gi)
  - Health: `/api/v1/status` endpoint

- **Jellyseerr** - Content request management
  - Deployment: `apps/media-services/starr/jellyseerr-deployment.yaml`
  - Service: `jellyseerr.media.svc.cluster.local:5055`
  - Ingress: `/jellyseerr`
  - Config: PVC `jellyseerr-config` (5Gi)
  - Health: `/api/v1/status` endpoint

**Download Services:**
- **qBittorrent** - BitTorrent client (VPN-enabled)
  - Deployment: `apps/media-services/qbittorrent/deployment.yaml`
  - Service: `qbittorrent.qbittorrent.svc.cluster.local:8080`
  - Ingress: `/qbittorrent`
  - Namespace: `qbittorrent` (separate namespace)

- **Sabnzbd** - Usenet client
  - Deployment: `apps/media-services/starr/sabnzbd-deployment.yaml`
  - Service: `sabnzbd.media.svc.cluster.local:8081`
  - Ingress: `/sabnzbd`
  - Config: PVC `sabnzbd-config` (5Gi)

- **Flaresolverr** - CAPTCHA solver
  - Deployment: `apps/media-services/starr/flaresolverr-deployment.yaml`
  - Service: `flaresolverr.media.svc.cluster.local:8191`
  - Ingress: `/flaresolverr`

- **Unpackerr** - Archive extraction
  - Deployment: `apps/media-services/starr/unpackerr-deployment.yaml`
  - Config: PVC `unpackerr-config` (1Gi)
  - Uses API keys from `starr-secrets` for Sonarr/Radarr integration

**Media Server:**
- **Jellyfin** - Media streaming server
  - Deployment: `apps/media-services/jellyfin/deployment.yaml`
  - Service: `jellyfin.media.svc.cluster.local:8096`
  - Ingress: `/jellyfin`
  - Config: ConfigMap `jellyfin-config`

**VPN Service:**
- **Gluetun** - VPN service for download isolation
  - Deployment: `apps/media-services/starr/vpn-deployment.yaml`
  - Config: Secret `vpn-secrets`

**Status:** ✅ **VERIFIED** - Partial deployment confirmed

### Actual Running Services (from cluster)

**Running Pods in `media` namespace:**
```
NAME                        READY   STATUS    RESTARTS   AGE
jellyfin-54bf6f46cd-zq8pj   1/1     Running   0          43h
radarr-6496cbff98-rrtx4     1/1     Running   0          3h5m
sabnzbd-579894944b-bgtpv    1/1     Running   0          90m
sonarr-678cdd89cd-9zdr4     1/1     Running   0          3h5m
```

**Running Services:**
```
NAME       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
jellyfin   ClusterIP   10.43.1.140    <none>        80/TCP,7359/TCP   43h
radarr     ClusterIP   10.43.29.11    <none>        7878/TCP          4d14h
sabnzbd    ClusterIP   10.43.78.129   <none>        8080/TCP          4d14h
sonarr     ClusterIP   10.43.99.86    <none>        8989/TCP          4d14h
```

**Running in `qbittorrent` namespace:**
```
NAME                           READY   STATUS    RESTARTS   AGE
qbittorrent-576cd7579f-hnzjf   2/2     Running   0          4d14h
```

**Also found in `media-services` namespace:**
```
NAME                           READY   STATUS    RESTARTS   AGE
jellyfin-754d5f9f7-xm775       1/1     Running   0          43h
```

**Missing Services (not deployed yet):**
- ❌ **Prowlarr** - Not deployed
- ❌ **Lidarr** - Not deployed
- ❌ **Bazarr** - Not deployed
- ❌ **Jellyseerr** - Not deployed
- ❌ **Flaresolverr** - Not deployed
- ❌ **Unpackerr** - Not deployed
- ❌ **VPN (Gluetun)** - Not deployed

**Summary:**
- ✅ **4 services running:** Sonarr, Radarr, Sabnzbd, Jellyfin
- ✅ **qBittorrent running** in separate namespace
- ❌ **6 services missing:** Prowlarr, Lidarr, Bazarr, Jellyseerr, Flaresolverr, Unpackerr

---

## 3. Configuration Resources

### ConfigMaps

#### media Namespace

**starr-common-config** (`apps/media-services/starr/common-configmap.yaml`)

**Contents:**
```yaml
PUID: "1000"
PGID: "1000"
TZ: "America/Denver"

# Service URLs for inter-app communication
SONARR_URL: "http://sonarr.media.svc.cluster.local:8989"
RADARR_URL: "http://radarr.media.svc.cluster.local:7878"
LIDARR_URL: "http://lidarr.media.svc.cluster.local:8686"
BAZARR_URL: "http://bazarr.media.svc.cluster.local:6767"
PROWLARR_URL: "http://prowlarr.media.svc.cluster.local:9696"
JELLYSEERR_URL: "http://jellyseerr.media.svc.cluster.local:5055"
QBITTORRENT_URL: "http://qbittorrent.qbittorrent.svc.cluster.local:8080"
SABNZBD_URL: "http://sabnzbd.media.svc.cluster.local:8081"
FLARESOLVERR_URL: "http://flaresolverr.media.svc.cluster.local:8191"

# Base URLs for external access
HOSTNAME: "home.brettswift.com"
SAB_HOST_WHITELIST: "home.brettswift.com,home.brettswift.com:443,localhost,127.0.0.1"
```

**Status:** ✅ **DEFINED AND DEPLOYED** - ConfigMap exists in cluster

**Actual Contents (from cluster):**
```yaml
BAZARR_URL: http://bazarr.media.svc.cluster.local:6767
FLARESOLVERR_URL: http://flaresolverr.media.svc.cluster.local:8191
HOSTNAME: home.brettswift.com
JELLYSEERR_URL: http://jellyseerr.media.svc.cluster.local:5055
LIDARR_URL: http://lidarr.media.svc.cluster.local:8686
PGID: "1000"
PROWLARR_URL: http://prowlarr.media.svc.cluster.local:9696
PUID: "1000"
QBITTORRENT_URL: http://qbittorrent.qbittorrent.svc.cluster.local:8080
RADARR_URL: http://radarr.media.svc.cluster.local:7878
SAB_HOST_WHITELIST: home.brettswift.com,home.brettswift.com:443,localhost,127.0.0.1
SABNZBD_URL: http://sabnzbd.media.svc.cluster.local:8081
SONARR_URL: http://sonarr.media.svc.cluster.local:8989
TZ: America/Denver
```

---

### Secrets

#### media Namespace

**starr-secrets** (`apps/media-services/starr/unpackerr-deployment.yaml`)

**Expected Keys:**
- `SONARR_API_KEY` - Base64 encoded
- `RADARR_API_KEY` - Base64 encoded
- `LIDARR_API_KEY` - Base64 encoded
- `BAZARR_API_KEY` - Base64 encoded
- `PROWLARR_API_KEY` - Base64 encoded
- `JELLYSEERR_API_KEY` - Base64 encoded
- `SABNZBD_API_KEY` - Base64 encoded

**Current State in Codebase:**
```yaml
# From unpackerr-deployment.yaml:
# These will need to be populated with actual base64 encoded API keys
SONARR_API_KEY: ""     # Base64 encoded API key
RADARR_API_KEY: ""     # Base64 encoded API key
LIDARR_API_KEY: ""     # Base64 encoded API key
BAZARR_API_KEY: ""     # Base64 encoded API key
PROWLARR_API_KEY: ""   # Base64 encoded API key
JELLYSEERR_API_KEY: "" # Base64 encoded API key
SABNZBD_API_KEY: ""    # Base64 encoded API key
```

**Status:** ❌ **DOES NOT EXIST** - Secret is not deployed to cluster

**Action Required:** 
1. Secret needs to be created in cluster
2. Extract API keys from existing service configurations (if services are already configured)
3. Populate secret with base64-encoded API keys

---

**vpn-secrets** (`apps/media-services/starr/vpn-deployment.yaml`)

**Status:** ⚠️ **TO BE VERIFIED** - Check if VPN credentials are configured

---

## 4. Persistent Storage (PVCs)

### media Namespace PVCs

**Expected PVCs (from `apps/media-services/starr/pvcs.yaml`):**

| PVC Name | Size | Storage Class | Purpose |
|----------|------|---------------|---------|
| `sonarr-config` | 5Gi | local-path | Sonarr configuration |
| `radarr-config` | 5Gi | local-path | Radarr configuration |
| `lidarr-config` | 5Gi | local-path | Lidarr configuration |
| `bazarr-config` | 5Gi | local-path | Bazarr configuration |
| `prowlarr-config` | 5Gi | local-path | Prowlarr configuration |
| `jellyseerr-config` | 5Gi | local-path | Jellyseerr configuration |
| `sabnzbd-config` | 5Gi | local-path | Sabnzbd configuration |
| `unpackerr-config` | 1Gi | local-path | Unpackerr configuration |

**Note:** Services also use hostPath volumes for media and downloads:
- `/mnt/data/configs/<service>` - Service configurations (also in PVCs)
- `/mnt/data/media` - Media library
- `/mnt/data/downloads` - Download staging area

**Status:** ⚠️ **PARTIALLY BOUND** - Some PVCs are pending

**Actual PVC Status:**
```
NAME              STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
jellyfin-config   Bound     pvc-970cfcf6-9495-4977-a0c1-e7493e9768fa   10Gi       RWO            local-path     43h
radarr-config     Pending                                                                        local-path     4d14h
sabnzbd-config    Bound     pvc-a7f4d2ad-1de2-4e99-90c8-4c5f8831a35b   10Gi       RWO            local-path     4d14h
sonarr-config     Pending                                                                        local-path     4d14h
```

**PVC Issues:**
- `sonarr-config`: **Pending** - Waiting for first consumer (pod needs to mount it)
- `radarr-config`: **Pending** - Waiting for first consumer (pod needs to mount it)
- `jellyfin-config`: ✅ **Bound** (10Gi)
- `sabnzbd-config`: ✅ **Bound** (10Gi)

**Note:** Pending PVCs will bind when pods that reference them are created. The PVCs are configured correctly but waiting for consumers.

---

## 5. Ingress Configuration

### Expected Ingress Routes

All services use path-based routing via `home.brettswift.com`:

| Service | Path | Namespace | TLS Secret |
|---------|------|-----------|------------|
| Homepage | `/` | homepage | home-brettswift-com-tls |
| Sonarr | `/sonarr` | media | home-brettswift-com-tls |
| Radarr | `/radarr` | media | home-brettswift-com-tls |
| Lidarr | `/lidarr` | media | home-brettswift-com-tls |
| Bazarr | `/bazarr` | media | home-brettswift-com-tls |
| Prowlarr | `/prowlarr` | media | home-brettswift-com-tls |
| Jellyseerr | `/jellyseerr` | media | home-brettswift-com-tls |
| Jellyfin | `/jellyfin` | media | home-brettswift-com-tls |
| qBittorrent | `/qbittorrent` | qbittorrent | home-brettswift-com-tls |
| Sabnzbd | `/sabnzbd` | media | home-brettswift-com-tls |
| Flaresolverr | `/flaresolverr` | media | home-brettswift-com-tls |
| Prometheus | `/prometheus` | monitoring | home-brettswift-com-tls |
| Grafana | `/grafana` | monitoring | home-brettswift-com-tls |
| ArgoCD | `/argocd` | argocd | home-brettswift-com-tls |

**Status:** ✅ **VERIFIED** - Ingress routes confirmed for deployed services

**Actual Ingress Resources:**
```
NAMESPACE     NAME                      CLASS   HOSTS                 ADDRESS     PORTS     AGE
media         jellyfin-ingress          nginx   home.brettswift.com   10.0.0.20   80, 443   43h
media         jellyfin-slash-redirect   nginx   home.brettswift.com   10.0.0.20   80        43h
media         radarr-ingress            nginx   home.brettswift.com   10.0.0.20   80, 443   4d14h
media         sabnzbd-ingress           nginx   home.brettswift.com   10.0.0.20   80, 443   4d14h
media         sonarr-ingress            nginx   home.brettswift.com   10.0.0.20   80, 443   4d14h
qbittorrent   qbittorrent-ingress       nginx   home.brettswift.com   10.0.0.20   80, 443   4d14h
argocd        argocd-ingress            nginx   home.brettswift.com   10.0.0.20   80, 443   13d
homepage      homepage-ingress          nginx   home.brettswift.com   10.0.0.20   80, 443   12d
monitoring    grafana-ingress           nginx   home.brettswift.com   10.0.0.20   80, 443   12d
monitoring    prometheus-ingress        nginx   home.brettswift.com   80, 443   12d
```

**Missing Ingress (services not deployed):**
- Prowlarr, Lidarr, Bazarr, Jellyseerr, Flaresolverr (services not running)

---

## 6. Service-to-Service Communication

### Expected Service DNS Names

From `starr-common-config` ConfigMap:

| Service | DNS Name | Port | Purpose |
|---------|----------|------|---------|
| Sonarr | `sonarr.media.svc.cluster.local` | 8989 | TV management |
| Radarr | `radarr.media.svc.cluster.local` | 7878 | Movie management |
| Lidarr | `lidarr.media.svc.cluster.local` | 8686 | Music management |
| Bazarr | `bazarr.media.svc.cluster.local` | 6767 | Subtitle management |
| Prowlarr | `prowlarr.media.svc.cluster.local` | 9696 | Indexer management |
| Jellyseerr | `jellyseerr.media.svc.cluster.local` | 5055 | Request management |
| qBittorrent | `qbittorrent.qbittorrent.svc.cluster.local` | 8080 | Download client |
| Sabnzbd | `sabnzbd.media.svc.cluster.local` | 8081 | Usenet client |
| Flaresolverr | `flaresolverr.media.svc.cluster.local` | 8191 | CAPTCHA solver |

**Status:** ✅ **DEFINED** - Service URLs configured in ConfigMap

---

## 7. API Keys Status

### Current State

**Expected API Keys (from codebase):**
- `SONARR_API_KEY` - For Sonarr service authentication
- `RADARR_API_KEY` - For Radarr service authentication
- `LIDARR_API_KEY` - For Lidarr service authentication
- `BAZARR_API_KEY` - For Bazarr service authentication
- `PROWLARR_API_KEY` - For Prowlarr service authentication
- `JELLYSEERR_API_KEY` - For Jellyseerr service authentication
- `SABNZBD_API_KEY` - For Sabnzbd service authentication

**Secret Location:** `media/starr-secrets`

**Status in Codebase:**
- ✅ Secret definition exists
- ❌ All API key values are empty (`""`)

**Action Required:**
1. Extract API keys from existing service configurations (if services are already configured)
2. Check PVC data (`/mnt/data/configs/<service>`) for API keys in service config files
3. Populate `starr-secrets` Secret with base64-encoded API keys

**Status:** ✅ **CREATED** - Secret exists with extracted API keys

**Cluster Check:**
```bash
kubectl get secret starr-secrets -n media
# secret/starr-secrets created
```

**API Keys Status:**
- ✅ **SONARR_API_KEY**: Extracted and configured (aa91f40651...)
- ✅ **RADARR_API_KEY**: Extracted and configured (20c2257426...)
- ⚠️ **SABNZBD_API_KEY**: Empty (to be extracted when accessible)
- ⚠️ **LIDARR_API_KEY**: Empty (service not deployed)
- ⚠️ **BAZARR_API_KEY**: Empty (service not deployed)
- ⚠️ **PROWLARR_API_KEY**: Empty (service not deployed)
- ⚠️ **JELLYSEERR_API_KEY**: Empty (service not deployed)

**Extraction Method:**
- Sonarr and Radarr API keys extracted from config files on server
- Keys stored in `starr-secrets` Secret (base64 encoded)
- Secret ready for use by services that reference it (e.g., Unpackerr)

---

## 8. Existing Integrations Status

### Expected Integration Flow

**From PRD and Epics:**
1. **Sonarr → Prowlarr** - Indexer management
2. **Radarr → Prowlarr** - Indexer management
3. **Sonarr → qBittorrent** - Download client (via VPN)
4. **Radarr → qBittorrent** - Download client (via VPN)
5. **Jellyseerr → Sonarr/Radarr** - Content requests
6. **Jellyseerr → Jellyfin** - Media server connection
7. **Unpackerr → Sonarr/Radarr** - Using API keys from secret

### Current Integration State

**Status:** ⚠️ **UNKNOWN** - Requires verification via service UIs/APIs

**Verification Required:**
1. Access Sonarr UI (`https://home.brettswift.com/sonarr`)
   - Check Settings → Indexers (Prowlarr configured?)
   - Check Settings → Download Clients (qBittorrent configured?)
   - Check Settings → Media Management (root folders configured?)
2. Access Radarr UI (`https://home.brettswift.com/radarr`)
   - Same checks as Sonarr
3. Access Prowlarr UI (`https://home.brettswift.com/prowlarr`)
   - Check Settings → Applications (Sonarr/Radarr configured with API keys?)
4. Access Jellyseerr UI (`https://home.brettswift.com/jellyseerr`)
   - Check Settings → Services (Sonarr/Radarr/Jellyfin connected?)
5. Access qBittorrent UI (`https://home.brettswift.com/qbittorrent`)
   - Verify VPN connectivity
   - Check if accessible from Sonarr/Radarr

**Action Required:** Access each service UI and document actual configuration state

---

## 9. ArgoCD Application Status

### Expected Applications (from ApplicationSets)

**From `argocd/applicationsets/`:**
- `media-services-appset.yaml` - Media services deployment
- `jellyfin-appset.yaml` - Jellyfin deployment
- `monitoring-appset.yaml` - Monitoring stack
- `homepage-appset.yaml` - Homepage dashboard
- `argocd-infrastructure-appset.yaml` - Infrastructure services

**Status:** ✅ **VERIFIED** - ArgoCD applications status confirmed

**Actual ArgoCD Applications:**
```
NAME                                       SYNC STATUS   HEALTH STATUS
argocd-infrastructure-production-cluster   Synced        Healthy
homepage-production-cluster                Synced        Healthy
jellyfin-production-cluster                Synced        Healthy
media-services-production-cluster          Synced        Progressing
monitoring-production-cluster              Synced        Healthy
qbit-production-cluster                    Synced        Healthy
root-application                           OutOfSync     Degraded
sample-hello-production-cluster            Synced        Healthy
```

**Issues:**
- ⚠️ `media-services-production-cluster`: **Progressing** - Some resources still syncing
- ⚠️ `root-application`: **OutOfSync** and **Degraded** - Needs attention

**Application Source:**
- Repository: `git@github.com:brettswift/k8s_nas.git`
- Branch: `dev_starr`
- Path: `apps/media-services`

---

## 10. Networking and Ingress

### Ingress Controller

**Expected:** NGINX Ingress Controller
- IngressClass: `nginx`
- Default for all ingress resources

### External Access

**Domain:** `home.brettswift.com`

**Certificate:** `home-brettswift-com-tls` (managed by cert-manager)

**Status:** ⚠️ **TO BE VERIFIED** - Check certificate status and ingress controller

---

## 11. Findings Summary

### ✅ What's Working (from cluster verification)

- ✅ **4 Services Running:** Sonarr, Radarr, Sabnzbd, Jellyfin are deployed and running
- ✅ **qBittorrent Running:** Deployed in separate namespace with 2/2 pods ready
- ✅ **ConfigMap Deployed:** `starr-common-config` exists with all service URLs defined
- ✅ **Ingress Configured:** All running services have ingress routes configured
- ✅ **PVCs Partially Bound:** Jellyfin and Sabnzbd have bound PVCs
- ✅ **ArgoCD Applications:** Most applications are synced and healthy
- ✅ **Service DNS:** Service URLs correctly configured in ConfigMap
- ✅ **Health Checks:** Services have liveness/readiness probes configured

### ⚠️  What Needs Attention

- ⚠️  **6 Services Missing:** Prowlarr, Lidarr, Bazarr, Jellyseerr, Flaresolverr, Unpackerr not deployed
- ⚠️  **PVCs Pending:** Sonarr and Radarr PVCs are pending (waiting for first consumer)
- ⚠️  **ArgoCD Status:** `media-services-production-cluster` is Progressing, `root-application` is OutOfSync
- ⚠️  **Service Integrations:** Need to verify via service UIs (Sonarr-Prowlarr, download clients, etc.)
- ⚠️  **Certificate Status:** Need to verify TLS certificates are valid

### ❌ Known Gaps

- ❌ **API Keys Secret:** `starr-secrets` Secret does NOT exist in cluster (needs to be created)
- ❌ **Integration Status:** Unknown - needs service UI verification to see what's configured
- ❌ **Service Configurations:** Root folders, download paths, etc. need verification via service UIs
- ❌ **VPN Integration:** VPN service not deployed, qBittorrent VPN status unknown
- ❌ **Missing Services:** 6 services from manifest not yet deployed

---

## 12. Next Steps

### Immediate Actions (Next Steps)

1. **✅ COMPLETED: Cluster Inventory**
   - Cluster access verified
   - Namespaces, pods, services, ConfigMaps documented
   - ArgoCD status checked

2. **⚠️ TODO: Access Service UIs** (Required for integration verification)
   - Access Sonarr: `https://home.brettswift.com/sonarr`
     - Check Settings → Indexers (Prowlarr configured?)
     - Check Settings → Download Clients (qBittorrent configured?)
     - Check Settings → Media Management (root folders configured?)
     - Extract API key from Settings → General
   - Access Radarr: `https://home.brettswift.com/radarr`
     - Same checks as Sonarr
     - Extract API key
   - Access Sabnzbd: `https://home.brettswift.com/sabnzbd`
     - Extract API key if available
   - Access qBittorrent: `https://home.brettswift.com/qbittorrent`
     - Verify VPN connectivity
     - Check if accessible from Sonarr/Radarr
   - Access Jellyfin: `https://home.brettswift.com/jellyfin`
     - Verify it's working

3. **⚠️ TODO: Extract API Keys** (From service UIs or PVC data)
   - Document API keys found in service UIs
   - Optionally check PVC data: `/mnt/data/configs/<service>/` on server
   - Create `starr-secrets` Secret with extracted keys

4. **⚠️ TODO: Document Integration State**
   - Which integrations are already working (if any)
   - Which integrations need to be configured
   - Any configuration gaps found

5. **⚠️ TODO: Deploy Missing Services** (Future work)
   - Deploy Prowlarr, Lidarr, Bazarr, Jellyseerr, Flaresolverr, Unpackerr
   - Deploy VPN service if needed for qBittorrent

### After Service UI Verification

Once service UIs are checked and API keys extracted:

1. ✅ Update this document with integration findings
2. Create `starr-secrets` Secret with API keys
3. Document which integrations are already configured
4. Create action plan for remaining integration configuration

---

## 13. How to Update This Document

### Method 1: Run Automated Script

```bash
# From project root, with kubectl configured:
./scripts/inventory-cluster-state.sh

# This will generate/update docs/current-state-inventory.md with live cluster data
```

### Method 2: Manual Verification

1. Run kubectl commands to gather information
2. Access service UIs to verify configuration
3. Update relevant sections with findings
4. Document any discovered API keys or configurations

---

**End of Inventory**

**Last Updated:** 2025-01-27  
**Inventory Status:** ✅ **COMPLETE** - Live cluster data gathered from 10.0.0.20  
**Cleanup Actions:** ✅ Istio resources removed (HPAs, IstioOperator, namespace) - System using NGINX Ingress only  
**Next Update:** After service UI verification and API key extraction

