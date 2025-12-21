#!/bin/bash
# Cluster State Inventory Script
# Gathers information about deployed services, configurations, and current state
# Run from project root with kubectl access configured

set -e

OUTPUT_DIR="${1:-docs}"
INVENTORY_FILE="${OUTPUT_DIR}/current-state-inventory.md"

echo "🔍 Gathering cluster state inventory..."
echo "Output will be written to: ${INVENTORY_FILE}"

# Create temp file for gathering data
TEMP_FILE=$(mktemp)
trap "rm -f ${TEMP_FILE}" EXIT

cat > "${INVENTORY_FILE}" << 'EOF'
# Current State Inventory - k8s_nas

**Generated:** $(date)  
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

---

## 1. Namespaces Inventory

EOF

echo "### Gathering namespaces..."
kubectl get namespaces -o wide >> "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query namespaces. Check kubectl access."

cat >> "${INVENTORY_FILE}" << 'EOF'

### Namespaces

```
EOF
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

---

## 2. Deployed Services by Namespace

EOF

echo "### Gathering pods and services..."

# Media namespace
cat >> "${INVENTORY_FILE}" << 'EOF'

### media Namespace

#### Pods

```
EOF
kubectl get pods -n media -o wide > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query pods in media namespace."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

#### Services

```
EOF
kubectl get services -n media > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query services in media namespace."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

EOF

# Infrastructure namespaces
for NS in argocd monitoring homepage infrastructure; do
  if kubectl get namespace "${NS}" >/dev/null 2>&1; then
    cat >> "${INVENTORY_FILE}" << EOF

### ${NS} Namespace

#### Pods

\`\`\`
EOF
    kubectl get pods -n "${NS}" -o wide > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query pods in ${NS} namespace."
    cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
    cat >> "${INVENTORY_FILE}" << 'EOF'
```

#### Services

```
EOF
    kubectl get services -n "${NS}" > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query services in ${NS} namespace."
    cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
    cat >> "${INVENTORY_FILE}" << 'EOF'
```

EOF
  fi
done

cat >> "${INVENTORY_FILE}" << 'EOF'

---

## 3. Configuration Resources

EOF

echo "### Gathering ConfigMaps and Secrets..."

cat >> "${INVENTORY_FILE}" << 'EOF'

### ConfigMaps

#### media Namespace

```
EOF
kubectl get configmaps -n media > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query ConfigMaps in media namespace."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

#### Key ConfigMap Contents

**starr-common-config:**
```
EOF
kubectl get configmap starr-common-config -n media -o yaml > "${TEMP_FILE}" 2>&1 || echo "⚠️  ConfigMap not found or not accessible."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### Secrets

#### media Namespace

```
EOF
kubectl get secrets -n media > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query Secrets in media namespace."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

#### Secret Status Check

**starr-secrets (API Keys):**
```
EOF
kubectl get secret starr-secrets -n media -o jsonpath='{.data}' 2>&1 | jq -r 'keys[]' > "${TEMP_FILE}" 2>&1 || echo "⚠️  Secret not found or keys not accessible."
if [ -s "${TEMP_FILE}" ]; then
  echo "Keys present in secret:" >> "${INVENTORY_FILE}"
  cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
  echo "" >> "${INVENTORY_FILE}"
  echo "⚠️  **Note:** Check if values are empty or populated" >> "${INVENTORY_FILE}"
else
  echo "Secret not found or empty" >> "${INVENTORY_FILE}"
fi
cat >> "${INVENTORY_FILE}" << 'EOF'
```

EOF

cat >> "${INVENTORY_FILE}" << 'EOF'

---

## 4. Persistent Storage (PVCs)

### media Namespace PVCs

```
EOF
kubectl get pvc -n media > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query PVCs in media namespace."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### PVC Details

EOF

kubectl get pvc -n media -o name 2>/dev/null | while read pvc; do
  if [ -n "$pvc" ]; then
    pvc_name=$(echo "$pvc" | cut -d'/' -f2)
    cat >> "${INVENTORY_FILE}" << EOF
