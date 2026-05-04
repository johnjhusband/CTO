#!/bin/bash
# CTO v1 Installation Script
# Installs OpenClaw + engram + MCP servers on Ubuntu 24.04 VPS
#
# Prerequisites (must be done BEFORE running this script):
#   1. OpenRouter account with $5+ credits (openrouter.ai)
#   2. Telegram bot created via @BotFather (token ready)
#   3. Hetzner Cloud API token (console.hetzner.cloud)
#   4. .env file at /opt/cto/.env with:
#      OPENROUTER_API_KEY=sk-or-...
#      TELEGRAM_BOT_TOKEN=...
#      TELEGRAM_USER_ID=...
#      HETZNER_API_TOKEN=...
#      OPENAI_API_KEY=... (optional, for embeddings)
#   5. Dedicated non-root user (e.g., 'cto')
#   6. Node.js 22+ via nvm
#   7. Git repo cloned to /opt/cto
#
# Run as: cto user (non-root)
# Usage: bash /opt/cto/scripts/install.sh
#
# Learned from actual installation 2026-04-27:
#   - Bonjour plugin crashes on headless VPS (disable it)
#   - skills.autoInstall is not a valid config key (don't use it)
#   - auth-profiles.json uses "key" not "token" (breaking change 2026.2.19)
#   - auth-profiles.json needs "profiles" wrapper object and "id" field
#   - auth-profiles.json goes in ~/.openclaw/agents/main/agent/ (per-agent path)
#   - IPv6 causes Telegram connection delays (disable on VPS)
#   - OpenRouter model IDs must be exact (google/gemini-2.0-flash-001 not gemini-2.0-flash)
#   - OPENROUTER_API_KEY must also be in openclaw.json env section
#   - systemd lingering required for gateway to survive logout

set -euo pipefail

echo "=== CTO v1 Installation Script ==="
echo ""

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Update system packages
echo "--- Updating system packages ---"
sudo apt-get update -qq 2>/dev/null
sudo apt-get upgrade -y -qq 2>/dev/null || echo "WARN: apt upgrade had issues"
echo "System updated"
echo ""

# Verify prerequisites
echo "--- Checking prerequisites ---"
node --version || { echo "FAIL: Node.js not found."; exit 1; }
npm --version || { echo "FAIL: npm not found."; exit 1; }
python3 --version || { echo "FAIL: Python3 not found."; exit 1; }
[ -f /opt/cto/.env ] || { echo "FAIL: /opt/cto/.env not found."; exit 1; }

# Load env vars
set -a
source /opt/cto/.env
set +a

[ -n "${OPENROUTER_API_KEY:-}" ] || { echo "FAIL: OPENROUTER_API_KEY not set in .env"; exit 1; }
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] || { echo "FAIL: TELEGRAM_BOT_TOKEN not set in .env"; exit 1; }
[ -n "${TELEGRAM_USER_ID:-}" ] || { echo "FAIL: TELEGRAM_USER_ID not set in .env"; exit 1; }
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
    ENGRAM_URL="https://github.com/Gentleman-Programming/engram/releases/download/${ENGRAM_VERSION}/engram_${ENGRAM_VERSION#v}_linux_amd64.tar.gz"
    echo "Downloading engram ${ENGRAM_VERSION} from: ${ENGRAM_URL}"
    curl -L -o /tmp/engram.tar.gz "$ENGRAM_URL"
    tar -xzf /tmp/engram.tar.gz -C /tmp/
    mkdir -p "$HOME/.local/bin"
    mv /tmp/engram "$HOME/.local/bin/"
    export PATH="$HOME/.local/bin:$PATH"
    grep -q '.local/bin' "$HOME/.bashrc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    rm -f /tmp/engram.tar.gz
    echo "engram installed: $(engram version)"
fi
echo ""

# Install MCPVault
echo "--- Installing MCPVault ---"
npm list -g @bitbonsai/mcpvault &> /dev/null && echo "MCPVault already installed" || {
    npm install -g @bitbonsai/mcpvault@latest
    echo "MCPVault installed"
}
echo ""

# Install Python venv (required for mcp-server-fetch)
echo "--- Installing Python dependencies ---"
sudo apt-get update -qq 2>/dev/null
sudo apt-get install -y -qq python3.12-venv 2>/dev/null || echo "WARN: Could not install python3.12-venv"
echo ""

# Install mcp-server-fetch (Python)
echo "--- Installing mcp-server-fetch ---"
if python3 -c "import mcp_server_fetch" 2>/dev/null; then
    echo "mcp-server-fetch already installed"
else
    pip3 install --user mcp-server-fetch 2>/dev/null || {
        python3 -m venv "$HOME/.mcp-venv"
        "$HOME/.mcp-venv/bin/pip" install mcp-server-fetch
    }
    echo "mcp-server-fetch installed"
fi
echo ""

# Set up SSH deploy key for GitHub (so CTO can git pull on its own)
echo "--- Setting up GitHub deploy key ---"
if [ -f "$HOME/.ssh/github-deploy" ]; then
    echo "Deploy key already exists"
else
    ssh-keygen -t ed25519 -C "cto-vps-deploy" -f "$HOME/.ssh/github-deploy" -N ""
    cat > "$HOME/.ssh/config" << SSHEOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github-deploy
    IdentitiesOnly yes
