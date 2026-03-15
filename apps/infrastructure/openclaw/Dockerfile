# Extend official OpenClaw image with vim and bat for terminal use (e.g. ArgoCD terminal).
FROM ghcr.io/openclaw/openclaw:main

USER root
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends vim bat && \
  rm -rf /var/lib/apt/lists/*
USER node
