# OpenClaw on Kubernetes

[OpenClaw](https://openclaw.ai) runs as a pod in this cluster. This is a starter setup; you can move it to a Mac mini later and run it there (native or Docker).

## Prerequisites

- **Gateway token**: The secret supplies the token to the gateway (server-side). The Control UI runs in the browser and cannot read cluster secrets, so you must paste the same token in Settings → Auth. If you don’t have a token yet, generate one and create the secret:

```bash
# Generate a token (e.g. 32 bytes hex)
export TOKEN=$(openssl rand -hex 32)

# Create the secret in the openclaw namespace
kubectl create secret generic openclaw-gateway-token \
  --namespace openclaw \
  --from-literal=token="$TOKEN"
```

Then open the Control UI (see below), go to Settings, and paste this token.

- **Anthropic API key** (for chat): The agent needs an Anthropic API key to power the Control UI chat. Create the secret:

```bash
kubectl create secret generic openclaw-anthropic-api-key \
  --namespace openclaw \
  --from-literal=api-key="sk-ant-api03-YOUR_KEY_HERE"
```

Replace `YOUR_KEY_HERE` with your key from [Anthropic Console](https://console.anthropic.com/). Restart the gateway pod after creating the secret.

- **Optional**: Run the OpenClaw onboarding wizard once to create config and workspace under the PVC. You can do that by running the CLI image as a one-off job with the same PVC, or complete setup via the Control UI after the gateway is up.

## URLs

- **Control UI**: https://openclaw.home.brettswift.com
- **Docs**: https://docs.openclaw.ai

## Telegram

Use a Telegram bot so you can chat with OpenClaw from your phone. Default is **pairing**: only people you approve can DM the bot.

### 1. Create the bot and get the token

1. In Telegram, open a chat with **@BotFather** (official, check the handle).
2. Send: `/newbot`
3. Follow the prompts: choose a **name** (e.g. "My OpenClaw") and a **username** ending in `bot` (e.g. `my_openclaw_bot`). Must be unique.
4. BotFather replies with a token like `123456789:ABCdefGHI...`. Copy and save it.

### 2. Store the token in the cluster

Create a Kubernetes secret (do not commit the token):

```bash
kubectl create secret generic openclaw-telegram-bot-token \
  --namespace openclaw \
  --from-literal=token="YOUR_BOT_TOKEN_FROM_BOTFATHER"
```

The deployment already has an optional `TELEGRAM_BOT_TOKEN` env that reads this secret.

### 3. Enable Telegram in config

In the Control UI: **Settings → Config → Raw**, merge this into `openclaw.json`:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing",
      "groups": { "*": { "requireMention": true } }
    }
  }
}
```

- **`dmPolicy: "pairing"`** – New users get a one-time code; you approve them (see step 5).
- Omit `botToken` in config when using the secret; the gateway uses `TELEGRAM_BOT_TOKEN` from the env.

Click **Apply**. The gateway will restart and load Telegram.

### 4. Open a chat with your bot

In Telegram, search for your bot by its username (e.g. `@my_openclaw_bot`) and send any message (e.g. "Hi"). The bot will reply that pairing is required and show a **pairing code**.

### 5. Approve the pairing (from your machine)

List pending Telegram pairings:

```bash
export KUBECONFIG=~/.kube/config-nas
kubectl exec -n openclaw deploy/openclaw-gateway -- node dist/index.js pairing list telegram
```

Approve using the code the user (or you) received in Telegram:

```bash
kubectl exec -n openclaw deploy/openclaw-gateway -- node dist/index.js pairing approve telegram <CODE>
```

After approval, that Telegram user can DM the bot and chat with OpenClaw.

### 6. Optional: allow a specific user without pairing

To allow a Telegram user by ID (no pairing):

1. Get your Telegram user ID (e.g. DM the bot once and read logs, or use a helper bot; see OpenClaw Telegram docs).
2. In config, set `dmPolicy: "allowlist"` and add your ID:

```json
"channels": {
  "telegram": {
    "enabled": true,
    "dmPolicy": "allowlist",
    "allowFrom": ["YOUR_TELEGRAM_USER_ID"],
    "groups": { "*": { "requireMention": true } }
  }
}
```

### 7. Optional: groups

To use the bot in groups, add it to the group in Telegram. By default the bot only replies when **mentioned** (e.g. `@my_openclaw_bot`). To change that, configure `channels.telegram.groups` (see [OpenClaw Telegram docs](https://docs.openclaw.ai/channels/telegram)).

## Skills (e.g. Home Assistant)

Skills teach OpenClaw how to use tools (e.g. talk to Home Assistant). You can install them from the Control UI or via ClawHub.

### Option 1: Control UI (manage only)

The Control UI **Settings → Skills** tab lists already-installed/bundled skills. You can enable/disable them and set API keys there. It does **not** search or install from ClawHub; use the CLI (Option 2) to install new skills.

### Option 2: Home Assistant skill via ClawHub (CLI in pod)

You need a **Home Assistant URL** and a **long-lived access token** (Home Assistant → Profile → Security → Long-Lived Access Tokens).

Create a Kubernetes secret for the Home Assistant token (recommended for UI-safe config editing):

```bash
kubectl create secret generic openclaw-home-assistant-token \
  --namespace openclaw \
  --from-literal=token="YOUR_LONG_LIVED_TOKEN"
