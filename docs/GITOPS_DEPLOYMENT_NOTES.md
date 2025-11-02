# GitOps Deployment Notes

**Important:** All services are deployed via **ArgoCD GitOps only**. Do NOT use `kubectl apply` directly.

---

## How It Works

1. **ArgoCD ApplicationSet** watches: `apps/media-services/starr/`
2. **Kustomization.yaml** lists which resources to deploy
3. **Commit changes** → ArgoCD automatically syncs and deploys

---

## Adding New Services (Lidarr, Bazarr, Jellyseerr)

**Status:** Added to `kustomization.yaml`, waiting for commit and ArgoCD sync.

**To Deploy:**

```bash
# 1. Commit the changes
git add apps/media-services/starr/kustomization.yaml
git commit -m "Add Lidarr, Bazarr, Jellyseerr to GitOps"
git push origin dev_starr

# 2. ArgoCD will automatically sync (or manually trigger)
# Check ArgoCD UI or:
kubectl get applications -n argocd | grep media-services

# 3. Wait for pods to be ready
kubectl get pods -n media -l 'app in (lidarr,bazarr,jellyseerr)'

# 4. Extract API keys after services are running
# View all API keys (from CONFIGURE_STARR_INTEGRATIONS.md):
for key in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BAZARR_API_KEY PROWLARR_API_KEY SABNZBD_API_KEY JELLYSEERR_API_KEY; do
  value=$(kubectl get secret starr-secrets -n media -o jsonpath="{.data.$key}" 2>/dev/null | base64 -d 2>/dev/null | grep -oE '[a-f0-9]{32}' | head -1)
  if [ -n "$value" ]; then
    echo "$key: $value"
  else
    echo "$key: (empty)"
  fi
done
```

---

## Current GitOps Configuration

**ApplicationSet:** `argocd/applicationsets/media-services-appset.yaml`
- **Watches:** `apps/media-services/starr/` path
- **Branch:** `dev_starr`
- **Namespace:** `media`
- **Sync Policy:** Automated (auto-sync enabled)

---

**Remember:** Always use GitOps - commit changes and let ArgoCD deploy!

