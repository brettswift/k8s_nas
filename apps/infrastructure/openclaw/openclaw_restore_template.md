# OpenClaw PVC restore reference (no secrets)

Use this as a **checklist** when recreating `~/.openclaw` and `~/.ssh` on a new
PVC.

**Your real values:** keep a local copy (e.g. `openclaw_backup_config_mess.json`
in this folder — **gitignored**; never commit). This file is the safe, empty
template for sharing in Git.

## Omitted on purpose (per-server / regenerate)

- **`identity/device.json`** — device keypair; OpenClaw creates new material on
  setup.
- **`identity/device-auth.json`** — operator tokens; re-pair / re-auth after a
  fresh install.

Do not copy those from an old server unless you know you need identity
continuity.

## `~/.openclaw/.env`

Create on the PVC with your real values (names only shown here):

```bash
# Providers (examples — use your keys)
DEEPSEEK_API_KEY=
TELEGRAM_BOT_TOKEN=
# Optional: numeric user id for DM pings (linear-kanban telegram_workflow_notify.py)
TELEGRAM_NOTIFY_CHAT_ID=
MOONSHOT_API_KEY=
MOLTBOOK_API_KEY=
HOMEASSISTANT_TOKEN=
PAYPAL_PASSWORD=
LINEAR_API_KEY=
OPENROUTER_API_KEY=

# Memory search (`memory-core`): `k8s_openclaw.json` uses provider `openai` with
# `remote.baseUrl` OpenRouter. The adapter reads **`OPENAI_API_KEY`** — set it to
# the same value as **`OPENROUTER_API_KEY`** unless you use a real OpenAI key for
# embeddings. Without this, status shows memory as unavailable.

OPENAI_API_KEY=

# Git over SSH from the gateway pod
GIT_SSH_COMMAND="ssh -F /home/node/.ssh/config"

# Optional: Google OAuth (if you use Gmail/Calendar integrations)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_PROJECT_ID=

# Optional: GitHub PAT for gh / API
GH_TOKEN=

# Optional: compare URL for kanban batch-ready Telegram ping (per project)
# KANBAN_BATCH_COMPARE_URL=https://github.com/org/repo/compare/live...feat/my-branch
# KANBAN_INTEGRATION_BRANCH=dev
```

## `~/.openclaw/credentials/telegram-default-allowFrom.json`

After you know your Telegram user id (from pairing / logs), list allowed DMs here.

For **`allowlist`**, OpenClaw also requires **`channels.telegram.allowFrom`**
in **`openclaw.json`** with at least one numeric sender id (same values as
here). The credentials file alone is not enough for config validation.

Set `channels.telegram.dmPolicy` to **`allowlist`** in `openclaw.json` (see
`buddy_vault/backup/k8s_openclaw.json`). With **`pairing`**, unknown users
still need an approved pairing code even if this file exists.

### Telegram groups (`groupPolicy` / `groupAllowFrom`)

To clear **`openclaw security audit`** criticals about **`groupPolicy="open"`**,
set **`channels.telegram.groupPolicy`** to **`allowlist`** and list allowed
supergroup chat ids in **`channels.telegram.groupAllowFrom`** (strings; supergroup
ids are usually negative, e.g. `"-1001234567890"`). An **empty** list means the bot
ignores **all** groups until you add ids (DM allowlist is unchanged).

Optional: set **`channels.defaults.groupPolicy`** to **`allowlist`** so other
channel types default the same way.

```json
{
  "version": 1,
  "allowFrom": ["YOUR_TELEGRAM_USER_ID"]
}
```

## `~/.openclaw/credentials/telegram-pairing.json`

Usually starts empty; the gateway manages pairing requests.

```json
{
  "version": 1,
  "requests": []
}
```

## `~/.ssh/config` (on PVC at `/home/node/.ssh/config`)

```text
Host github.com
  IdentityFile /home/node/.ssh/id_ed25519
  IdentitiesOnly yes
```

## `~/.ssh/id_ed25519` (private key)

**Never commit this file.** Keep the private key in a vault; copy onto the PVC
with `kubectl cp` or an editor, mode `600`, owner the gateway user (`node`).

### Mode 0640 on the gateway pod (chmod “does not persist”)

The gateway Deployment’s `ensure-workspace-perms` init container runs a recursive
`chmod` that adds group-read on `/data`, then **re-tightens SSH private keys** by
scanning `/data/.ssh` for PEM / `BEGIN … PRIVATE KEY` headers and `chmod 600`
those files. You should not need to fix keys by hand after restarts.

OpenSSH requires private keys **not** be readable by group or other (`0600` only).
If you see **Permissions 0640 … are too open**, the usual cause on Kubernetes is
**`pod.spec.securityContext.fsGroup`** (or similar volume ownership): the kubelet
recursively adjusts the PVC so the supplemental group can read files, which sets
**group-readable** bits (`0640`). That satisfies the volume but breaks SSH.

Manual `chmod 0600` inside the pod can be **undone on the next pod restart** when
the kubelet reapplies volume ownership, which looks like “chmod does not persist
on the PVC.”

**Fix (pick one):**

1. **Init container (simplest with an existing key on the PVC)** — run as UID 0
   once per start and tighten modes after the volume is mounted. See
   `openclaw-gateway-ssh-perms-init.snippet.yaml` in this folder for a copy-paste
   block (set the volume name and `mountPath` to match your Deployment).

2. **Mount the key from a `Secret`** with `defaultMode: 0600` (`384` decimal) and
   optionally `subPath` — permissions stay correct without relying on PVC bits.
   Same snippet file shows an example `volumes` / `volumeMounts` shape.

3. **Remove `fsGroup`** from the pod if nothing else on the PVC needs group-writable
   dirs — only do this if you understand the tradeoff for other files under
   `/home/node`.

If your namespace enforces restricted Pod Security and blocks `runAsUser: 0` on
the init container, use the **Secret mount** approach or ask for an exemption for
that init only.

## `~/.ssh/id_ed25519.pub` (public key — safe to keep in Git as reference)

Register this deploy key in GitHub (or your Git host) for repos the gateway
should clone.

```text
ssh-ed25519 AAAA...comment node@your-gateway
```

Replace `AAAA...` with your real public line from `ssh-keygen -y -f id_ed25519`
or from the host where the key was generated.

## `~/.ssh/known_hosts` (optional)

You can let SSH populate this on first connect, or copy a minimal set for
`github.com` from a trusted machine. Example line shape:

```text
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...
```

## `plugins.allow` (extensions you trust)

Bundled core plugins (model providers, etc.) ship with the image; you do not list
every one. Set **`plugins.allow`** to the **plugin ids** of workspace extensions
you deliberately load from `~/.openclaw/extensions/` (e.g. **`rtk-rewrite`**),
and mirror them under **`plugins.entries.<id>.enabled`**. Run
`openclaw plugins list` on the gateway pod to confirm ids. **`gateway`** is not
a plugin id here.

## See also

- `openclaw-gateway-ssh-perms-init.snippet.yaml` — initContainer / Secret examples
  for correct SSH key modes on Kubernetes.
