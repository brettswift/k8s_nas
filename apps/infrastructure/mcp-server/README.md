# MCP Server (Home Assistant)

This deploys a Home Assistant MCP server at `https://mcp.home.brettswift.com`.

## What this deployment does

- Runs `homeassistant-ai/ha-mcp` in namespace `mcp`
- Exposes it through NGINX Ingress on subdomain `mcp.home.brettswift.com`
- Uses in-cluster Home Assistant URL: `http://homeassistant.homeautomation.svc.cluster.local:8123`

## Required secret

Create a long-lived Home Assistant token secret in the `mcp` namespace:

```bash
export KUBECONFIG=~/.kube/config-nas
kubectl create secret generic mcp-homeassistant-token \
  --namespace mcp \
  --from-literal=token="YOUR_HOME_ASSISTANT_LONG_LIVED_TOKEN"
```

If the secret is missing, the MCP server pod can still start but Home Assistant tool calls will fail.

## OpenClaw connection notes

Use the remote MCP endpoint in OpenClaw:

- Base URL: `https://mcp.home.brettswift.com`
- MCP path: `https://mcp.home.brettswift.com/mcp`

If your OpenClaw MCP client expects SSE transport, switch this deployment command from `ha-mcp-web` to `ha-mcp-sse`.
