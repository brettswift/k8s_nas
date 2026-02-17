# CLAUDE.md Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a concise Claude-specific guidance document at repository root that supplements AI_GUIDANCE.md with Claude Code skills, workflows, and project conventions.

**Architecture:** Single markdown file at root with 5 sections: Critical Rules, Claude Skills, Project Structure, Common Workflows, and Additional Resources. Focuses on safety constraints, practical patterns, and the git push origin <branch>:live deployment workflow.

**Tech Stack:** Markdown, elements-of-style skill for clear writing

---

## Task 1: Create CLAUDE.md with Critical Rules Section

**Files:**
- Create: `CLAUDE.md`

**Step 1: Create file with header and Critical Rules section**

```markdown
# Claude Code Guidance for k8s NAS

> **See also:** `docs/AI_GUIDANCE.md` for detailed infrastructure information

## Critical Rules

**🚫 What NOT to do:**

- **No local cluster** - This project has NO local k3d/kind setup. Always target the remote k3s server at `10.1.0.20`
- **No `kubectl apply`** - This is a GitOps project. ALL changes go through Git commits + ArgoCD sync
- **Never commit secrets** - Use kubectl secrets or sealed secrets, never commit credentials

**✅ How changes work:**

1. Edit manifests in your feature branch
2. Commit changes: `git commit -m "descriptive message"`
3. Deploy to live: `git push origin <your-branch>:live`
4. ArgoCD auto-syncs to cluster (or manually sync via UI)
5. Verify in ArgoCD UI: https://home.brettswift.com/argocd

**✅ Rollback pattern:**

```bash
# If your change breaks something
git push origin <previous-working-branch>:live

# Or rollback to specific commit
git push origin <commit-sha>:live
```

---
```

**Step 2: Verify file was created**

Run: `ls -lh CLAUDE.md`
Expected: File exists with ~50 lines

**Step 3: Commit Critical Rules section**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md with Critical Rules section

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Add Claude Skills Section

**Files:**
- Modify: `CLAUDE.md` (append after Critical Rules)

**Step 1: Add Claude Skills section**

Add this content to `CLAUDE.md`:

```markdown
## Claude Skills for This Project

Claude automatically invokes these skills when appropriate, but you can also explicitly request them:

**Available Skills:**

- **`superpowers:brainstorming`** - Use before adding new services or making architectural changes
  - Example: "Use brainstorming to help me add Prometheus monitoring"

- **`superpowers:systematic-debugging`** - When pods fail, ArgoCD won't sync, or ingress breaks
  - Example: "Use systematic debugging to figure out why the jellyfin pod is crashing"

- **`superpowers:writing-plans`** - For multi-step changes (e.g., migrating a service, major refactors)
  - Example: "Use writing-plans to create a plan for migrating all services to use external-secrets"

- **`superpowers:verification-before-completion`** - Verify changes on cluster before claiming success
  - Automatically invoked when claiming work is complete

**Workflow Note:** This project tests on the live cluster (not TDD). The pattern is:
1. Push to `live` branch
2. Test on actual cluster
3. Rollback via `git push origin <previous-branch>:live` if needed

---
```

**Step 2: Verify section was added**

Run: `grep -A 5 "Claude Skills" CLAUDE.md`
Expected: Shows the new section header and content

**Step 3: Commit Claude Skills section**

```bash
git add CLAUDE.md
git commit -m "docs: add Claude Skills section to CLAUDE.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Add Project Structure Section

**Files:**
- Modify: `CLAUDE.md` (append after Claude Skills)

**Step 1: Add Project Structure section**

Add this content to `CLAUDE.md`:

```markdown
## Project Structure

