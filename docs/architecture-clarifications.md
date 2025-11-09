# Architecture Clarifications

**Date:** 2025-01-27  
**Purpose:** Clarify architectural concerns and decisions

---

## Terminology Clarification

### "Root App" Confusion

**What I Meant:** ArgoCD Root Application (GitOps entry point)
- `root-application.yaml` - ArgoCD Application that points to `argocd/applicationsets/`
- This is the **entry point** for GitOps - it tells ArgoCD where to find ApplicationSets
- Used by: `start_k8s.sh` applies this file

**What You Thought:** Web root path (`/`) for homepage
- Homepage currently accessible at `/` (root path)
- Question: Should root path redirect to `/home` or be empty?

**Resolution:**
- ✅ **ArgoCD Root Application:** `root-application.yaml` is correct (points to `argocd/applicationsets/`)
- ⚠️ **Legacy File:** `argocd/root-app.yaml` has wrong path (`argocd-minimal/applications`) - needs cleanup
- 📋 **Homepage Routing:** Separate concern - see design doc for options

---

## Current Architecture Issues

### 1. ArgoCD Not Managed by GitOps

**Problem:** ArgoCD is installed via shell scripts, not managed by GitOps itself.

**Current Flow:**
```
start_k8s.sh
  → Installs k3s cluster
  → Installs ArgoCD via kubectl apply
  → Creates root-application.yaml (manual)
  → GitOps manages applications
```

**Missing:** ArgoCD self-management via GitOps

**Solution:** See [Bootstrap vs GitOps Design](./bootstrap-vs-gitops-design.md)

---

### 2. Blurred Bootstrap vs GitOps Boundary

**Current State:**
- Bootstrap scripts install everything (plugins, ArgoCD)
- GitOps manages applications
- **Gap:** ArgoCD itself not managed by GitOps

**Desired State:**
- **Bootstrap:** One-time cluster + ArgoCD setup
- **GitOps:** Everything else (including ArgoCD self-management)

**Solution:** Clear separation defined in design doc

---

### 3. Homepage Routing Strategy

**Current:** Homepage at `/` (root path)

**Options:**
1. Keep at `/` - Simple, but root path occupied
2. Redirect `/` → `/home` - Clean landing, root available for future
3. Homepage at `/home`, root empty - Explicit routing

**Your Preference:** Option 2 (redirect `/` → `/home`)

**Implementation:** See Bootstrap vs GitOps Design doc

---

## File Cleanup Needed

### `argocd/root-app.yaml`

**Status:** Legacy/Unused  
**Issue:** References non-existent path `argocd-minimal/applications`

**Current State:**
- `root-application.yaml` (root) - ✅ Active, correct path
- `argocd/root-app.yaml` - ❌ Wrong path, appears unused

**Action:**
- [ ] Verify `argocd/root-app.yaml` is not used
- [ ] Delete if unused, OR
- [ ] Update if needed for some purpose

---

## Summary

### Resolved ✅
1. **ArgoCD Root Application** - Correct file is `root-application.yaml`
2. **Homepage Routing Preference** - Redirect `/` → `/home`
3. **Architectural Concerns** - Most are accepted decisions

### Needs Design 📋
1. **ArgoCD Self-Management** - Design complete, needs implementation
2. **Bootstrap → GitOps Transition** - Design complete, needs implementation

### Needs Cleanup ⚠️
1. **Legacy root-app.yaml** - Delete or update
2. **Secrets Management** - Document disaster recovery

---

## Next Steps

1. Review [Bootstrap vs GitOps Design](./bootstrap-vs-gitops-design.md)
2. Clean up `argocd/root-app.yaml`
3. Implement ArgoCD self-management structure
4. Update homepage routing




