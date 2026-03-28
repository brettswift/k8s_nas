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

For these IDs to work **without** running `openclaw pairing approve`, set
`channels.telegram.dmPolicy` to **`allowlist`** in `openclaw.json` (see
`buddy_workspace/backup/k8s_openclaw.json`). With **`pairing`**, unknown users
still need an approved pairing code even if this file exists.

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

## See also

- [FRESH_PVC_GUIDE.md](FRESH_PVC_GUIDE.md) — full fresh-PVC flow.
- [README.md](README.md) — secrets and `.env` on the PVC.