```

The deployment reads this secret into the `HA_TOKEN` environment variable.

**Install the skill into the gateway’s data:**

```bash
./scripts/openclaw-install-skill.sh home-assistant
# or any slug: ./scripts/openclaw-install-skill.sh weather
```

(If you see “Rate limit exceeded”, wait 10–15 minutes and retry.) To find slugs: `clawhub search "home assistant"` in a one-off node pod.

**Configure the skill** in OpenClaw (Control UI → Config → Raw). Add under `skills.entries`:

```json
"skills": {
  "entries": {
    "home-assistant": {
      "enabled": true,
      "env": {
        "HA_URL": "http://YOUR_HA_HOST:8123",
        "HA_TOKEN": "${HA_TOKEN}"
      }
    }
  }
}
```

Use your real Home Assistant URL (e.g. `http://10.1.0.20:8123` if HA runs on the same host, or your HA hostname). Keep `HA_TOKEN` as `${HA_TOKEN}` in config so UI edits stay portable and do not write secrets to disk. Restart the gateway after config changes so the skill is loaded.

The one-off pod mounts the same PVC as the gateway; `--workdir /data/workspace` makes the skill land in `workspace/skills`, which OpenClaw loads. Restart the gateway (or start a new session) after installing.

## Tool profile: safe but powerful (research)

To let the bot **research** (web search, fetch pages, remember things) and **do useful things** (send messages, use sessions, optional browser) without **dangerous** tools (no shell exec, no file read/write, no gateway restart, no node control), use a profile above `minimal` and deny the risky groups.

Merge this into your config (Settings → Config → Raw, then Apply):

```json
{
  "tools": {
    "profile": "messaging",
    "allow": [
      "group:web",
      "group:memory",
      "image"
    ],
    "deny": [
      "group:runtime",
      "group:fs",
      "group:automation",
      "group:nodes",
      "browser",
      "canvas"
    ],
    "web": {
      "search": {
        "enabled": true
      },
      "fetch": {
        "enabled": true
      }
    }
  }
}
```

The **green web-search control** in the UI often only enables when a Brave Search API key is present. Set it via env (recommended): create a secret and add it to the deployment:

```bash
kubectl create secret generic openclaw-brave-api-key -n openclaw --from-literal=api-key="YOUR_BRAVE_KEY"
```

