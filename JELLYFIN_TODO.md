# Jellyfin Deployment TODO

## CRITICAL REQUIREMENTS (MUST NOT BREAK):
1. ✅ https://home.brettswift.com shows the homepage
2. ✅ https://home.brettswift.com/argocd works and shows ArgoCD
3. 🔄 All unknown states in ArgoCD must be resolved

## JELLYFIN REQUIREMENTS:
- Must be accessible at https://home.brettswift.com/jellyfin (NOT IP:port)
- Must be deployed via GitOps (push to feat/jellyfin branch)
- Must pull media from /mnt directory on server

## CURRENT STATUS:
- ❌ Jellyfin is NOT working at https://home.brettswift.com/jellyfin
- ❌ I incorrectly changed Traefik to NodePort (WRONG APPROACH)
- ❌ I need to fix the LoadBalancer configuration properly

## NEXT STEPS:
1. Check if homepage and ArgoCD are still working at standard URLs
2. Fix Traefik LoadBalancer to properly expose ports 80/443 on host
3. Ensure Jellyfin works at https://home.brettswift.com/jellyfin
4. Verify all ArgoCD applications are synced
