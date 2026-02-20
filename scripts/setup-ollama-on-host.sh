#!/usr/bin/env bash
# Setup Ollama on the k8s host (10.1.0.20) for OpenClaw local models.
#
# Run remotely: ssh nas 'bash -s' < scripts/setup-ollama-on-host.sh
# Or copy to host and run: scp scripts/setup-ollama-on-host.sh nas: && ssh nas ./setup-ollama-on-host.sh
# Add --pull-model to also pull llama3.2.

set -euo pipefail

echo "=== Ollama setup for OpenClaw host ==="

# 1. Install Ollama if missing
if ! command -v ollama &>/dev/null; then
  echo "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "Ollama already installed: $(ollama --version)"
fi

# 2. Configure OLLAMA_HOST=0.0.0.0 persistently (systemd override survives reboots)
echo "Configuring OLLAMA_HOST=0.0.0.0 (persistent via systemd override)..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '%s\n' '[Service]' 'Environment="OLLAMA_HOST=0.0.0.0"' | sudo tee /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl restart ollama
sudo systemctl enable ollama

# 3. Verify
echo ""
echo "Ollama status:"
systemctl is-active ollama
ollama --version
echo ""
echo "Listening on:"
ss -tlnp 2>/dev/null | grep 11434 || netstat -tlnp 2>/dev/null | grep 11434 || true

# 4. Optional: pull a default model (pass --pull-model to do this)
if [[ "${1:-}" == "--pull-model" ]]; then
  echo "Pulling llama3.2..."
  ollama pull llama3.2
  ollama list
fi

echo ""
echo "Done. Add ollama-host provider to OpenClaw config (baseUrl: http://10.1.0.20:11434/v1)"
echo "To pull a model later: ollama pull llama3.2"
