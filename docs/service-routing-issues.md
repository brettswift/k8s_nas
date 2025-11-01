# Service Routing Issues - Path Base URL Conflict

**Issue Date:** 2025-01-27  
**Status:** ⚠️ **IDENTIFIED** - Requires resolution

---

## Problem Summary

Services are experiencing 307 redirect loops when accessed via ingress because of a conflict between:

1. Service configuration having `<UrlBase>/service</UrlBase>` set in config files
2. Ingress trying to strip the `/service` prefix and send `/` to backend

---

## Root Cause

**Sonarr Example:**

- Config file has: `<UrlBase>/sonarr</UrlBase>`
- Ingress rewrite: strips `/sonarr` prefix → sends `/` to backend
- Sonarr receives `/` but expects `/sonarr` → redirects to `/sonarr/`
- Redirect loop occurs: 307 → `/sonarr/` → ingress strips → `/` → Sonarr redirects → repeat

**Same issue likely affects:**

- Radarr (if config has `/radarr` base URL)
- Sabnzbd (if config has `/sabnzbd` base URL)

---

## Current Configuration

### Ingress Configuration (apps/media-services/starr/sonarr-ingress.yaml)

```yaml
annotations:
  nginx.ingress.kubernetes.io/use-regex: "true"
  nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - http:
      paths:
      - path: /sonarr(/|$)(.*)   # Captures /sonarr/anything
        pathType: Prefix
```

**Behavior:** `/sonarr/login` → rewritten to `/login` → sent to Sonarr backend

### Sonarr Config File

```xml
<UrlBase>/sonarr</UrlBase>
```

**Behavior:** Sonarr expects all requests to start with `/sonarr`, redirects if not

**Conflict:** Ingress strips prefix, Sonarr adds it back → redirect loop

---

## Solutions

### Option 1: Remove Base URL from Service Configs (Recommended)

**Approach:** Let ingress handle path routing, services serve from root

**Steps:**

1. Remove or set `<UrlBase></UrlBase>` (empty) in service config files
2. Services will serve from `/` (root)
3. Ingress strips `/service` prefix and forwards to `/`

**Pros:**

- Matches deployment comment ("Rely on ingress strip-prefix")
- Cleaner - routing handled by ingress controller
- No service restart needed (config change only)

**Cons:**

- Need to edit config files on disk
- Services might need restart to pick up change

### Option 2: Remove Ingress Path Stripping

**Approach:** Let services handle base path, ingress just routes

**Steps:**

1. Change ingress rewrite to pass through full path
2. Services handle `/service/...` paths directly

**Pros:**

- No config file changes needed

**Cons:**

- Services must be configured with base URL
- Less flexible if services need to change paths later

### Option 3: Configure Services via Environment Variable

**Approach:** Use environment variable to set/clear base URL

**Steps:**

1. Add `URL_BASE` environment variable to deployments
2. Set to empty or `/` to disable base URL
3. Services pick up from env (may override config file)

**Check:** LinuxServer.io images may support `URL_BASE` env var

---

## Recommended Fix

### Option 1: Remove Base URL from Config Files

Since the deployment comment explicitly says "Rely on ingress strip-prefix", we should:

1. Access each service directly (port-forward) or via service DNS
2. Remove or clear `<UrlBase>/sonarr</UrlBase>` from config
3. Repeat for Radarr, Sabnzbd if they have same issue
4. Test that services are accessible via ingress after change

**Commands to fix:**

```bash
# Check current config
ssh bswift@10.0.0.20 "grep UrlBase /mnt/data/configs/sonarr/config.xml"

# Edit to remove base URL (or set to empty)
ssh bswift@10.0.0.20 "sed -i 's|<UrlBase>/sonarr</UrlBase>|<UrlBase></UrlBase>|g' /mnt/data/configs/sonarr/config.xml"

# Restart pod to pick up config change
kubectl rollout restart deployment/sonarr -n media
```

---

## Verification

After fixing:

```bash
# Should return 200 or login page (not 307 loop)
curl -k -L https://home.brettswift.com/sonarr/

# Should show actual Sonarr UI content
curl -k https://home.brettswift.com/sonarr/ 2>&1 | grep -i "sonarr\|login" | head -5
```

---

## Impact on Story 1.1

**Current Status:**

- ✅ API keys extracted and stored in secret
- ✅ **FIXED:** Service routing issue resolved - Services now return HTTP 200
- ✅ Services are accessible via browser

**Updated Acceptance Criteria:**

- [ ] Services must be accessible via browser without redirect loops
- [ ] Services must return actual UI content (200 OK or login page), not redirect loops

---

**Resolution:** ✅ **FIXED** - Removed base URL from Sonarr, Radarr, and Sabnzbd config files. Updated Sabnzbd initContainer to not set url_base. Removed location header rewrite from Sabnzbd ingress. Services now return HTTP 200 via ingress without double path prefixes.
