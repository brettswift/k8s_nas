#!/usr/bin/env sh
# Move the live OpenClaw config aside and replace openclaw.json with a symlink
# to backup/k8s_openclaw.json under the state directory (typically ~/.openclaw).
#
# On the gateway pod, copy backup/k8s_openclaw.json from the buddy_vault
# repo into /home/node/.openclaw/backup/k8s_openclaw.json, then run:
#   OPENCLAW_STATE_DIR=/home/node/.openclaw sh setup-openclaw-json-symlink.sh
#
# Canonical file: buddy_vault/backup/k8s_openclaw.json (gateway tokens
# stripped; cluster uses openclaw-gateway-token / OPENCLAW_GATEWAY_TOKEN).

set -eu

DIR="${OPENCLAW_STATE_DIR:-${HOME}/.openclaw}"
TARGET_REL="backup/k8s_openclaw.json"
BAK_NAME="openclaw.json_bak_initial_simlink_setup"

cd "$DIR"

if [ -L openclaw.json ]; then
  echo "openclaw.json is already a symlink ($(readlink openclaw.json)); aborting" >&2
  exit 1
fi

if [ ! -f "$TARGET_REL" ]; then
  echo "missing ${DIR}/${TARGET_REL} — copy buddy_vault/backup/k8s_openclaw.json here first" >&2
  exit 1
fi

if [ -f openclaw.json ]; then
  mv openclaw.json "$BAK_NAME"
  echo "saved previous config as ${DIR}/${BAK_NAME}"
fi

ln -sf "$TARGET_REL" openclaw.json
echo "openclaw.json -> ${TARGET_REL}"
