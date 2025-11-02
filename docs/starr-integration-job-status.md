# Starr Integration Job - Status and Next Steps

**Date:** 2025-01-27  
**Status:** ⚠️ **In Progress** - Structure complete, API payload debugging needed

---

## What's Working ✅

1. **Job Structure** - Kubernetes Job manifest is correct
2. **GitOps Integration** - Added to `kustomization.yaml` for ArgoCD management
3. **RBAC** - ServiceAccount, Role, and RoleBinding created
4. **Service Detection** - Successfully detects which services are ready
5. **Idempotent Checks** - Safely checks if integration already exists before configuring
6. **Error Handling** - Gracefully handles missing services

## Current Issue ⚠️

**HTTP 400 Validation Errors** - The API payload format needs adjustment:

- Sonarr/Prowlarr indexer POST: Validation errors on field structure
- Prowlarr application POST: `syncLevel` value format issue

The error messages suggest:
- Field values may need to match specific enum types
- Some required fields might be missing
- Field structure might need adjustment

---

## Debugging Next Steps

### Option 1: Capture Successful API Call

1. Configure integration manually via UI (Sonarr/Prowlarr)
2. Use browser DevTools → Network tab to capture the actual POST request
3. Compare with our script payload format
4. Adjust script to match exact format

### Option 2: Test API Schema Response

Check what the schema API actually returns:

```bash
# Sonarr indexer schema
kubectl run -it --rm test --image=alpine:3.20 --restart=Never --namespace=media -- \
  sh -c "apk add --no-cache curl jq && \
  SONARR_KEY='<key>' && \
  curl -s -L -H \"X-Api-Key: \${SONARR_KEY}\" \
  \"http://sonarr.media.svc.cluster.local:8989/api/v3/indexer/schema\" | \
  jq '.[] | select(.implementation == \"Prowlarr\") | {fields: .fields[0:5]}'"

# Prowlarr application schema  
kubectl run -it --rm test --image=alpine:3.20 --restart=Never --namespace=media -- \
  sh -c "apk add --no-cache curl jq && \
  PROWLARR_KEY='<key>' && \
  curl -s -L -H \"X-Api-Key: \${PROWLARR_KEY}\" \
  \"http://prowlarr.media.svc.cluster.local:9696/api/v1/applications/schema\" | \
  jq '.[] | select(.implementation == \"Sonarr\") | {fields: .fields[0:5]}'"
```

### Option 3: Use Manual Configuration

For now, use the manual guide: `CONFIGURE_STARR_INTEGRATIONS.md`

The Job is ready - once payload format is corrected, it will work.

---

## Current Job Configuration

**Location:** `apps/media-services/starr/starr-integration-configurator/job.yaml`

**Features:**
- ✅ Handles both Sonarr and Radarr
- ✅ Idempotent (safe to run multiple times)
- ✅ Gracefully handles partial configurations
- ✅ Detailed error logging
- ✅ GitOps-ready (included in kustomization.yaml)

**To Trigger:**
```bash
# Delete existing job to allow recreation
kubectl delete job starr-integration-configurator -n media

# Apply via GitOps (ArgoCD will sync)
kubectl apply -k apps/media-services/starr/

# Or apply directly
kubectl apply -f apps/media-services/starr/starr-integration-configurator/job.yaml
```

---

## Recommendations

1. **Short-term:** Use manual configuration guide for now (`CONFIGURE_STARR_INTEGRATIONS.md`)
2. **Debug:** Capture a working API request from browser DevTools
3. **Fix:** Adjust payload format based on actual API requirements
4. **Test:** Re-run Job once payload is corrected
5. **Long-term:** Consider using Buildarr tool (mentioned in design doc) if payload format continues to be complex

---

**Last Updated:** 2025-01-27

