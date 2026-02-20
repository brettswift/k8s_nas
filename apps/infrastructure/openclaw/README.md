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

- **Optional**: Run the OpenClaw onboarding wizard once to create config and workspace under the PVC. You can do that by running the CLI image as a one-off job with the same PVC, or complete setup via the Control UI after the gateway is up.

## URLs

- **Control UI**: https://openclaw.home.brettswift.com
- **Docs**: https://docs.openclaw.ai

## Moving to Mac mini later

- **Option A**: Copy the PVC contents (e.g. via a temporary pod that mounts the PVC and streams a tarball, or backup/restore). Then run OpenClaw on the Mac (native install or Docker) and point it at the same config/workspace.
- **Option B**: Run `openclaw onboard` on the Mac and reconfigure channels/skills there. Use the same gateway token if you want to reuse the same “instance” identity.

## GitOps

This app is part of the **infrastructure** ArgoCD Application. When you push this branch to `live`, ArgoCD will sync the openclaw namespace, PVC, deployment, service, and ingress. Do not apply these manifests with `kubectl apply`; use Git + ArgoCD only.