```
k8s_nas/
├── apps/                          # All application manifests
│   ├── infrastructure/            # Core services (argocd, cert-manager, monitoring, blocky, external-dns)
│   ├── media-services/            # Starr apps (jellyfin, qbittorrent, starr/)
│   ├── homeautomation/            # Home Assistant, Matter server
│   └── homepage/                  # Homepage dashboard
├── argocd/                        # ArgoCD Applications and ApplicationSets
│   ├── applications/              # Individual Application manifests
│   └── projects/                  # ArgoCD Projects (e.g., nas)
├── docs/                          # Documentation
│   ├── AI_GUIDANCE.md             # Infrastructure details (server, certs, access)
│   └── plans/                     # Design and implementation plans
├── scripts/                       # Helper scripts (argocd-local-user.sh, etc.)
└── bootstrap/                     # Initial cluster setup scripts
```

**Key Patterns:**

- **Kustomization**: Each app has `kustomization.yaml` to manage resources
- **Standard resources**: Services use `namespace.yaml`, `deployment.yaml`, `service.yaml`, `ingress.yaml`
- **Shared configs**: ConfigMaps or Secrets (e.g., `starr-secrets` in `media` namespace)
- **Ingress pattern**: All services at `home.brettswift.com/<service>` via NGINX Ingress

**Branch Strategy:**

- **`live`** - What's running on the cluster (ArgoCD targets this branch)
- **`feat/*`** - Feature branches for development
- **Deploy**: `git push origin <your-branch>:live`
- **Rollback**: `git push origin <previous-working-branch>:live`

---
```

**Step 2: Verify section was added**

Run: `grep -A 10 "Project Structure" CLAUDE.md | head -15`
Expected: Shows directory tree and key patterns

**Step 3: Commit Project Structure section**

```bash
git add CLAUDE.md
git commit -m "docs: add Project Structure section to CLAUDE.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Add Common Workflows Section

**Files:**
- Modify: `CLAUDE.md` (append after Project Structure)

**Step 1: Add Common Workflows section**

Add this content to `CLAUDE.md`:

```markdown
## Common Workflows

### Adding a New Service

1. **Create app manifests** in `apps/<category>/<service>/`
   - `namespace.yaml` - Create namespace
   - `deployment.yaml` - Define pods, containers, volumes
   - `service.yaml` - Expose pods internally
   - `ingress.yaml` - Expose via `home.brettswift.com/<service>`
   - `kustomization.yaml` - List all resources

2. **Create ArgoCD Application** in `argocd/applications/<service>.yaml`
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: <service>
     namespace: argocd
   spec:
     project: nas
     source:
       repoURL: https://github.com/brettswift/brettswift.git
       targetRevision: live
       path: bs-mediaserver-projects/k8s_nas/apps/<category>/<service>
     destination:
       server: https://kubernetes.default.svc
       namespace: <namespace>
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```

3. **Deploy to live**
   ```bash
   git add apps/<category>/<service>/ argocd/applications/<service>.yaml
   git commit -m "feat: add <service> to <category>"
   git push origin feat/add-service:live
   ```

4. **Verify deployment**
   - Check ArgoCD UI: https://home.brettswift.com/argocd
   - Check pods: `kubectl get pods -n <namespace>`
   - Check ingress: `curl https://home.brettswift.com/<service>`

5. **Rollback if needed**
   ```bash
   git push origin <previous-working-branch>:live
   ```

### Debugging Deployment Issues

**Check ArgoCD sync status:**
- UI: https://home.brettswift.com/argocd
- Look for sync errors, health status

**Check pod status:**
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Check events:**
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**For complex issues:**
- Use `superpowers:systematic-debugging` skill
- Check similar working services for patterns

### Updating Configurations

1. **Edit manifests** in `apps/<category>/<service>/`
2. **Commit changes**
   ```bash
   git add apps/<category>/<service>/
   git commit -m "fix: update <service> configuration"
   ```
3. **Deploy to live**
   ```bash
   git push origin <branch>:live
   ```
4. **Verify ArgoCD auto-syncs** (or manually sync via UI)
5. **Check changes** applied on cluster

### Rollback Pattern

```bash
# Deploy new version
git push origin feat/new-feature:live

# If it breaks, rollback to previous working state
git push origin feat/previous-working:live

# Or rollback to specific commit
git push origin a1b2c3d:live

# Verify rollback in ArgoCD UI
# Check pods are healthy: kubectl get pods -A
```

