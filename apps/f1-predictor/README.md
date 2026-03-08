# F1 Predictor

Local image only – no remote registry. Build on the cluster node.

## Build (on the node)

```bash
# From repo root
cd apps/f1-predictor
docker build -t f1-predictor:latest .
```

For k3s (containerd): import into k3s so the node can use it:

```bash
docker save f1-predictor:latest | sudo k3s ctr images import -
```

`imagePullPolicy: Never` – Kubernetes uses the locally cached image.
