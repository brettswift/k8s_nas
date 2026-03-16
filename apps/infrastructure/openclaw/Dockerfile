# Extend official OpenClaw image with vim, bat, and Python pip for terminal use and scripting.
FROM ghcr.io/openclaw/openclaw:2026.3.13-1

USER root
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    vim bat python3-pip python3-venv && \
  rm -rf /var/lib/apt/lists/*

# Install duckdb for time-series analytics (used by skills/time-series)
RUN pip3 install --break-system-packages duckdb

USER node
