# Claude Code Guidance for k8s NAS

> **See also:** `docs/AI_GUIDANCE.md` for detailed infrastructure information

## Critical Rules

**Critical Constraints:**

- **Remote cluster only** - Target the k3s server at `10.1.0.20` (no local k3d/kind setup exists)
- **GitOps workflow required** - Make changes through Git commits and ArgoCD sync (not `kubectl apply`)
- **Protect secrets** - Use kubectl secrets or sealed secrets; never commit credentials

**Deployment Workflow:**

1. Edit manifests in your feature branch
2. Commit: `git commit -m "descriptive message"`
3. Deploy: `git push origin <your-branch>:live`
4. ArgoCD syncs to cluster (auto or manual via UI)
5. Verify: https://home.brettswift.com/argocd

**Rollback:**

```bash
# Restore previous working branch
git push origin <previous-working-branch>:live

# Or restore specific commit
git push origin <commit-sha>:live
```

---

## Claude Skills for This Project

Claude invokes these skills automatically or on request:

**Available Skills:**

- **`superpowers:brainstorming`** - Use before adding new services or making architectural changes
  - Example: "Use brainstorming to help me add Prometheus monitoring"

- **`superpowers:systematic-debugging`** - When pods fail, ArgoCD won't sync, or ingress breaks
  - Example: "Use systematic debugging to figure out why the jellyfin pod is crashing"

- **`superpowers:writing-plans`** - For multi-step changes (e.g., migrating a service, major refactors)
  - Example: "Use writing-plans to create a plan for migrating all services to use external-secrets"

- **`superpowers:verification-before-completion`** - Verify cluster changes before claiming success
  - Invoked automatically before completion

**Testing:** This project tests on the live cluster (not TDD):
1. Push to `live` branch
2. Test on cluster
3. Rollback if needed: `git push origin <previous-branch>:live`

---

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

**Branches:**

- **`live`** - Running on cluster (ArgoCD target)
- **`feat/*`** - Development branches
- **Deploy**: `git push origin <your-branch>:live`
- **Rollback**: `git push origin <previous-branch>:live`

---

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

4. **Verify**
   - ArgoCD UI: https://home.brettswift.com/argocd
   - Pods: `kubectl get pods -n <namespace>`
   - Ingress: `curl https://home.brettswift.com/<service>`

5. **Rollback if needed**
   ```bash
   git push origin <previous-branch>:live
   ```

### Debugging Deployment Issues

**Check ArgoCD:**
- UI: https://home.brettswift.com/argocd
- Review sync errors and health status

**Check pods:**
```bash
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Check events:**
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

**Complex issues:**
- Use `superpowers:systematic-debugging` skill
- Compare with similar working services

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
4. **Wait for ArgoCD sync** (auto or manual via UI)
5. **Verify** changes on cluster

### Rollback

```bash
# Deploy new version
git push origin feat/new-feature:live

# Restore previous working state
git push origin feat/previous-working:live

# Or restore specific commit
git push origin a1b2c3d:live

# Verify in ArgoCD UI
# Check pod health: kubectl get pods -A
```

---

## Additional Resources

**Key Documentation:**

- **Infrastructure details**: `docs/AI_GUIDANCE.md` - Server access, kubeconfig, certificate setup, current services
- **Starr integrations**: `docs/configure-starr-integrations.md` - Configure media service integrations
- **Bootstrap guide**: `BOOTSTRAP.md` - Production server setup instructions

**Quick Reference:**

- **Kubeconfig**: `export KUBECONFIG=~/.kube/config-nas`
- **ArgoCD UI**: https://home.brettswift.com/argocd
- **Server SSH**: `ssh 10.1.0.20` or `ssh nas`
- **Verification**: Check ArgoCD sync status and pod health after every deploy

**Philosophy:**

> Commit small, test on live, rollback easily

When in doubt:
1. Make small incremental changes
2. Commit each logical step
3. Push to live and verify
4. Keep previous working branch in mind for quick rollback
