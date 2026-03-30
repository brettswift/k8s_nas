# OpenClaw status and troubleshooting

This doc explains what `openclaw status` shows in this deployment and how to fix common issues (including npm, Telegram plugin, and wiping the PVC).

## Running status in the cluster

```bash
export KUBECONFIG=~/.kube/config-nas
kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- node /app/dist/index.js status
kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- node /app/dist/index.js status --all
```

## What status shows

- **Gateway: unreachable (missing scope: operator.read)**  
  The in-pod **`openclaw status`** CLI opens loopback WS **without** the same device/session path as the Control UI, so this table row is often misleading while the gateway is up. Confirm with **`curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:18789/healthz`** in the **gateway** container (expect **200**), or use Telegram / the Control UI.

- **Logs: `[ws] ⇄ res ✗` … `missing scope: operator.read` on `status` / `system-presence` / `config.get`**  
  This is a **known OpenClaw 2026.3.13 regression**: stricter device-auth rejects those RPCs for token-based WS clients that lack a registered device identity, so the gateway logs **INVALID_REQUEST** even when your cluster secret and UI token are fine. Chat (e.g. Telegram) can still work. Upstream: [openclaw#47640](https://github.com/openclaw/openclaw/issues/47640) (fixed in later releases; **2026.3.23** also hardens Control UI operator scopes). **Remediation:** rebuild and deploy the custom gateway image from **`apps/infrastructure/openclaw/Dockerfile`** using base **`ghcr.io/openclaw/openclaw:2026.3.23`** (or newer stable), then confirm Telegram and the Control UI.

- **Update: pnpm · npm latest unknown**  
  The gateway image runs Node and loads plugins from the image and from the PVC. It does not run `npm` or `pnpm` inside the container, so the CLI cannot resolve "latest" version. This is expected in the containerized setup and is not caused by moving `node_modules` unless you overwrote image or extension files.

- **Channels: empty**  
  If the Telegram plugin fails to load (see below), no channels appear. Other channels (e.g. webchat) may still work via the Control UI.

- **Channels: empty but `channels.telegram.enabled` is true**  
  Check **`openclaw plugins list`**: the stock **Telegram** row must be **loaded/enabled**, not **disabled**. If you use **`plugins.allow`** as a whitelist (e.g. only **`rtk-rewrite`**), the **Telegram** stock plugin is **not** loaded until you add **`telegram`** to **`plugins.allow`**. **`plugins.entries.telegram.enabled`** alone is not enough. Fix: add **`telegram`** to **`plugins.allow`**, then **`openclaw plugins enable telegram`** (or edit JSON) and **restart the gateway**. Symptom: **`openclaw status`** shows an empty Channels table and logs have **no** **`[telegram]`** lines at startup.

- **Telegram plugin: fails to load**  
  Logs show:
  `telegram failed to load from /app/extensions/telegram/index.ts: Error: Cannot find module '../../../src/infra/outbound/send-deps.js'`  
  The **image** (`ghcr.io/openclaw/openclaw:main`) ships the Telegram extension as TypeScript that requires a path that does not exist in the built image. This is an upstream image bug, not a misconfiguration. You cannot fix it by editing config or the PVC. Options: wait for an upstream fix, try a different image tag, or build a custom image. See [Telegram plugin fails](#telegram-plugin-fails) below.

- **Security audit**  
  Run `openclaw security audit --deep` (inside the pod) for full findings. Common items: config/credentials dir permissions, `gateway.trustedProxies`, `plugins.allow`.

- **node_modules on the PVC**  
  The only `node_modules` directory on the PVC in a typical install is under `extensions/openclaw-linear/node_modules` (for the Linear extension). The rest of OpenClaw runs from the image. If you copied a full `node_modules` tree into the PVC (e.g. under `~/.openclaw`), it can conflict with how the image resolves modules. Prefer not to put image-level dependencies on the PVC; only extension-specific `node_modules` (e.g. for user-installed extensions) belong there.

## Telegram: typing indicator, then silence

**Symptoms:** The bot shows “typing” for a long time, then stops with no message.
Logs often include:

- `[tools] read failed: Missing required parameter: path`
- `[agent/embedded] read tool called without path`
- `read failed: ENOENT` where the “path” is clearly a **shell command** pasted into
  the tool
- `typing TTL reached (2m); stopping typing indicator`
- `write failed: Missing required parameter: content` or `image failed: image required`

**Typical cause:** The **DM session transcript grew very large** (hundreds of
thousands of input tokens). The model starts emitting **invalid tool calls**;
each failure burns another turn until the typing window expires.

**Check (in the gateway container):**

```bash
openclaw sessions --json | grep -A6 'telegram:direct'
```

If **`inputTokens`** is huge for
`agent:main:telegram:direct:<your_user_id>`, reset that session.

**Reset one Telegram DM session (PVC-backed):**

1. Find the key **`agent:main:telegram:direct:<telegram_user_id>`** and its
   **`sessionId`** in **`~/.openclaw/agents/main/sessions/sessions.json`**.
2. **Back up** `sessions.json`, **remove** that object key from the JSON, and
   **rename** **`<sessionId>.jsonl`** to something like
   **`<sessionId>.jsonl.deleted.<timestamp>`** in the same directory (same
   pattern as other `.deleted.*` files already on disk).
3. **`kubectl rollout restart deployment/openclaw-gateway -n openclaw`** so the
   gateway drops any in-memory copy of the old session.

The next DM starts a **fresh** conversation (pairing / allowlist rules
unchanged).

## Control UI: WebSocket `gateway token missing`

**Symptom:** Logs show `reason=unauthorized: gateway token missing` and `code=1008` for connections from the browser (`openclaw-control-ui`), often with `remote=10.42.0.1` (ingress) and your LAN IP in `fwd=`.

**Cause:** The Control UI has not stored the same token as `gateway.auth.token` (from the `openclaw-gateway-token` secret). The gateway is behaving correctly.

**Fix:** Open https://openclaw.home.brettswift.com → **Settings → Auth** → paste the gateway token (see [README prerequisites](README.md)). Optionally set `gateway.trustedProxies` to your ingress hop IPs if you see “Proxy headers detected from untrusted address” and expect tokenless local behavior—you still normally need the token in the UI for WS auth.

## Tool noise, mangled paths, and Linear script names

**`tools.profile (coding) allowlist contains unknown entries`**  
The preset **`coding`** profile always includes tools in `group:fs`,
`group:memory`, etc. OpenClaw **warns** when those names are not registered
(e.g. **memory search off** without embedding keys, or `apply_patch` blocked
by `tools.exec.applyPatch`). **`tools.deny` does not silence** that check.

**Balanced default on this cluster:** **`tools.profile: "full"`** plus a **short**
**`tools.deny`**: `browser`, `canvas`, `nodes` (omit **`gateway`** if agents
should adjust models/config via the gateway tool). Turn off
**`tools.web.search`**; leave **`tools.web.fetch`** on. Set
**`tools.elevated.enabled: false`** so normal workspace **`exec`** works without
“elevated” gate errors. Set **`tools.exec.applyPatch.enabled: true`** if you
want **`apply_patch`** available.

**`exec failed: exec host=sandbox … sandbox runtime is unavailable` (K8s gateway)**  
OpenClaw defaults exec to the **sandbox** host; this image/pod has **no Docker
sandbox**. The model agrees to run commands then nothing useful happens. Set
**`tools.exec.host: "gateway"`** in `openclaw.json` so shell/exec runs on the
gateway pod (see `buddy_vault/backup/k8s_openclaw.json`).

**Heartbeat / scripts blocked (“exec approval required”)**  
Headless gateways have **no Control UI** to answer approval prompts. If policy
defaults to **allowlist** + **`ask: on-miss`**, **`askFallback: deny`** in
**`exec-approvals.json`** wins and runs never start. For a **single-user** pod
where you want **cron and scripts to run without prompts**, set
**`tools.exec.security: "full"`** and **`tools.exec.ask: "off"`** in
`openclaw.json` (see **`buddy_vault/backup/k8s_openclaw.json`**), plus
**`askFallback: "full"`** (and matching **`security` / `ask`**) under
**`defaults`** and **`agents.main`** in **`~/.openclaw/exec-approvals.json`**
only — **`askFallback` is not** a `tools.exec` key in current OpenClaw builds.

**Optional:** switch to **`coding`** once **`agents.defaults.memorySearch`**
is fully configured (embedding provider); otherwise leave memory off and accept
either **`full`** or occasional **`coding`** warnings.

**`read failed: ENOENT ... workspace/: 10` or paths containing `,`**  
Usually the model passed a **shell snippet or pipeline** as a single file path (e.g. `path | wc -l` pasted into `read`). Treat as bad tool arguments from the model, not RTK. Prefer `exec` for shell pipelines and `read` only for a single path.

**`linear-linear-sync.sh: not found`**  
There is no separate `linear-linear-sync.sh` in the kanban skill; the real script is `linear-kanban-workflow.sh`. Old prompts or hallucinations can call the wrong name. A small compatibility shim on the PVC can forward `sync-all` to `check-and-process`; prefer updating prompts to the path in `HEARTBEAT.md` and the skill.

## Cron jobs: Telegram `not-delivered`

**Symptom:** `cron runs` shows `deliveryStatus: "not-delivered"` or `delivered: false` even though `delivery.to` is set.

**Common cause:** The isolated run finished without a **final plain-text assistant message**. Reasoning-only or tool-only turns (no user-visible text) are not announced. Cron payloads should instruct the model to **always end with a short plain-text summary** when Telegram delivery is enabled.

**Not the bot token:** `TELEGRAM_BOT_TOKEN` is the **bot** credential. Scheduled delivery uses your **Telegram user/chat id** in `cron edit ... --to "..."` (Digits from `sendMessage ok chat=...` in logs, or your user id from pairing.)

**Duplicate jobs:** Two crons with the same schedule and task can run twice and confuse history; remove duplicates with `openclaw cron rm <id>`.

## Log inventory on the gateway pod

| Location | Purpose |
| --- | --- |
| `kubectl logs -n openclaw deploy/openclaw-gateway -c gateway` | Container stdout (recent entries; useful for crashes and startup). |
| `/tmp/openclaw/openclaw-YYYY-MM-DD.log` | Daily JSON-ish log file inside the container (good for grepping tool and agent errors). |

Example:

```bash
export KUBECONFIG=~/.kube/config-nas
kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- sh -lc 'ls -la /tmp/openclaw/; tail -50 /tmp/openclaw/openclaw-$(date -u +%F).log'
```

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
