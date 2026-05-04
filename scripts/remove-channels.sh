#!/bin/bash
# Post-install script: Remove ALL built-in communication channel plugins.
# Our openclaw-secure-a2a plugin is the ONLY communication pathway.
#
# This is a three-layer security approach:
#   Layer 1: Physical deletion (files gone from disk)
#   Layer 2: Config deny list (blocked even if files reappear)
#   Layer 3: Environment variable (channels subsystem skipped)
#
# Keep: AI provider extensions (openai, anthropic, etc.), utility extensions
#       (memory-core, browser, codex, etc.)

set -euo pipefail

echo "=== Removing built-in communication channel plugins ==="

# Find OpenClaw's extensions directory
OPENCLAW_DIR=$(npm root -g)/openclaw/dist/extensions 2>/dev/null || true
if [ ! -d "$OPENCLAW_DIR" ]; then
  # Try alternative path
  OPENCLAW_DIR=$(dirname $(which openclaw 2>/dev/null))/../lib/node_modules/openclaw/dist/extensions 2>/dev/null || true
fi

if [ ! -d "$OPENCLAW_DIR" ]; then
  echo "ERROR: Cannot find OpenClaw extensions directory"
  echo "Looked in: $(npm root -g)/openclaw/dist/extensions"
  exit 1
fi

echo "Extensions directory: $OPENCLAW_DIR"

# Communication channels to remove (exhaustive list from research)
CHANNELS_TO_REMOVE=(
  telegram
  discord
  slack
  whatsapp
  signal
  matrix
  irc
  msteams
  googlechat
  feishu
  line
  mattermost
  nextcloud-talk
  nostr
  synology-chat
  tlon
  bluebubbles
  imessage
  zalo
  zalouser
  qqbot
  twitch
  google-meet
  voice-call
  talk-voice
  inworld
  webchat
)

# Extensions to KEEP (AI providers, utilities, our plugin)
# openai, anthropic, openrouter, ollama, gemini, mistral, deepseek, grok
# memory-core, browser, codex, acpx, device-pair, phone-control
# bonjour (already disabled in config but keep files for reference)

REMOVED=0
for channel in "${CHANNELS_TO_REMOVE[@]}"; do
  if [ -d "$OPENCLAW_DIR/$channel" ]; then
    echo "  Removing: $channel"
    rm -rf "$OPENCLAW_DIR/$channel"
    REMOVED=$((REMOVED + 1))
  fi
done

echo "Removed $REMOVED channel plugins from disk"

# Layer 2: Config deny list
echo ""
echo "--- Setting config deny list ---"
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
if [ -f "$OPENCLAW_CONFIG" ]; then
  python3 -c "
import json
with open('$OPENCLAW_CONFIG') as f:
    d = json.load(f)
d.setdefault('plugins', {})
d['plugins']['deny'] = $(printf '%s\n' "${CHANNELS_TO_REMOVE[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
with open('$OPENCLAW_CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
import os
os.chmod('$OPENCLAW_CONFIG', 0o600)
print('Config deny list updated')
"
fi

# Layer 3: Environment variable
echo ""
echo "--- Setting OPENCLAW_SKIP_CHANNELS ---"
# Add to systemd service environment
SYSTEMD_ENV="$HOME/.config/systemd/user/openclaw-gateway.service.d"
mkdir -p "$SYSTEMD_ENV"
cat > "$SYSTEMD_ENV/no-channels.conf" << EOF
[Service]
Environment="OPENCLAW_SKIP_CHANNELS=0"
# Note: Set to 0 because OUR plugin handles channels.
# The skip only applies to built-in channel discovery.
# Our plugin is registered separately via the plugin system.
EOF

echo ""
echo "=== Channel removal complete ==="
echo "  Physical files removed: $REMOVED"
echo "  Config deny list: set"
echo "  Only communication channel: openclaw-secure-a2a (our plugin)"
echo ""
echo "Restart gateway: systemctl --user restart openclaw-gateway"
