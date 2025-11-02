# Quick Start: Sonarr-Prowlarr Integration

**TL;DR:** Only configure in Prowlarr. No Sonarr configuration needed - Prowlarr syncs indexers automatically.

---

## Step-by-Step

### Step 1: Configure Prowlarr → Sonarr (THIS IS ALL YOU DO)

1. Go to **Prowlarr**: `https://home.brettswift.com/prowlarr`
2. **Settings** → **Apps** → **+ Add Application** → Select **Sonarr**
3. Fill in:
   - **Sonarr URL**: `http://sonarr:8989` (or `http://sonarr.media.svc.cluster.local:8989`)
   - **API Key**: `aa91f40651d84c2bb03faadc07d9ccbc` ← **Sonarr's API key** (NOT Prowlarr's!)
   - **Sync Level**: 
     - **Full Sync** ← Recommended if Prowlarr is your single source of truth
     - **Add and Remove Only** ← Use if you want to customize indexers in Sonarr
   - ✅ **Sync App Indexers**: Enabled
4. Click **Test**
5. Click **Save**

**That's it!** No configuration needed in Sonarr.

---

### Step 2: Add Indexers in Prowlarr (Optional)

1. In **Prowlarr**: **Indexers** → **+ Add Indexer**
2. Add your preferred indexers
3. They will automatically sync to Sonarr!

---

### Step 3: Verify in Sonarr

1. Go to **Sonarr**: `https://home.brettswift.com/sonarr`
2. **Settings** → **Indexers**
3. You should see the indexers from Prowlarr listed here automatically
4. You did NOT add them manually - Prowlarr synced them!

---

## Important Notes

- **No Sonarr configuration needed** - you don't add Prowlarr as an indexer in Sonarr
- **Only configure in Prowlarr** - add Sonarr as an application in Prowlarr
- **Keys are NOT automatically loaded** - you must type/paste the Sonarr API key manually
- **Use Sonarr's API key** (`aa91f40651d84c2bb03faadc07d9ccbc`) in Prowlarr

---

## If Connection Test Fails

1. ✅ **Verify you're using Sonarr's API key** (not Prowlarr's)
2. ✅ **Try the short DNS form** (`http://sonarr:8989`)
3. ✅ **Save anyway** - sometimes sync works even if test fails

---

**Last Updated:** 2025-01-27

