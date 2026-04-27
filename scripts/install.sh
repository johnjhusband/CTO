#!/bin/bash
# CTO v1 Installation Script
# Installs OpenClaw + engram + MCPVault on Ubuntu 24.04 VPS
# Prerequisites: Node.js 22+ via nvm, dedicated 'cto' user
# Run as: cto user (non-root)
set -euo pipefail

echo "=== CTO v1 Installation Script ==="
echo ""

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Verify prerequisites
echo "--- Checking prerequisites ---"
node --version || { echo "FAIL: Node.js not found. Install nvm + Node 22 first."; exit 1; }
npm --version || { echo "FAIL: npm not found."; exit 1; }
python3 --version || { echo "FAIL: Python3 not found."; exit 1; }
echo "Prerequisites OK"
echo ""

# Install OpenClaw
echo "--- Installing OpenClaw ---"
if command -v openclaw &> /dev/null; then
    echo "OpenClaw already installed: $(openclaw --version)"
else
    npm install -g openclaw@latest
    echo "OpenClaw installed: $(openclaw --version)"
fi
echo ""

# Install engram
echo "--- Installing engram ---"
if command -v engram &> /dev/null; then
    echo "engram already installed: $(engram version)"
else
    ENGRAM_VERSION=$(curl -sI https://github.com/Gentleman-Programming/engram/releases/latest | grep -i '^location:' | grep -oP 'v[\d.]+' | head -1)
    echo "Latest engram version: $ENGRAM_VERSION"
    ENGRAM_URL="https://github.com/Gentleman-Programming/engram/releases/download/${ENGRAM_VERSION}/engram_${ENGRAM_VERSION#v}_linux_amd64.tar.gz"
    echo "Downloading from: $ENGRAM_URL"
    curl -L -o /tmp/engram.tar.gz "$ENGRAM_URL"
    tar -xzf /tmp/engram.tar.gz -C /tmp/
    # Install to user's local bin if no sudo, or /usr/local/bin with sudo
    if [ -w /usr/local/bin ]; then
        mv /tmp/engram /usr/local/bin/
    else
        mkdir -p "$HOME/.local/bin"
        mv /tmp/engram "$HOME/.local/bin/"
        export PATH="$HOME/.local/bin:$PATH"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    rm -f /tmp/engram.tar.gz
    engram version
    echo "engram installed"
fi
echo ""

# Install MCPVault
echo "--- Installing MCPVault ---"
npm list -g @bitbonsai/mcpvault &> /dev/null && echo "MCPVault already installed" || {
    npm install -g @bitbonsai/mcpvault@latest
    echo "MCPVault installed"
}
echo ""

# Install fetch MCP server (Python, via pip)
echo "--- Installing mcp-server-fetch ---"
if pip3 show mcp-server-fetch &> /dev/null 2>&1; then
    echo "mcp-server-fetch already installed"
else
    pip3 install --user mcp-server-fetch 2>/dev/null || {
        python3 -m venv "$HOME/.mcp-venv"
        "$HOME/.mcp-venv/bin/pip" install mcp-server-fetch
        echo "mcp-server-fetch installed in venv at ~/.mcp-venv"
    }
fi
echo ""

# Install GitHub MCP server (Go binary)
echo "--- Installing github-mcp-server ---"
if command -v github-mcp-server &> /dev/null; then
    echo "github-mcp-server already installed"
else
    GH_MCP_URL="https://github.com/github/github-mcp-server/releases/latest/download/github-mcp-server_linux_amd64.tar.gz"
    curl -L -o /tmp/gh-mcp.tar.gz "$GH_MCP_URL" 2>/dev/null
    if [ -s /tmp/gh-mcp.tar.gz ] && file /tmp/gh-mcp.tar.gz | grep -q gzip; then
        tar -xzf /tmp/gh-mcp.tar.gz -C /tmp/
        if [ -w /usr/local/bin ]; then
            mv /tmp/github-mcp-server /usr/local/bin/
        else
            mv /tmp/github-mcp-server "$HOME/.local/bin/"
        fi
        rm -f /tmp/gh-mcp.tar.gz
        echo "github-mcp-server installed"
    else
        echo "WARN: github-mcp-server download failed — install manually later"
        rm -f /tmp/gh-mcp.tar.gz
    fi
fi
echo ""

# Pull latest repo
echo "--- Syncing repo ---"
cd /opt/cto
git pull 2>/dev/null || echo "WARN: git pull failed — may need auth"
echo ""

# Write openclaw.json
echo "--- Configuring OpenClaw ---"
OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

# Load env vars from .env
if [ -f /opt/cto/.env ]; then
    set -a
    source /opt/cto/.env
    set +a
fi

cat > "$OPENCLAW_DIR/openclaw.json" << OCEOF
{
  "gateway": {
    "bind": "loopback",
    "auth": { "mode": "token" },
    "port": 18789
  },
  "skills": {
    "autoInstall": false
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN:-}",
      "dmPolicy": "allowlist",
      "allowFrom": ["tg:${TELEGRAM_USER_ID:-}"]
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/opt/cto",
      "skipBootstrap": true,
      "model": {
        "primary": "openrouter/anthropic/claude-sonnet-4",
        "fallbacks": ["openrouter/google/gemini-2.0-flash"]
      },
      "thinkingDefault": "adaptive",
      "heartbeat": {
        "every": "30m",
        "model": "openrouter/google/gemini-2.5-flash",
        "lightContext": true,
        "isolatedSession": true
      },
      "memorySearch": {
        "extraPaths": ["/opt/cto/wiki", "/opt/cto/logs/decisions"]
      }
    }
  },
  "mcp": {
    "servers": {
      "vault": {
        "command": "npx",
        "args": ["-y", "@bitbonsai/mcpvault@latest", "/opt/cto/wiki"]
      },
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/opt/cto"]
      },
      "engram": {
        "command": "engram",
        "args": ["mcp"]
      }
    }
  }
}
OCEOF

