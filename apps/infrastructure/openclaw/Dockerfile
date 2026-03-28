# Extend official OpenClaw image with vim, bat, Python pip, RTK CLI, and vendored RTK plugin.
# GitOps merges rtk-rewrite into openclaw.json and seeds the extension; see deployment.yaml
# and rtk-plugin/README.md.
FROM ghcr.io/openclaw/openclaw:2026.3.13-1

ARG RTK_VERSION=v0.33.1

USER root
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    vim bat python3-pip python3-venv curl ca-certificates && \
  rm -rf /var/lib/apt/lists/*

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