SSHEOF
    chmod 600 "$HOME/.ssh/config"
    ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
    echo ""
    echo "IMPORTANT: Add this deploy key to GitHub repo settings:"
    echo "  Repository → Settings → Deploy keys → Add deploy key"
    echo "  Title: cto-vps-deploy"
    echo "  Key:"
    cat "$HOME/.ssh/github-deploy.pub"
    echo ""
    echo "Or run: gh repo deploy-key add ~/.ssh/github-deploy.pub -R johnjhusband/CTO --title cto-vps-deploy"
fi
# Switch git remote to SSH
cd /opt/cto && git remote set-url origin git@github.com:johnjhusband/CTO.git 2>/dev/null
echo ""

# Write openclaw.json
# Sources: OpenClaw docs, OpenRouter integration guide, GitHub issues #17191, #21448
echo "--- Writing openclaw.json ---"
OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

cat > "$OPENCLAW_DIR/openclaw.json" << OCEOF
{
  "env": {
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
    "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN:-}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY:-}",
    "TELEGRAM_BOT_TOKEN": "${TELEGRAM_BOT_TOKEN}",
    "TELEGRAM_USER_ID": "${TELEGRAM_USER_ID}"
  },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": { "mode": "token" },
    "port": 18789
  },
  "plugins": {
    "entries": {
      "bonjour": { "enabled": false }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["tg:${TELEGRAM_USER_ID}"]
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/opt/cto",
      "skipBootstrap": true,
      "sandbox": {
        "mode": "off"
      },
      "model": {
        "primary": "openrouter/openrouter/auto",
        "fallbacks": ["openrouter/google/gemini-2.5-flash"]
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
chmod 600 "$OPENCLAW_DIR/openclaw.json"
echo "openclaw.json written"
echo ""

# Write auth-profiles.json (per-agent path)
# Source: GitHub issue #21448 — uses "key" not "token" since 2026.2.19
echo "--- Writing auth profiles ---"
AGENT_DIR="$OPENCLAW_DIR/agents/main/agent"
mkdir -p "$AGENT_DIR"
cat > "$AGENT_DIR/auth-profiles.json" << AUTHEOF
{
  "profiles": [
    {
      "id": "openrouter-default",
      "type": "api-key",
      "provider": "openrouter",
      "key": "${OPENROUTER_API_KEY}"
    }
  ]
}
AUTHEOF
chmod 600 "$AGENT_DIR/auth-profiles.json"
# Also copy to root openclaw dir
cp "$AGENT_DIR/auth-profiles.json" "$OPENCLAW_DIR/auth-profiles.json"
chmod 600 "$OPENCLAW_DIR/auth-profiles.json"
echo "Auth profiles written (key field, profiles wrapper, per-agent path)"
echo ""

# Install daemon
echo "--- Installing OpenClaw daemon ---"
openclaw onboard --non-interactive \
    --install-daemon \
    --skip-bootstrap \
    --skip-health \
    --workspace /opt/cto \
    --accept-risk 2>&1 | tail -5 || echo "WARN: onboard had issues — check openclaw doctor"
echo ""

# Enable systemd lingering
echo "--- Enabling systemd lingering ---"
sudo loginctl enable-linger "$(whoami)" 2>/dev/null && echo "Lingering enabled" || echo "WARN: Run 'sudo loginctl enable-linger cto' as root"
echo ""

# Re-write openclaw.json (onboard may have overwritten it)
echo "--- Re-applying config (onboard may have overwritten) ---"
cat > "$OPENCLAW_DIR/openclaw.json" << OCEOF2
{
  "env": {
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
    "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN:-}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY:-}",
    "TELEGRAM_BOT_TOKEN": "${TELEGRAM_BOT_TOKEN}",
    "TELEGRAM_USER_ID": "${TELEGRAM_USER_ID}"
  },
  "gateway": {
    "mode": "local",
    "bind": "loopback",
    "auth": { "mode": "token" },
    "port": 18789
  },
  "plugins": {
    "entries": {
      "bonjour": { "enabled": false }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["tg:${TELEGRAM_USER_ID}"]
    }
  },
  "agents": {
    "defaults": {
      "workspace": "/opt/cto",
      "skipBootstrap": true,
      "sandbox": {
        "mode": "off"
      },
      "model": {
        "primary": "openrouter/openrouter/auto",
        "fallbacks": ["openrouter/google/gemini-2.5-flash"]
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
OCEOF2
chmod 600 "$OPENCLAW_DIR/openclaw.json"
echo "Config re-applied"
echo ""

# Generate gateway token (preserve if onboard created one)
echo "--- Gateway token ---"
if grep -q '"token"' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null; then
    echo "Gateway token exists (from onboard)"
else
    openclaw doctor --generate-gateway-token 2>/dev/null || echo "WARN: Run openclaw doctor to generate gateway token"
fi
echo ""

# Start gateway
echo "--- Starting gateway ---"
systemctl --user daemon-reload
systemctl --user restart openclaw-gateway
sleep 15
systemctl --user status openclaw-gateway --no-pager | head -5
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
echo "IMPORTANT: John must message @HusbandCTObot on Telegram first"
echo "to enable proactive messaging (known Telegram Bot API requirement)."
echo ""
echo "Post-install checks:"
echo "  openclaw doctor"
echo "  openclaw gateway status"
echo "  systemctl --user status openclaw-gateway"
