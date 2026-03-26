# RTK (optional)

The `rtk` binary is on `PATH`. OpenClaw **does not** load this plugin from GitOps:

- No `plugins.entries.rtk-rewrite` is added to `openclaw.json`.
- No files are copied into `~/.openclaw/extensions/` by Kubernetes.

To try the plugin later, copy from the image and enable in config (see [upstream](https://github.com/rtk-ai/rtk/blob/master/openclaw/README.md)):

```bash
kubectl exec -it -n openclaw deploy/openclaw-gateway -c gateway -- sh -lc '
  mkdir -p ~/.openclaw/extensions/rtk-rewrite &&
  cp /opt/rtk-openclaw-plugin/index.ts /opt/rtk-openclaw-plugin/openclaw.plugin.json ~/.openclaw/extensions/rtk-rewrite/
'
```

Then add the `rtk-rewrite` entry under `plugins.entries` in `~/.openclaw/openclaw.json` and restart the gateway.