The deployment already has optional `BRAVE_API_KEY` from secret `openclaw-brave-api-key`. After creating the secret, restart the gateway so web search (and the UI control) work. Key from [Brave Search API](https://brave.com/search/api/) (Data for Search plan).

**What this gives:**

| Allowed | Purpose |
| --- | --- |
| `group:messaging` + session tools | Send messages, list/send to sessions, session_status |
| `group:web` | `web_search`, `web_fetch` (research) |
| `group:memory` | `memory_search`, `memory_get` (remember across chats) |
| `image` | Analyze images with the image model |

**What’s denied:**

| Denied | Reason |
| --- | --- |
| `group:runtime` | `exec`, `process` (no shell commands) |
| `group:fs` | `read`, `write`, `edit`, `apply_patch` (no file access) |
| `group:automation` | `cron`, `gateway` (no cron, no config/restart) |
| `group:nodes` | No paired-node control (camera, run, etc.) |
| `browser`, `canvas` | No browser automation or Canvas (remove from `deny` if you want research via browser) |

**Web tools:** `web_fetch` works without a key. `web_search` requires a Brave API key (`BRAVE_API_KEY` env or `tools.web.search.apiKey`); see [Brave Search](https://docs.openclaw.ai/brave-search).

To allow the **browser** for research (e.g. JS-heavy sites), remove `"browser"` from the `deny` array. To allow **file read-only** in the workspace, you could switch to `profile: "coding"` and `deny: ["group:runtime", "write", "edit", "apply_patch", "group:automation", "group:nodes", "browser", "canvas"]` so only `read` is allowed.

## Local models on the host (GPU)

OpenClaw runs in a pod; the model server must run on the **host** (the k8s node at 10.1.0.20) so it can use the GPU. The pod reaches the host via the node IP.

### 1. Install Ollama on the host

SSH to the host and install Ollama:

```bash
ssh nas   # or ssh bswift@10.1.0.20

# Install Ollama (Linux)
curl -fsSL https://ollama.com/install.sh | sh

# Expose on all interfaces so the pod can reach it (required)
export OLLAMA_HOST=0.0.0.0
# Make persistent: add to ~/.bashrc or create /etc/systemd/system/ollama.service.d/override.conf
```

For a systemd-managed Ollama service:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
echo -e '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0"' | sudo tee /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 2. Pull models and use GPU

Ollama uses the GPU automatically when available. Pull models on the host:

```bash
ollama pull llama3.2
ollama pull mistral
# List: ollama list
```

### 3. Wire OpenClaw to the host’s Ollama

The pod must use the **host IP** (10.1.0.20), not `localhost`.

**In the Control UI:**

1. Open https://openclaw.home.brettswift.com
2. In the left sidebar, expand **Settings** (click the chevron if collapsed)
3. Click **Config**
4. Click the **Raw** button (top of the config area) to switch from Form view to raw JSON
5. Merge the JSON below into the existing config in the **Raw JSON5** editor. If the file is empty or minimal, paste this as the full config. If you already have `models` or `agents` sections, merge the `providers` and `fallbacks` into them.
6. Click **Apply** to save and restart the gateway with the new config.

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "ollama-host": {
        "baseUrl": "http://10.1.0.20:11434/v1",
        "apiKey": "ollama",
        "api": "openai-responses",
        "models": [
          {
            "id": "llama3.2",
            "name": "Llama 3.2 (Host GPU)",
            "reasoning": false,
            "input": ["text"],
            "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
            "contextWindow": 128000,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-sonnet-4-5",
        "fallbacks": ["ollama-host/llama3.2", "anthropic/claude-opus-4-6"]
      }
    }
  }
}
```

Adjust `id` to match your `ollama list` output. Use `models.mode: "merge"` so hosted models stay as fallbacks.

### 4. Alternatives: vLLM, LM Studio

- **vLLM** (best performance): Run on host, bind to `0.0.0.0:8000`, use `baseUrl: "http://10.1.0.20:8000/v1"`.
- **LM Studio**: Run on host, enable local server (default port 1234), use `baseUrl: "http://10.1.0.20:1234/v1"`.

## Moving to Mac mini later

- **Option A**: Copy the PVC contents (e.g. via a temporary pod that mounts the PVC and streams a tarball, or backup/restore). Then run OpenClaw on the Mac (native install or Docker) and point it at the same config/workspace.
- **Option B**: Run `openclaw onboard` on the Mac and reconfigure channels/skills there. Use the same gateway token if you want to reuse the same “instance” identity.

## Config UI: can't save

If **Apply** in Settings → Config doesn’t persist (e.g. with tool presets set to **minimal** or after editing the form):

1. **Use Raw JSON** – Switch to **Settings → Config → Raw** and click **Apply** from there. The form view can sometimes send a payload the gateway rejects; Raw applies your JSON directly.
2. **Fix redacted values** – If the Raw editor shows `__OPENCLAW_REDACTED__` or `__OPENCLAW_REDACTED__-host`, replace them with real values (e.g. `ollama`, `ollama-host`, or your model ref) before saving, or the gateway may reject or mis-load the config.
3. **Rate limit** – Config apply is limited to 3 requests per 60 seconds. If save seems to do nothing, wait a minute and try again.
4. **Edit on the pod** – If the UI still won’t save, edit the config file on the gateway and restart:

```bash
export KUBECONFIG=~/.kube/config-nas

# Dump current config
kubectl exec -n openclaw deploy/openclaw-gateway -- cat /home/node/.openclaw/openclaw.json > /tmp/openclaw.json

# Edit /tmp/openclaw.json locally, then push it back (replace <pod-name> with the actual pod name)
kubectl cp /tmp/openclaw.json openclaw/$(kubectl get pod -n openclaw -l app=openclaw-gateway -o jsonpath='{.items[0].metadata.name}'):/home/node/.openclaw/openclaw.json

# Restart so the gateway picks up the file
kubectl rollout restart deployment/openclaw-gateway -n openclaw
```

## GitOps

This app is part of the **infrastructure** ArgoCD Application. When you push this branch to `live`, ArgoCD will sync the openclaw namespace, PVC, deployment, service, and ingress. Do not apply these manifests with `kubectl apply`; use Git + ArgoCD only.
