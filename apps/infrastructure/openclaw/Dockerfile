# Extend official OpenClaw image with vim, bat, and Python pip for terminal use and scripting.
# RTK CLI is installed for optional token-saving hooks; the OpenClaw plugin is NOT enabled
# via GitOps (no openclaw.json / PVC seeding). Plugin sources live in /opt/rtk-openclaw-plugin/
# for manual enable later. See rtk-plugin/README.md.
FROM ghcr.io/openclaw/openclaw:2026.3.13-1

ARG RTK_VERSION=v0.33.1

USER root
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    vim bat python3-pip python3-venv curl ca-certificates && \
  rm -rf /var/lib/apt/lists/*

COPY rtk-plugin/ /opt/rtk-openclaw-plugin/

RUN curl -fsSL "https://github.com/rtk-ai/rtk/releases/download/${RTK_VERSION}/rtk-x86_64-unknown-linux-musl.tar.gz" -o /tmp/rtk.tgz && \
  tar -xzf /tmp/rtk.tgz -C /usr/local/bin rtk && \
  chmod +x /usr/local/bin/rtk && \
  rm /tmp/rtk.tgz && \
  rtk --version

USER node