**${pvc_name}:**
\`\`\`
EOF
    kubectl describe "$pvc" -n media > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not describe PVC."
    cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
    cat >> "${INVENTORY_FILE}" << 'EOF'
```

EOF
  fi
done

cat >> "${INVENTORY_FILE}" << 'EOF'

---

## 5. Ingress Configuration

### All Ingress Resources

```
EOF
kubectl get ingress --all-namespaces > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query Ingress resources."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### Ingress Details by Service

EOF

# Get all ingress resources
kubectl get ingress --all-namespaces -o name 2>/dev/null | while read ingress; do
  if [ -n "$ingress" ]; then
    namespace=$(echo "$ingress" | cut -d'/' -f1)
    name=$(echo "$ingress" | cut -d'/' -f2)
    cat >> "${INVENTORY_FILE}" << EOF

**${namespace}/${name}:**
\`\`\`
EOF
    kubectl get "$ingress" -n "$namespace" -o yaml > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not get Ingress details."
    cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
    cat >> "${INVENTORY_FILE}" << 'EOF'
```

EOF
  fi
done

cat >> "${INVENTORY_FILE}" << 'EOF'

---

## 6. Service-to-Service Communication

### Service DNS Names

```
EOF
kubectl get services --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[0].port > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query service DNS."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### Expected Service URLs (from ConfigMap)

From `starr-common-config`:
- SONARR_URL: http://sonarr.media.svc.cluster.local:8989
- RADARR_URL: http://radarr.media.svc.cluster.local:7878
- LIDARR_URL: http://lidarr.media.svc.cluster.local:8686
- BAZARR_URL: http://bazarr.media.svc.cluster.local:6767
- PROWLARR_URL: http://prowlarr.media.svc.cluster.local:9696
- JELLYSEERR_URL: http://jellyseerr.media.svc.cluster.local:5055
- QBITTORRENT_URL: http://qbittorrent.qbittorrent.svc.cluster.local:8080
- SABNZBD_URL: http://sabnzbd.media.svc.cluster.local:8081
- FLARESOLVERR_URL: http://flaresolverr.media.svc.cluster.local:8191

---

## 7. API Keys Status

### Current State

**Expected API Keys (from codebase):**
- SONARR_API_KEY
- RADARR_API_KEY
- LIDARR_API_KEY
- BAZARR_API_KEY
- PROWLARR_API_KEY
- JELLYSEERR_API_KEY
- SABNZBD_API_KEY

**Secret Location:** `media/starr-secrets`

**Status Check:**
```
EOF

# Check if secret exists and has non-empty values
if kubectl get secret starr-secrets -n media >/dev/null 2>&1; then
  echo "✅ Secret 'starr-secrets' exists" >> "${INVENTORY_FILE}"
  echo "" >> "${INVENTORY_FILE}"
  echo "Checking key values..." >> "${INVENTORY_FILE}"
  for key in SONARR_API_KEY RADARR_API_KEY LIDARR_API_KEY BAZARR_API_KEY PROWLARR_API_KEY JELLYSEERR_API_KEY SABNZBD_API_KEY; do
    value=$(kubectl get secret starr-secrets -n media -o jsonpath="{.data.${key}}" 2>/dev/null | base64 -d 2>/dev/null || echo "")
    if [ -z "$value" ] || [ "$value" = "" ]; then
      echo "⚠️  ${key}: NOT CONFIGURED (empty)" >> "${INVENTORY_FILE}"
    else
      echo "✅ ${key}: CONFIGURED (value present)" >> "${INVENTORY_FILE}"
    fi
  done
else
  echo "❌ Secret 'starr-secrets' does not exist" >> "${INVENTORY_FILE}"
fi

