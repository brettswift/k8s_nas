# OpenClaw: fresh or wiped PVC

This cluster already deploys OpenClaw via ArgoCD (`apps/infrastructure/openclaw`).
You do **not** need the upstream
[`deploy.sh` flow](https://docs.openclaw.ai/install/kubernetes); that guide targets
their sample manifests (ConfigMap-based config, port-forward-first). Here,
**PVC + secrets + ingress** are the source of truth.

Use this document after **deleting or replacing the OpenClaw PVC** while keeping
the same Deployment and namespace.

## How this differs from docs.openclaw.ai/kubernetes

| Upstream doc | This repo |
| --- | --- |
| `./scripts/k8s/deploy.sh` | ArgoCD sync of `apps/infrastructure/openclaw` |
| CM holds `openclaw.json` | PVC `~/.openclaw/`; optional Git file (Path A) |
| Loopback + port-forward | Ingress + gateway bind (see `deployment.yaml`) |
| Secret `openclaw-secrets` | Your secrets: gateway token, Telegram, etc. |

Official reference still helps for **gateway options** and **environment
variables**:
[Kubernetes](https://docs.openclaw.ai/install/kubernetes),
[Environment](https://docs.openclaw.ai/help/environment).

## Before you start

- **Kubernetes secrets** live in the namespace, not on the PVC. After a PVC
  wipe, confirm they still exist, for example:

  - `openclaw-gateway-token` — must match what you paste in the Control UI
    (**Settings → Auth**).
  - `openclaw-telegram-bot-token` (and any others you use, e.g. Home
    Assistant).

- **`KUBECONFIG`**: e.g. `export KUBECONFIG=~/.kube/config-nas` (see
  `docs/AI_GUIDANCE.md`).

- **Interactive wizard**: OpenClaw does not use a separate `openclaw onboard`
  command. The interactive flow is
  [`openclaw configure`](https://docs.openclaw.ai/cli/configure) (same as
  `openclaw config` with no subcommand).

## Path A — Git-tracked config + `.env` (recommended baseline)

Best when [`backup/k8s_openclaw.json`](../../../backup/k8s_openclaw.json) is how
you want the gateway to behave (no gateway tokens in Git; cluster uses the
secret).

1. **Copy the tracked config onto the PVC** (from your laptop, repo root):

   ```bash
   kubectl exec -n openclaw deploy/openclaw-gateway -c gateway -- \
     mkdir -p /home/node/.openclaw/backup
   cat backup/k8s_openclaw.json | kubectl exec -i -n openclaw \
     deploy/openclaw-gateway -c gateway -- \
     sh -c 'cat > /home/node/.openclaw/backup/k8s_openclaw.json'
   ```

2. **Symlink or replace `openclaw.json`**  
   If the init container already created `~/.openclaw/openclaw.json`, use the
   repo script (copy script into the pod, or run the same `mv` + `ln -s` steps
   as in
   [`backup/setup-openclaw-json-symlink.sh`](../../../backup/setup-openclaw-json-symlink.sh)).

3. **Create `~/.openclaw/.env`** on the PVC with provider API keys (Moonshot,
   OpenRouter, etc.). OpenClaw loads this automatically
   ([environment docs](https://docs.openclaw.ai/help/environment)). Use a
   password manager or rotated values — do not commit `.env`.

4. **Optional:** Restore **`credentials/`** (e.g. Telegram allowlists) and
   **`identity/`** (device keys) from an **encrypted** backup. If you skip this,
   expect to **re-pair** Telegram and get new device material.

5. **Restart the gateway** so it reads the new tree:

   ```bash
   kubectl delete pod -n openclaw -l app=openclaw-gateway
   ```

6. **Control UI**: Open the UI, paste the **gateway token** from the secret
   (same value as `OPENCLAW_GATEWAY_TOKEN` in the pod).

## Path B — `openclaw configure` (wizard)

Use when you want prompts for models, channels, gateway sections, etc.

Run **inside** the gateway container (PVC mounted at `/home/node`), with a TTY:

```bash
kubectl exec -it -n openclaw deploy/openclaw-gateway -c gateway -- \
  openclaw configure
```

Limit sections if you like
([configure CLI](https://docs.openclaw.ai/cli/configure)):

```bash
kubectl exec -it -n openclaw deploy/openclaw-gateway -c gateway -- \
  openclaw configure --section model --section channels
```

The wizard does **not** remove the need for **`~/.openclaw/.env`** (or other
provider setup) for API keys unless you configure everything through other
means.

**Practical combo:** Apply Path A first, then run `openclaw configure`
**only** for gaps (often **channels** / Telegram pairing).

## Closing gaps from an old backup export

If you have a private export (paths like `.env`, `credentials/*.json`,
`identity/*.json`):

- Treat any file that ever contained **live secrets** as **compromised**
  unless you have **rotated** those credentials.
- Recreate **`.env`** with current keys from a vault — do not paste long-lived
  secrets into Git.
- Restore **JSON state files** from an encrypted archive, or re-run pairing and
  accept new files.

## Smoke tests

- Ingress:
  `curl -sk https://openclaw.home.brettswift.com/healthz` →
  `{"ok":true,...}` (or your hostname).
- Pod:
  `kubectl logs -n openclaw deploy/openclaw-gateway -c gateway --tail=80` —
  look for `[gateway] listening`, `[telegram]` if enabled, and
  `[heartbeat] started`.
- Telegram: send a test message if the bot is configured.

## See also

- [README](README.md) — prerequisites, Control UI pairing, tools policy.
- [STATUS_AND_TROUBLESHOOTING.md](STATUS_AND_TROUBLESHOOTING.md) — token,
  tools, cron, logs.
