# OpenClaw status and troubleshooting

This doc explains what `openclaw status` shows in this deployment and how to fix common issues (including npm, Telegram plugin, and wiping the PVC).

## Running status in the cluster

```bash
export KUBECONFIG=~/.kube/config-nas
kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- node /app/dist/index.js status
kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- node /app/dist/index.js status --all
```

## What status shows

- **Update: pnpm · npm latest unknown**  
  The gateway image runs Node and loads plugins from the image and from the PVC. It does not run `npm` or `pnpm` inside the container, so the CLI cannot resolve "latest" version. This is expected in the containerized setup and is not caused by moving `node_modules` unless you overwrote image or extension files.

- **Channels: empty**  
  If the Telegram plugin fails to load (see below), no channels appear. Other channels (e.g. webchat) may still work via the Control UI.

- **Telegram plugin: fails to load**  
  Logs show:
  `telegram failed to load from /app/extensions/telegram/index.ts: Error: Cannot find module '../../../src/infra/outbound/send-deps.js'`  
  The **image** (`ghcr.io/openclaw/openclaw:main`) ships the Telegram extension as TypeScript that requires a path that does not exist in the built image. This is an upstream image bug, not a misconfiguration. You cannot fix it by editing config or the PVC. Options: wait for an upstream fix, try a different image tag, or build a custom image. See [Telegram plugin fails](#telegram-plugin-fails) below.

- **Security audit**  
  Run `openclaw security audit --deep` (inside the pod) for full findings. Common items: config/credentials dir permissions, `gateway.trustedProxies`, `plugins.allow`.

- **node_modules on the PVC**  
  The only `node_modules` directory on the PVC in a typical install is under `extensions/openclaw-linear/node_modules` (for the Linear extension). The rest of OpenClaw runs from the image. If you copied a full `node_modules` tree into the PVC (e.g. under `~/.openclaw`), it can conflict with how the image resolves modules. Prefer not to put image-level dependencies on the PVC; only extension-specific `node_modules` (e.g. for user-installed extensions) belong there.

## Telegram plugin fails

**Symptom:** Logs show:

```text
[plugins] telegram failed to load from /app/extensions/telegram/index.ts: Error: Cannot find module '../../../src/infra/outbound/send-deps.js'
Require stack:
- /app/extensions/telegram/src/channel.ts
```

**Cause:** The Docker image includes the Telegram extension source that references `../../../src/infra/outbound/send-deps.js`. That path is not present in the built image (upstream build/packaging issue).

**What you can do:**

1. **Leave Telegram disabled**  
   Use the Control UI (webchat) only until the image is fixed.

2. **Try another image tag**  
   Check [OpenClaw GitHub](https://github.com/openclaw/openclaw) / releases for a tag where Telegram is known to work, and set that tag in `deployment.yaml` (e.g. `image: ghcr.io/openclaw/openclaw:<tag>`). Then push to `live` and let ArgoCD sync.

3. **Wipe PVC and start fresh**  
   If you have a backup and want a clean state (no old extensions or config), you can delete the PVC and start over. See [Wiping the PVC](#wiping-the-pvc) below. This does not fix the Telegram bug in the image; it only gives you a clean data dir.

## Workspace permissions (EACCES on workspace files)

**Symptom:** Config or tools fail with `EACCES: permission denied, open '/home/node/.openclaw/workspace/...'`

**Cause:** The gateway runs as UID 1000 (`node`). The PVC must be owned by 1000:1000 so the process can read/write the workspace (and openclaw.json, etc.). Some storage drivers or bootstrap steps can leave files/dirs owned by root.

**What we do:** The deployment includes an init container `ensure-workspace-perms` that runs as root and:

- `chown -R 1000:1000 /data` so the whole `.openclaw` tree is owned by the gateway user
- `mkdir -p /data/workspace` and sets ownership so the workspace exists and is writable

After a fresh PVC or any restart, the init runs before the gateway, so the gateway can write to the workspace. If you see EACCES again, ensure this init container is present and that no other process is creating root-owned files under the volume.

## Config auto-recovery (sentinel + restore)

When a bad config change causes the gateway to crash before becoming healthy, the deployment auto-restores the previous config on the next pod start.

**How it works:**

1. **Sentinel:** The init container writes `.gateway-starting` before the gateway starts. A sidecar waits for the gateway to respond to `/healthz`, then removes the sentinel.
2. **Crash detection:** If the pod restarts (e.g. CrashLoopBackOff) before the sidecar clears the sentinel, the sentinel still exists on the next start.
3. **Restore:** The init container sees the sentinel and restores from `openclaw.json.bak` (OpenClaw creates this whenever it overwrites the config). If `.bak` is missing, it falls back to the golden ConfigMap `openclaw-golden-config`.
4. **Bad config kept:** The current (broken) config is copied to `openclaw.json.bad.<timestamp>` before restore so you can inspect it.

**Manual restore:** Delete the gateway pod; the init will restore on the next start if the previous run crashed before becoming healthy. To force a restore, remove the sentinel manually (e.g. via ArgoCD terminal) and delete the pod — but if the pod was healthy, the sentinel is already gone, so you'd need to create a dummy sentinel first, then delete the pod.

## Wiping the PVC

If you have a backup and want to reset OpenClaw data (config, workspace, extensions, agents) to a clean state:

1. **Scale the gateway to 0** so the PVC is not in use:

   ```bash
   export KUBECONFIG=~/.kube/config-nas
   kubectl scale deployment openclaw-gateway -n openclaw --replicas=0
   kubectl wait --for=delete pod -l app=openclaw-gateway -n openclaw --timeout=120s || true
   ```

2. **Delete the PVC** (and thus the PersistentVolume if it was provisioned):

   ```bash
   kubectl delete pvc openclaw-data -n openclaw
   ```

3. **Recreate the PVC** (ArgoCD will recreate it from git if the PVC is in the app manifest; otherwise apply the same `pvc.yaml`):

   ```bash
   kubectl apply -f apps/infrastructure/openclaw/pvc.yaml
   # Or push to live and let ArgoCD sync the app (including pvc.yaml).
   ```

4. **Scale the gateway back to 1**:

   ```bash
   kubectl scale deployment openclaw-gateway -n openclaw --replicas=1
   kubectl rollout status deployment/openclaw-gateway -n openclaw
   ```

5. **Fresh start**  
   The init container will create a minimal `openclaw.json` if the file is missing. Re-enter the gateway token in the Control UI, re-add API keys (or rely on existing K8s secrets and config), and restore from backup only what you need (e.g. config snippets, skills, workspace files).

**Important:** All data on the old PVC (config, sessions, extensions, workspace, credentials) is gone after delete. Restore selectively from backup; do not restore a full copy of an old `node_modules` tree that might conflict with the image.
