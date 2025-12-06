# Prowlarr Sync Level: Full Sync vs Add and Remove Only

## Quick Answer

**"Add and Remove Only" seems limited because it is - but that's by design for flexibility.**

---

## Sync Level Options

### 1. **Full Sync** (Recommended for Most Users)

**What it does:**
- ✅ Adds new indexers from Prowlarr to Sonarr
- ✅ Removes deleted indexers from Sonarr
- ✅ **Updates settings of existing indexers** (priority, enabled/disabled, etc.)

**Best for:**
- You want Prowlarr to be the **single source of truth**
- You manage all indexer settings in Prowlarr
- You don't need to customize indexers individually in Sonarr
- You want changes in Prowlarr to automatically reflect in Sonarr

**Example:**
- Change indexer priority in Prowlarr → automatically updates in Sonarr
- Disable an indexer in Prowlarr → automatically disabled in Sonarr

---

### 2. **Add and Remove Only** (Recommended for Power Users)

**What it does:**
- ✅ Adds new indexers from Prowlarr to Sonarr
- ✅ Removes deleted indexers from Sonarr
- ❌ **Does NOT update settings** of existing indexers

**Best for:**
- You want to customize indexer settings in Sonarr
- You want different priorities/tags in Sonarr vs Prowlarr
- You want to fine-tune settings per application without Prowlarr overwriting them

**Example:**
- Add indexer in Prowlarr → appears in Sonarr
- Change priority in Sonarr → stays changed (Prowlarr won't overwrite)
- Change priority in Prowlarr → **does NOT change in Sonarr** (only adds/removes sync)

---

### 3. **Add Only**
- Only adds new indexers
- Never removes or updates
- Rarely used

---

### 4. **Disabled**
- No synchronization
- Manual management only

---

## Which Should You Choose?

### Choose **Full Sync** if:
- ✅ You're new to the stack
- ✅ You want simplicity - manage everything in one place (Prowlarr)
- ✅ You don't need different settings per application
- ✅ You want automatic updates when you change things in Prowlarr

### Choose **Add and Remove Only** if:
- ✅ You need different indexer priorities in Sonarr vs Radarr
- ✅ You want to customize tags or settings per application
- ✅ You're okay managing some settings manually in Sonarr
- ✅ You want flexibility to override Prowlarr's defaults

---

## Recommendation

**For most users: Start with Full Sync**

- It's simpler and more automated
- Prowlarr becomes your single control point
- If you later need customization, you can switch to "Add and Remove Only"

**For advanced users: Use Add and Remove Only**

- If you know you need different settings per application
- If you want fine-grained control

---

## How to Change Later

You can always change the sync level:
1. Go to Prowlarr → Settings → Apps
2. Edit your Sonarr application
3. Change "Sync Level"
4. Save

---

**Last Updated:** 2025-01-27