---
```

**Step 2: Verify section was added**

Run: `grep -A 5 "Common Workflows" CLAUDE.md`
Expected: Shows workflow section with subsections

**Step 3: Commit Common Workflows section**

```bash
git add CLAUDE.md
git commit -m "docs: add Common Workflows section to CLAUDE.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Add Additional Resources Section

**Files:**
- Modify: `CLAUDE.md` (append at end)

**Step 1: Add Additional Resources section**

Add this content to `CLAUDE.md`:

```markdown
## Additional Resources

**Key Documentation:**

- **Infrastructure details**: `docs/AI_GUIDANCE.md` - Server access, kubeconfig, certificate setup, current services
- **Starr integrations**: `docs/configure-starr-integrations.md` - Configure media service integrations
- **Bootstrap guide**: `BOOTSTRAP.md` - Production server setup instructions

**Quick Reference:**

- **Kubeconfig**: `export KUBECONFIG=~/.kube/config-nas` (set before kubectl commands)
- **ArgoCD UI**: https://home.brettswift.com/argocd
- **Server SSH**: `ssh 10.1.0.20` or `ssh nas` (if configured)
- **Verification**: Always check ArgoCD sync status and pod health after deploying

**Philosophy:**

> Commit small, test on live, rollback easily

When in doubt:
1. Make small incremental changes
2. Commit each logical step
3. Push to live and verify
4. Keep previous working branch in mind for quick rollback
```

**Step 2: Verify section was added**

Run: `tail -20 CLAUDE.md`
Expected: Shows Additional Resources section

**Step 3: Verify complete document structure**

Run: `grep "^##" CLAUDE.md`
Expected: Shows all 5 section headers

**Step 4: Commit Additional Resources section**

```bash
git add CLAUDE.md
git commit -m "docs: add Additional Resources section to CLAUDE.md

Complete CLAUDE.md with all sections:
- Critical Rules
- Claude Skills
- Project Structure
- Common Workflows
- Additional Resources

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Apply Writing Style and Final Review

**Files:**
- Modify: `CLAUDE.md` (final polish)

**Step 1: Review with elements-of-style skill**

Use `elements-of-style:writing-clearly-and-concisely` skill to:
- Remove unnecessary words
- Make writing more direct and active
- Ensure clarity and conciseness
- Fix any awkward phrasing

**Step 2: Verify document completeness**

Check that CLAUDE.md includes:
- [ ] Critical Rules (safety constraints)
- [ ] Claude Skills (with examples)
- [ ] Project Structure (directory tree, patterns, branch strategy)
- [ ] Common Workflows (adding service, debugging, updating, rollback)
- [ ] Additional Resources (links and quick tips)

**Step 3: Test readability**

Run: `wc -l CLAUDE.md`
Expected: ~150-200 lines (concise target met)

**Step 4: Commit final polish**

```bash
git add CLAUDE.md
git commit -m "docs: polish CLAUDE.md for clarity and conciseness

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Success Criteria

- [ ] CLAUDE.md exists at repository root
- [ ] All 5 sections present and complete
- [ ] Critical rules prominently featured at top
- [ ] Claude skills documented with examples
- [ ] Project structure clearly explained
- [ ] Common workflows have step-by-step instructions
- [ ] Rollback pattern `git push origin <branch>:live` highlighted
- [ ] Document is concise (~150-200 lines)
- [ ] Writing is clear, direct, and actionable
- [ ] No local cluster or kubectl apply instructions
- [ ] References AI_GUIDANCE.md appropriately
- [ ] All changes committed to Git

---

## Notes

- **No TDD**: Project tests on live cluster, not via test-first development
- **GitOps only**: All changes via Git + ArgoCD, never kubectl apply
- **Lightweight**: No bmad-style heavy process documentation
- **Practical**: Focus on working examples and actual patterns
- **Safety**: Rollback pattern featured prominently for risk mitigation
