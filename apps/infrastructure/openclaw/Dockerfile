# Extend official OpenClaw image with vim, bat, Python pip, RTK CLI, and vendored RTK plugin.
# GitOps merges rtk-rewrite into openclaw.json and seeds the extension; see deployment.yaml
# and rtk-plugin/README.md.
# Pin OpenClaw release here; deployment.yaml uses the same tag on ghcr.io/brettswift/openclaw-gateway
# (see .github/workflows/build-openclaw-gateway.yml). Was 2026.3.23 (2026-03-23); bumped 2026-04-12.
FROM ghcr.io/openclaw/openclaw:2026.4.11

ARG RTK_VERSION=v0.33.1
# Pin client to cluster minor; bump when k3s upgrades.
ARG KUBECTL_VERSION=v1.31.6

USER root
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    vim bat python3-pip python3-venv curl ca-certificates && \
  rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
  install -m 0755 /tmp/kubectl /usr/local/bin/kubectl && \
  rm /tmp/kubectl && \
  kubectl version --client=true --output=yaml

# Debian package "bat" installs /usr/bin/batcat; expose as `bat` for muscle memory.
RUN if [ -x /usr/bin/batcat ]; then ln -sf /usr/bin/batcat /usr/local/bin/bat; fi

# Interactive shells (kubectl exec -it … bash): convenience aliases for node.
RUN printf '%s\n' \
  '' \
  '# openclaw-gateway image (k8s_nas)' \
  "alias l='ls -lah'" \
  "alias ll='ls -lah'" \
  >> /home/node/.bashrc && \
  chown node:node /home/node/.bashrc

COPY rtk-plugin/ /opt/rtk-openclaw-plugin/

RUN curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/${RTK_VERSION}/rtk-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rtk.tgz && \
  tar -xzf /tmp/rtk.tgz -C /usr/local/bin rtk && \
  chmod +x /usr/local/bin/rtk && \
  rm /tmp/rtk.tgz && \
  rtk --version

USER node
