# RTK plugin (GitOps)

The gateway image includes the `rtk` binary. Kubernetes seeds this plugin into
`~/.openclaw/extensions/rtk-rewrite/` from a ConfigMap and merges
`plugins.entries.rtk-rewrite` into `openclaw.json` on each pod start (idempotent).

To disable without removing the image, set `"enabled": false` under
`plugins.entries.rtk-rewrite` in `openclaw.json` on the PVC, or remove that
entry and delete the extension directory.

Upstream: [rtk-ai/rtk/openclaw](https://github.com/rtk-ai/rtk/tree/master/openclaw).