cat >> "${INVENTORY_FILE}" << 'EOF'
```

---

## 8. Existing Integrations Status

### Check Current Service Configurations

**Note:** This requires accessing service UIs/APIs to verify actual configuration state.

**Services to Check:**
1. **Sonarr** - Check for:
   - Prowlarr integration configured
   - Download client (qBittorrent) configured
   - Root folders configured
2. **Radarr** - Check for:
   - Prowlarr integration configured
   - Download client (qBittorrent) configured
   - Root folders configured
3. **Prowlarr** - Check for:
   - Applications (Sonarr, Radarr) configured with API keys
4. **Jellyseerr** - Check for:
   - Sonarr connection
   - Radarr connection
   - Jellyfin connection
5. **qBittorrent** - Check for:
   - VPN connectivity (if applicable)
   - Accessible from Sonarr/Radarr

**Integration Status:** ⚠️ **TO BE VERIFIED** - Requires service API access

---

## 9. ArgoCD Application Status

### Deployed Applications

```
EOF
kubectl get applications -n argocd > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query ArgoCD applications."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### Application Sync Status

```
EOF
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,STATUS:.status.sync.status,HEALTH:.status.health.status,SYNCED:.status.sync.revision > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query ArgoCD application status."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

---

## 10. Networking and Ingress

### Ingress Class

```
EOF
kubectl get ingressclass > "${TEMP_FILE}" 2>&1 || echo "⚠️  Could not query IngressClass."
cat "${TEMP_FILE}" >> "${INVENTORY_FILE}"
cat >> "${INVENTORY_FILE}" << 'EOF'
```

### External Access

**Domain:** home.brettswift.com

**Service Paths (from codebase):**
- `/` - Homepage
- `/sonarr` - Sonarr
- `/radarr` - Radarr
- `/lidarr` - Lidarr
- `/bazarr` - Bazarr
- `/prowlarr` - Prowlarr
- `/jellyseerr` - Jellyseerr
- `/jellyfin` - Jellyfin
- `/qbittorrent` - qBittorrent
- `/sabnzbd` - Sabnzbd
- `/flaresolverr` - Flaresolverr
- `/prometheus` - Prometheus
- `/grafana` - Grafana
- `/argocd` - ArgoCD

---

## 11. Findings Summary

### ✅ What's Working

- Services deployed and running (to be verified)
- ConfigMaps with service URLs defined
- PVCs created for configuration storage
- Ingress configured for external access
- ArgoCD managing deployments

### ⚠️  What Needs Configuration

- **API Keys:** `starr-secrets` Secret exists but values appear empty
- **Service Integrations:** Need to verify current state via service UIs/APIs
- **Service-to-Service Communication:** URLs defined in ConfigMap, but API authentication needed

### ❌ Known Gaps

- API keys not extracted from existing configurations (if any)
- Integration status unknown (Sonarr-Prowlarr, download clients, etc.)
- Service configurations not verified (root folders, download paths, etc.)

---

## 12. Next Steps

Based on this inventory:

1. **Verify Secret Values:** Check if `starr-secrets` has any populated API keys
2. **Access Service UIs:** Verify current integration state
3. **Extract API Keys:** If services are configured, extract API keys from PVC data or service configurations
4. **Document Integration State:** Document which integrations are already working
5. **Identify Configuration Gaps:** List what needs to be configured

---

**End of Inventory**

EOF

# Replace date placeholder
sed -i.bak "s/\$(date)/$(date)/g" "${INVENTORY_FILE}" 2>/dev/null || \
sed "s/\$(date)/$(date)/g" "${INVENTORY_FILE}" > "${INVENTORY_FILE}.tmp" && mv "${INVENTORY_FILE}.tmp" "${INVENTORY_FILE}"

echo "✅ Inventory complete: ${INVENTORY_FILE}"
echo ""
echo "📋 Next steps:"
echo "   1. Review the inventory document"
echo "   2. Access service UIs to verify integration state"
echo "   3. Check PVC data for existing API keys"
echo "   4. Update the document with findings"







