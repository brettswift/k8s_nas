# NGINX Ingress Controller Issue

**Date:** 2025-11-29  
**Status:** nginx-ingress installed but only processing 2 of 11 ingresses

## Problem

nginx-ingress-controller is only creating location blocks for:
- `/prometheus` (monitoring namespace)
- `/lidarr` (media namespace)

All other ingresses are being ignored, resulting in 404s.

## Current State

- **nginx-ingress-controller:** v1.14.0 (installed via Helm)
- **Installation:** `hostNetwork=true` on ports 80/443
- **IngressClass:** `nginx` (created and working)
- **Total ingresses:** 11 (all have `ingressClassName: nginx`)
- **Location blocks created:** Only 3 (prometheus, lidarr, root catch-all)

## Working Ingresses

Both working ingresses have:
- `nginx.ingress.kubernetes.io/rewrite-target: /`
- `nginx.ingress.kubernetes.io/backend-protocol: HTTP`
- `nginx.ingress.kubernetes.io/ssl-redirect: "true"`

## Non-Working Ingresses

- `media/sonarr-ingress` - has `configuration-snippet` but no `rewrite-target`
- `media/jellyfin-ingress` - has complex path regex `/jellyfin(/|$)(.*)`
- `media/radarr-ingress`
- `media/bazarr-ingress`
- `media/sabnzbd-ingress`
- `media/prowlarr-ingress`
- `monitoring/grafana-ingress`
- `qbittorrent/qbittorrent-ingress`

## Investigation

1. ✅ All services have endpoints
2. ✅ All ingresses have correct `ingressClassName: nginx`
3. ✅ Controller logs show ingresses are "Scheduled for sync"
4. ✅ nginx config syntax is valid
5. ❌ Only 3 location blocks in entire config (should be 11+)
6. ⚠️ One warning: `jellyfin-slash-redirect` has invalid `permanent-redirect` annotation

## Possible Causes

1. **Bug in nginx-ingress-controller v1.14.0** - may have issues processing certain ingress configurations
2. **Configuration limit** - nginx may have a limit on location blocks
3. **Processing order issue** - controller may stop processing after encountering certain configurations
4. **Annotation conflict** - `configuration-snippet` may be causing parsing issues

## Solution

**Root Cause:** The `nginx.ingress.kubernetes.io/configuration-snippet` annotation was causing nginx-ingress-controller to fail processing ingresses. When an ingress has this annotation, the controller appears to skip creating location blocks for it and subsequent ingresses.

**Fix:** Removed `configuration-snippet` annotations from all ingress manifests. The standard nginx annotations (`ssl-redirect`, `backend-protocol`, `rewrite-target`) work fine without the custom snippet.

**Status:** ✅ FIXED - All services now have location blocks and are accessible.

## Next Steps

1. ✅ Remove `configuration-snippet` from all ingresses (DONE)
2. Monitor for any issues with forwarded headers (nginx sets these by default)
3. Consider incremental migration to Traefik IngressRoutes if desired (ArgoCD/homepage already use Traefik)

## Git Hash for Rollback

Current commit: `5df860d6d740faec4022b96dc98f13b92b533736`  
Branch: `new-argo`

All nginx ingress configurations are in Git, so we can rollback if needed.

