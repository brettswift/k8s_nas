# Troubleshooting Starr Integration Configuration

**Quick Reference:** Common issues and solutions when configuring Sonarr-Prowlarr integration.

---

## API Key Reference

**Current API Keys (from `starr-secrets` Secret):**

```
Sonarr API Key:   aa91f40651d84c2bb03faadc07d9ccbc
Prowlarr API Key: 117317d797114158b10f7789affd26e7
```

**Which Key to Use:**

1. **Prowlarr → Sonarr (Adding Sonarr as Application in Prowlarr):**
   - Use: **Sonarr API Key** (`aa91f40651d84c2bb03faadc07d9ccbc`)
   - Reason: Prowlarr needs to authenticate to Sonarr

2. **Sonarr → Prowlarr (Adding Prowlarr as Indexer in Sonarr):**
   - Use: **Prowlarr API Key** (`117317d797114158b10f7789affd26e7`)
   - Reason: Sonarr needs to authenticate to Prowlarr

---

## Configuration Order

**Recommended Order (if having issues):**

1. **First:** Configure Prowlarr → Sonarr Application
   - In Prowlarr: Settings → Apps → Add Sonarr
   - Uses: Sonarr API Key

2. **Second:** Configure Sonarr → Prowlarr Indexer
   - In Sonarr: Settings → Indexers → Add Prowlarr
   - Uses: Prowlarr API Key

**Why this order?** Sometimes configuring Prowlarr → Sonarr first helps establish the connection path.

---

## Connection Test Failures

### Issue: Sonarr can't connect to Prowlarr

**Symptom:** Connection test in Sonarr fails when adding Prowlarr indexer.

**Solutions (try in order):**

1. **Verify API Key:**
   - Ensure you're using **Prowlarr's API key** (not Sonarr's)
   - Key: `117317d797114158b10f7789affd26e7`
   - Check for typos or extra spaces

2. **Try Alternative URLs:**
   
   **Option A: Short DNS (recommended)**
   ```
   http://prowlarr:9696
   ```
   
   **Option B: Full DNS (default)**
   ```
   http://prowlarr.media.svc.cluster.local:9696
   ```
   
   **Option C: ClusterIP (if DNS fails)**
   ```
   http://10.43.133.135:9696
   ```
   *Note: ClusterIP may change if service is recreated*

3. **Verify Prowlarr is Accessible:**
   ```bash
   # Test from cluster
   kubectl run -it --rm test --image=alpine:3.20 --restart=Never --namespace=media -- \
     sh -c "apk add --no-cache curl && curl -v http://prowlarr.media.svc.cluster.local:9696/prowlarr/ping"
   ```

4. **Check Network Policies:**
   - Ensure no NetworkPolicy is blocking pod-to-pod communication in `media` namespace

### Issue: Prowlarr can't connect to Sonarr

**Symptom:** Connection test in Prowlarr fails when adding Sonarr application.

**Solutions:**

1. **Verify API Key:**
   - Ensure you're using **Sonarr's API key** (not Prowlarr's)
   - Key: `aa91f40651d84c2bb03faadc07d9ccbc`

2. **Try Alternative URLs:**
   ```
   http://sonarr:8989
   ```
   or
   ```
   http://sonarr.media.svc.cluster.local:8989
   ```

---

## API Key Format Issues

### Issue: "API key from secret fails"

**Possible Causes:**

1. **Wrong API Key:**
   - Using Sonarr key where Prowlarr key is needed (or vice versa)
   - Double-check which key goes where (see "Which Key to Use" above)

2. **Copy/Paste Issues:**
   - Extra spaces before/after key
   - Missing characters
   - Try typing manually instead of copy/paste

3. **Key Changed:**
   - If you signed up in Prowlarr, a new API key may have been generated
   - Check current key: Go to Prowlarr → Settings → General → Security → API Key

**Solution:**
```bash
# Get current keys from secret
kubectl get secret starr-secrets -n media -o jsonpath='{.data.SONARR_API_KEY}' | base64 -d && echo
kubectl get secret starr-secrets -n media -o jsonpath='{.data.PROWLARR_API_KEY}' | base64 -d && echo

# Get current key from Prowlarr UI
# Go to: Prowlarr → Settings → General → Security → API Key
# Compare with secret value
```

---

## Quick Configuration Checklist

**Prowlarr → Sonarr (Settings → Apps → Add Application):**
- ✅ Application: Sonarr
- ✅ Sonarr Server URL: `http://sonarr.media.svc.cluster.local:8989` (or `http://sonarr:8989`)
- ✅ API Key: `aa91f40651d84c2bb03faadc07d9ccbc` (Sonarr's key)
- ✅ Sync Level: Add and Remove Only
- ✅ Sync App Indexers: Enabled

**Sonarr → Prowlarr (Settings → Indexers → Add Indexer):**
- ✅ Indexer Type: Prowlarr
- ✅ Prowlarr URL: `http://prowlarr.media.svc.cluster.local:9696` (or `http://prowlarr:9696`)
- ✅ API Key: `117317d797114158b10f7789affd26e7` (Prowlarr's key)
- ✅ Sync Level: Full Sync

---

## Still Having Issues?

1. **Check Service Logs:**
   ```bash
   kubectl logs -n media -l app=prowlarr --tail=50
   kubectl logs -n media -l app=sonarr --tail=50
   ```

2. **Verify Services are Running:**
   ```bash
   kubectl get pods -n media -l 'app in (sonarr,prowlarr)'
   ```

3. **Test Network Connectivity:**
   ```bash
   # From Sonarr pod
   kubectl exec -n media -l app=sonarr -- ping -c 3 prowlarr.media.svc.cluster.local
   
   # From Prowlarr pod
   kubectl exec -n media -l app=prowlarr -- ping -c 3 sonarr.media.svc.cluster.local
   ```

---

**Last Updated:** 2025-01-27







