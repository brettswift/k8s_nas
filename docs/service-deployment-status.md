# Service Deployment Status

**Last Updated:** 2025-01-27  
**Purpose:** Track which services are deployed, accessible, and functioning

---

## Current Deployment Status

### ✅ Deployed and Accessible Services

**Services in `apps/media-services/starr/kustomization.yaml`:**

| Service | Deployment | Service | Ingress | Status | URL |
|---------|-----------|---------|---------|--------|-----|
| **Sonarr** | ✅ Deployed | ✅ Exists | ✅ Configured | ✅ Accessible | https://home.brettswift.com/sonarr |
| **Radarr** | ✅ Deployed | ✅ Exists | ✅ Configured | ✅ Accessible | https://home.brettswift.com/radarr |
| **Sabnzbd** | ✅ Deployed | ✅ Exists | ✅ Configured | ✅ Accessible | https://home.brettswift.com/sabnzbd |

**Other Deployed Services:**

| Service | Namespace | Deployment | Ingress | Status | URL |
|---------|-----------|-----------|---------|--------|-----|
| **Jellyfin** | media | ✅ Deployed | ✅ Configured | ✅ Accessible | https://home.brettswift.com/jellyfin |
| **qBittorrent** | qbittorrent | ✅ Deployed | ✅ Configured | ✅ Accessible | https://home.brettswift.com/qbittorrent |

---

### ❌ Not Deployed (Manifests Exist but Not in Kustomization)

These services have deployment and ingress manifests in `apps/media-services/starr/` but are **NOT** included in `kustomization.yaml`:

| Service | Manifest Exists | In Kustomization | Deployed | Accessible |
|---------|----------------|-----------------|----------|------------|
| **Prowlarr** | ✅ `prowlarr-deployment.yaml` | ❌ No | ❌ No | ❌ No (404 if ingress exists) |
| **Lidarr** | ✅ `lidarr-deployment.yaml` | ❌ No | ❌ No | ❌ No |
| **Bazarr** | ✅ `bazarr-deployment.yaml` | ❌ No | ❌ No | ❌ No |
| **Jellyseerr** | ✅ `jellyseerr-deployment.yaml` | ❌ No | ❌ No | ❌ No |
| **Flaresolverr** | ✅ `flaresolverr-deployment.yaml` | ❌ No | ❌ No | ❌ No |
| **Unpackerr** | ✅ `unpackerr-deployment.yaml` | ❌ No | ❌ No | ❌ No |
| **VPN (Gluetun)** | ✅ `vpn-deployment.yaml` | ❌ No | ❌ No | ❌ No |

---

## Why Services Are Not Deployed

**Root Cause:** `apps/media-services/starr/kustomization.yaml` only includes:
```yaml
resources:
- namespace.yaml
- common-configmap.yaml
- sonarr-deployment.yaml
- sonarr-ingress.yaml
- sabnzbd-deployment.yaml
- sabnzbd-ingress.yaml
- radarr-deployment.yaml
- radarr-ingress.yaml
```

**Solution:** To deploy additional services, add them to `kustomization.yaml`:
```yaml
resources:
- namespace.yaml
- common-configmap.yaml
- sonarr-deployment.yaml
- sonarr-ingress.yaml
- sabnzbd-deployment.yaml
- sabnzbd-ingress.yaml
- radarr-deployment.yaml
- radarr-ingress.yaml
- prowlarr-deployment.yaml      # Add this
- prowlarr-ingress.yaml         # Add this
- lidarr-deployment.yaml        # Add this
- lidarr-ingress.yaml           # Add this
# ... etc
```

---

## Service Accessibility Testing

### Test Current Deployed Services

Run verification script:
```bash
./scripts/verify-service-accessibility.sh
```

**Manual Browser Testing:**
- ✅ https://home.brettswift.com/sonarr - Should load Sonarr UI
- ✅ https://home.brettswift.com/radarr - Should load Radarr UI
- ✅ https://home.brettswift.com/sabnzbd - Should load Sabnzbd UI
- ✅ https://home.brettswift.com/jellyfin - Should load Jellyfin UI
- ✅ https://home.brettswift.com/qbittorrent - Should load qBittorrent UI

**Expected:** All should return 200 OK or redirect to login/setup page (not 404)

### Test Undeployed Services

- ❌ https://home.brettswift.com/prowlarr - Will return 404 (service not deployed)
- ❌ https://home.brettswift.com/lidarr - Will return 404 (service not deployed)
- ❌ https://home.brettswift.com/bazarr - Will return 404 (service not deployed)
- ❌ https://home.brettswift.com/jellyseerr - Will return 404 (service not deployed)

---

## Story 1.1 Status

**Completed for Deployed Services:**
- ✅ Extracted API keys from Sonarr and Radarr (deployed services)
- ✅ Created `starr-secrets` Secret
- ✅ Verified deployed services are accessible

**Not Applicable (Services Not Deployed):**
- Prowlarr, Lidarr, Bazarr, Jellyseerr - Cannot extract keys (services not deployed)
- Will extract keys when services are deployed

---

## Next Steps

1. **To Deploy Missing Services:**
   - Update `apps/media-services/starr/kustomization.yaml` to include desired services
   - Commit and push - ArgoCD will deploy them
   - Extract API keys once services are running

2. **For Story 1.2+ (Prowlarr Integration):**
   - First deploy Prowlarr by adding to kustomization
   - Extract Prowlarr API key
   - Update `starr-secrets` with Prowlarr key
   - Then configure integrations

---

**Key Insight:** Story 1.1 is correctly scoped to **deployed and accessible services only**. Services that aren't deployed yet will have their keys extracted when they're deployed in future work.