echo "openclaw.json written to $OPENCLAW_DIR/"
echo ""

# Set OpenRouter API key via auth profiles
echo "--- Configuring OpenRouter ---"
if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    # Write directly to auth profiles (avoids interactive paste-token prompt)
    AUTH_DIR="$OPENCLAW_DIR/auth-profiles"
    mkdir -p "$AUTH_DIR"
    python3 -c "
import json, os
auth_file = os.path.join('$AUTH_DIR', 'openrouter.json')
auth = {'provider': 'openrouter', 'method': 'api-key', 'token': '$OPENROUTER_API_KEY'}
with open(auth_file, 'w') as f:
    json.dump(auth, f)
os.chmod(auth_file, 0o600)
print('OpenRouter key written to auth profile')
"
    # Also set as env var in .openclaw/.env for the gateway
    echo "OPENROUTER_API_KEY=${OPENROUTER_API_KEY}" >> "$OPENCLAW_DIR/.env"
    chmod 600 "$OPENCLAW_DIR/.env"
    echo "OpenRouter key configured"
else
    echo "WARN: OPENROUTER_API_KEY not set in .env — run: openclaw models auth paste-token --provider openrouter"
fi
echo ""

# Disable Bonjour plugin (crashes on headless VPS — known issue #62652)
echo "--- Disabling Bonjour plugin ---"
python3 -c "
import json
with open('$OPENCLAW_DIR/openclaw.json') as f:
    d = json.load(f)
if 'plugins' not in d:
    d['plugins'] = {}
if 'entries' not in d['plugins']:
    d['plugins']['entries'] = {}
d['plugins']['entries']['bonjour'] = {'enabled': False}
# Remove invalid skills.autoInstall key if present
if 'skills' in d and 'autoInstall' in d.get('skills', {}):
    del d['skills']['autoInstall']
    if not d['skills']:
        del d['skills']
with open('$OPENCLAW_DIR/openclaw.json', 'w') as f:
    json.dump(d, f, indent=2)
print('Bonjour disabled, config cleaned')
"
echo ""

# Security hardening
echo "--- Security hardening ---"
chmod 600 "$OPENCLAW_DIR/openclaw.json"
echo "Config permissions set to 600"
echo ""

# Enable systemd lingering (gateway survives logout)
echo "--- Enabling systemd lingering ---"
sudo loginctl enable-linger $(whoami) 2>/dev/null && echo "Lingering enabled" || echo "WARN: Could not enable lingering — run 'sudo loginctl enable-linger cto' as root"
echo ""

# Install daemon
echo "--- Installing OpenClaw daemon ---"
openclaw onboard --non-interactive --install-daemon --skip-bootstrap --skip-health --workspace /opt/cto --accept-risk 2>&1 | tail -5
echo ""

# Verify
echo "--- Verification ---"
echo "OpenClaw: $(openclaw --version 2>/dev/null || echo 'NOT FOUND')"
echo "engram: $(engram version 2>/dev/null || echo 'NOT FOUND')"
echo "Node: $(node --version 2>/dev/null || echo 'NOT FOUND')"
echo "Python: $(python3 --version 2>/dev/null || echo 'NOT FOUND')"
echo ""

echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "1. Run 'openclaw doctor' to validate config"
echo "2. Run 'openclaw gateway run' to test (foreground)"
echo "3. Install daemon: 'openclaw onboard --install-daemon --skip-bootstrap'"
echo "4. John: message @HusbandCTObot on Telegram to enable proactive messaging"
echo "5. Add OpenRouter credits at openrouter.ai/settings/credits"
