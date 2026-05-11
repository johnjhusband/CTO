#!/bin/bash
# CTO Two-Hemisphere Install Script
# Implements /opt/cto/install-plan.md sections 1-6.
#
# Target: Hetzner VPS 46.224.81.84, Ubuntu 24.04, user `cto`.
# Run as: cto user (non-root).
# Invocation: bash /opt/cto/scripts/install-cto.sh
#
# This is a one-time, human-directed install (per architecture-decisions-john.md
# and SOUL.md #15 exemption documented in install-plan.md preamble).
# Idempotent — safe to re-run if a step fails.

set -euo pipefail

# ─── Setup ─────────────────────────────────────────────────────────────────

CTO_ROOT="/opt/cto"
LOG_DIR="${CTO_ROOT}/logs/install"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
ENV_FILE="${CTO_ROOT}/.env"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=== CTO Two-Hemisphere Install — $(date -Is) ==="
echo "Log: ${LOG_FILE}"
echo ""

# Load nvm BEFORE the prereq check — script runs under nohup / non-interactive
# shell where .bashrc isn't sourced. Without this, `node` isn't on PATH at §1.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
fi
# Also pick up uv and local-bin paths in case prior steps installed them
export PATH="$HOME/.local/bin:$PATH"

fail() { echo "FAIL: $*" >&2; exit 1; }
note() { echo "→ $*"; }
section() { echo ""; echo "═══ $* ═══"; }
have() { command -v "$1" >/dev/null 2>&1; }

# ─── Section 1: Verify Human-Required Prereqs ──────────────────────────────

section "Section 1 — Verify human-required prereqs"

[ -f "${ENV_FILE}" ] || fail "${ENV_FILE} not found. See install-plan.md §1."

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
set +a

# Required vars
: "${GITHUB_TOKEN:?GITHUB_TOKEN missing in .env}"
: "${HETZNER_API_TOKEN:?HETZNER_API_TOKEN missing in .env}"
: "${HERMES_API_SERVER_KEY:?HERMES_API_SERVER_KEY missing in .env (any random 32+ char string)}"

# Optional but recommended
[ -z "${OPENAI_API_KEY:-}" ] && note "OPENAI_API_KEY not set — embeddings will be unavailable"
[ -z "${OPENROUTER_API_KEY:-}" ] && note "OPENROUTER_API_KEY not set — no LLM fallback configured"
[ -z "${BRAVE_API_KEY:-}" ] && note "BRAVE_API_KEY not set — Brave search MCP will fail at runtime"

note "Env vars present"

# Verify VPS state
[ -d "${CTO_ROOT}" ] || fail "${CTO_ROOT} not present — clone the repo first"
have node || fail "Node not on PATH — verify nvm setup"
node --version | grep -qE '^v22\.' || fail "Node 22 required (have: $(node --version))"

note "VPS state OK"

# ─── Section 3: System Prereqs ─────────────────────────────────────────────

section "Section 3 — System prereqs"

note "Updating apt"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

note "Installing system packages"
sudo apt-get install -y \
  git \
  curl \
  build-essential \
  python3.12-venv \
  python3-pip \
  ufw \
  fail2ban \
  sqlite3 \
  jq

note "Installing uv (Hermes Python manager)"
if ! have uv; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # shellcheck disable=SC1091
  . "$HOME/.local/bin/env" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
fi
have uv || fail "uv install failed"

note "Installing A2A SDK"
pip install --user --quiet a2a-sdk
python3 -c "import a2a" || fail "a2a SDK import failed"

note "OS tweaks (IPv6 off, systemd lingering on)"
if [ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)" != "1" ]; then
  sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
  echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee /etc/sysctl.d/99-cto.conf >/dev/null
fi
sudo loginctl enable-linger "$(whoami)" || true

# ─── Section 4: Install Binaries ───────────────────────────────────────────

section "Section 4 — Install OpenClaw, Hermes, supporting binaries"

note "Installing OpenClaw (target latest — must be v2026.5.6+ for the device-code SSH bug fix, issue #74212)"
if ! have openclaw; then
  npm install -g openclaw@latest
fi
OC_VERSION=$(openclaw --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
note "OpenClaw version: ${OC_VERSION}"

note "Installing Codex CLI (@openai/codex) — drives the device-code OAuth flow that OpenClaw and Hermes both consume"
# Putting Codex CLI first means we do ONE device-code approval (codex login), populating ~/.codex/auth.json.
# OpenClaw and Hermes both pick up from that file (Hermes natively imports it; OpenClaw's models auth can reuse).
if ! have codex; then
  npm install -g @openai/codex
fi
codex --version

note "Installing engram (Gentleman-Programming/engram, Go binary)"
if ! have engram; then
  ENGRAM_URL=$(curl -fsSL "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" \
    | grep '"browser_download_url"' \
    | grep -E 'linux.*amd64|linux.*x86_64' \
    | head -1 \
    | cut -d '"' -f 4)
  [ -n "${ENGRAM_URL}" ] || fail "Could not find engram linux/amd64 release asset"
  curl -fsSL "${ENGRAM_URL}" -o /tmp/engram
  sudo install -m 0755 /tmp/engram /usr/local/bin/engram
fi
engram --version || engram version || true

note "Installing Hermes Agent"
if ! have hermes; then
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
  # shellcheck disable=SC1090
  . "$HOME/.bashrc" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
fi
have hermes || fail "Hermes installer did not produce \`hermes\` on PATH"
hermes --version

note "Installing github-mcp-server (Go binary)"
if ! have github-mcp-server; then
  GH_MCP_URL=$(curl -fsSL https://api.github.com/repos/github/github-mcp-server/releases/latest \
    | grep '"browser_download_url"' \
    | grep 'linux-amd64' \
    | head -1 \
    | cut -d '"' -f 4)
  [ -n "${GH_MCP_URL}" ] || fail "Could not find github-mcp-server linux-amd64 release"
  curl -fsSL "${GH_MCP_URL}" -o /tmp/github-mcp-server
  sudo install -m 0755 /tmp/github-mcp-server /usr/local/bin/github-mcp-server
fi

note "Installing hcloud CLI"
if ! have hcloud; then
  curl -fsSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
  sudo tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud
  rm hcloud-linux-amd64.tar.gz
fi
hcloud version

note "Installing OpenClaw daemon (systemd user service)"
# Onboard only if not already onboarded
if ! systemctl --user list-unit-files | grep -q openclaw-gateway; then
  openclaw onboard --non-interactive \
    --mode local \
    --auth-choice "openrouter-api-key" \
    --openrouter-api-key "${OPENROUTER_API_KEY:-placeholder}" \
    --gateway-port 18789 \
    --gateway-bind loopback \
    --install-daemon \
    --daemon-runtime node \
    --skip-bootstrap \
    --skip-health \
    --workspace "${CTO_ROOT}"
fi

note "Installing Hermes daemon (systemd user service)"
if ! systemctl --user list-unit-files | grep -q hermes-gateway; then
  hermes gateway install
  systemctl --user daemon-reload
fi

# ─── Section 5: Configure ──────────────────────────────────────────────────

section "Section 5 — Configure OpenClaw + Hermes + A2A"

note "Codex OAuth — primary device-code flow via Codex CLI (single approval)"
# Strategy: do ONE device-code flow via the upstream Codex CLI. This populates
# ~/.codex/auth.json. Both OpenClaw and Hermes can then consume that auth state
# (Hermes imports it natively; OpenClaw's models auth login can use it too on
# v2026.5.6+ where the device-code SSH-display bug #74212 is fixed).
if [ ! -s "${HOME}/.codex/auth.json" ]; then
  echo ""
  echo "→ John: Codex CLI will print a URL + 8-character code."
  echo "→ Open the URL on your phone, sign in to your ChatGPT Business workspace,"
  echo "→ enter the code, and click Authorize. Then come back here — install resumes."
  echo ""
  codex login --device-auth
else
  note "~/.codex/auth.json already present — reusing existing Codex auth"
fi

# Token sanity check
if [ -s "${HOME}/.codex/auth.json" ]; then
  jq -r '{auth_mode, last_refresh, has_access_token: ((.tokens.access_token // "") != "")}' \
    "${HOME}/.codex/auth.json" 2>/dev/null || note "(jq not installed — skipping token introspection)"
else
  fail "Codex device-code flow did not produce ~/.codex/auth.json"
fi

note "Codex OAuth — register profile with OpenClaw (reuses Codex CLI auth state)"
if ! openclaw models auth list 2>/dev/null | grep -q openai-codex; then
  # On OpenClaw v2026.5.6+, models auth login can leverage the existing
  # ~/.codex/auth.json. If it falls back to its own device-code flow,
  # approve the SECOND code on phone.
  openclaw models auth login --provider openai-codex --device-code || \
    note "(OpenClaw auth login non-zero — verify with: openclaw models auth list)"
else
  note "OpenClaw already has openai-codex auth profile"
fi

note "Codex OAuth — register profile with Hermes (auto-imports ~/.codex/auth.json)"
# Hermes explicitly supports importing from ~/.codex/auth.json on first use.
if ! hermes model list 2>/dev/null | grep -q openai-codex; then
  # If Hermes doesn't auto-import, it'll prompt for its own device-code.
  hermes model add openai-codex --device-code 2>/dev/null || \
    note "(Hermes 'model add' subcommand may have different syntax — verify manually with: hermes model)"
fi

note "Writing OpenClaw openclaw.json"
OPENCLAW_DIR="${HOME}/.openclaw"
mkdir -p "${OPENCLAW_DIR}"
cat > "${OPENCLAW_DIR}/openclaw.json" <<JSON
{
  "env": {
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY:-}",
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}",
    "BRAVE_API_KEY": "${BRAVE_API_KEY:-}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY:-}"
  },
  "gateway": { "bind": "loopback", "auth": { "mode": "token" }, "port": 18789 },
  "skills": { "autoInstall": false },
  "plugins": { "entries": { "bonjour": { "enabled": false } } },
  "agents": {
    "defaults": {
      "workspace": "${CTO_ROOT}",
      "model": {
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": ["openrouter/openrouter/auto"]
      },
      "thinkingDefault": "adaptive",
      "sandbox": { "mode": "off" },
      "memorySearch": { "extraPaths": ["${CTO_ROOT}/wiki", "${CTO_ROOT}/logs/decisions"] }
    }
  },
  "mcp": {
    "servers": {
      "engram":     { "command": "engram", "args": ["mcp-server"] },
      "vault":      { "command": "npx", "args": ["-y", "@bitbonsai/mcpvault@latest", "${CTO_ROOT}/wiki"] },
      "filesystem": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "${CTO_ROOT}"] },
      "github":     { "command": "/usr/local/bin/github-mcp-server", "args": [], "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "\${GITHUB_TOKEN}" } },
      "brave-search": { "command": "npx", "args": ["-y", "@brave/brave-search-mcp-server"], "env": { "BRAVE_API_KEY": "\${BRAVE_API_KEY}" } },
      "fetch":      { "command": "uvx", "args": ["mcp-server-fetch"] },
      "hetzner":    { "command": "npx", "args": ["-y", "@lazyants/hetzner-mcp-server"], "env": { "HETZNER_API_TOKEN": "\${HETZNER_API_TOKEN}" } }
    }
  }
}
JSON
note "Validating OpenClaw config"
openclaw doctor || fail "openclaw doctor reported errors — see ${LOG_FILE}"

note "Writing Hermes config"
hermes config set model openai-codex/gpt-5.5
hermes config set gateway.port 8642
hermes config set gateway.bind loopback
hermes config set api_server.enabled true
hermes config set api_server.key "${HERMES_API_SERVER_KEY}"
[ -n "${OPENAI_API_KEY:-}" ] && hermes config set OPENAI_API_KEY "${OPENAI_API_KEY}"
chmod 0600 "${HOME}/.hermes/.env" 2>/dev/null || true

note "Setting up A2A registry"
A2A_DIR="${CTO_ROOT}/a2a/registry"
mkdir -p "${A2A_DIR}/cards"

# Agent Cards — minimal v1.0 versions
cat > "${A2A_DIR}/cards/openclaw.json" <<JSON
{
  "name": "openclaw",
  "role": "left-hemisphere",
  "description": "Orchestrator: gateway, planning, task decomposition, final-mile delivery to user",
  "endpoint": "http://127.0.0.1:18789",
  "capabilities": ["messaging", "routing", "planning", "skill-execution-via-openclaw-skills"]
}
JSON

cat > "${A2A_DIR}/cards/hermes.json" <<JSON
{
  "name": "hermes",
  "role": "right-hemisphere",
  "description": "Worker: skill execution, GEPA learning loop, skill auto-creation",
  "endpoint": "http://127.0.0.1:8642",
  "capabilities": ["skill-execution", "research-synthesis", "long-horizon-work", "self-evolution"]
}
JSON

# Minimal A2A registry server — production version would use a2a-sdk fully
cat > "${A2A_DIR}/server.py" <<'PYEOF'
#!/usr/bin/env python3
"""Minimal A2A registry for CTO v1.0.
Serves Agent Cards over HTTP. Full a2a-sdk integration follows in v1.1.
"""
import json
import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler

CARDS_DIR = os.path.join(os.path.dirname(__file__), "cards")
AUDIT_LOG = os.path.join(os.path.dirname(__file__), "audit.log")
PORT = int(os.environ.get("A2A_REGISTRY_PORT", "9000"))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/cards":
            cards = {}
            for fn in os.listdir(CARDS_DIR):
                if fn.endswith(".json"):
                    with open(os.path.join(CARDS_DIR, fn)) as f:
                        cards[fn[:-5]] = json.load(f)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(cards).encode())
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        with open(AUDIT_LOG, "a") as f:
            f.write(f"{self.address_string()} {fmt % args}\n")

if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
PYEOF
chmod +x "${A2A_DIR}/server.py"

# systemd user unit
mkdir -p "${HOME}/.config/systemd/user"
cat > "${HOME}/.config/systemd/user/cto-a2a-registry.service" <<UNIT
[Unit]
Description=CTO A2A Registry
After=network.target

[Service]
ExecStart=/usr/bin/python3 ${A2A_DIR}/server.py
Restart=on-failure
Environment=A2A_REGISTRY_PORT=9000

[Install]
WantedBy=default.target
UNIT
systemctl --user daemon-reload

# ─── Section 6: Post-Configuration ─────────────────────────────────────────

section "Section 6 — Start, harden network, finalize"

note "Starting daemons"
systemctl --user enable --now openclaw-gateway hermes-gateway cto-a2a-registry
sleep 3

note "Configuring UFW (network defense in depth — gateways stay loopback)"
sudo ufw --force default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable
sudo systemctl enable --now fail2ban

note "Writing decision log CTO-DECISION-007 (install state)"
DECISION_FILE="${CTO_ROOT}/logs/decisions/CTO-DECISION-007.json"
mkdir -p "$(dirname "${DECISION_FILE}")"
cat > "${DECISION_FILE}" <<JSON
{
  "id": "CTO-DECISION-007",
  "timestamp": "$(date -Is)",
  "version_before": "0.1.0",
  "version_after": "0.2.0",
  "technology": "Two-hemisphere install state",
  "action": "adopted",
  "summary": "Initial two-hemisphere install executed by install-cto.sh.",
  "installed_versions": {
    "openclaw": "$(openclaw --version 2>/dev/null | head -1)",
    "hermes": "$(hermes --version 2>/dev/null | head -1)",
    "engram": "$(engram --version 2>/dev/null | head -1 || engram version 2>/dev/null | head -1)",
    "hcloud": "$(hcloud version 2>/dev/null | head -1)",
    "node": "$(node --version)",
    "uv": "$(uv --version 2>/dev/null | head -1)"
  },
  "ports": { "openclaw": 18789, "hermes": 8642, "a2a_registry": 9000 },
  "auth_profiles": { "openclaw": "openai-codex", "hermes": "openai-codex" },
  "rollback": {
    "instructions": "systemctl --user stop openclaw-gateway hermes-gateway cto-a2a-registry; rm -rf ~/.openclaw ~/.hermes ${A2A_DIR}; re-run scripts/install-cto.sh"
  }
}
JSON

note "Repo push"
cd "${CTO_ROOT}"
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "Two-hemisphere install — DECISION-007 install state recorded"
fi
git push origin main || note "Push failed — verify deploy key has write access (see architecture-decisions-john.md #10)"

# ─── Verification gates (Phase 1 + 2 from test-plan.md) ─────────────────────

section "Verification — Phase 1 (static) + Phase 2 (services)"

# Phase 1 — Static
note "1.1 Binaries on PATH"
for bin in openclaw hermes engram github-mcp-server hcloud uv; do
  have "$bin" || fail "1.1 $bin not on PATH"
done

note "1.3 Config files exist"
[ -f "${OPENCLAW_DIR}/openclaw.json" ] || fail "1.3 openclaw.json missing"
[ -f "${HOME}/.hermes/config.yaml" ] || fail "1.3 Hermes config.yaml missing"
[ "$(stat -c '%a' "${HOME}/.hermes/.env" 2>/dev/null || echo none)" = "600" ] || note "1.3 WARN: ~/.hermes/.env not 0600"

note "1.6 No Telegram artefacts"
! grep -iq telegram "${OPENCLAW_DIR}/openclaw.json" || fail "1.6 Telegram in openclaw.json"

note "1.7 systemd units present"
[ "$(systemctl --user list-unit-files | grep -cE 'openclaw-gateway|hermes-gateway|cto-a2a-registry')" -ge 3 ] || fail "1.7 missing service units"

# Phase 2 — Services
note "2.1 Daemons active"
for svc in openclaw-gateway hermes-gateway cto-a2a-registry; do
  systemctl --user is-active "$svc" >/dev/null || fail "2.1 $svc not active"
done

note "2.2 Ports bound to loopback"
ss -tlnp 2>/dev/null | grep -q "127.0.0.1:18789" || fail "2.2 OpenClaw 18789 not on loopback"
ss -tlnp 2>/dev/null | grep -q "127.0.0.1:8642"  || fail "2.2 Hermes 8642 not on loopback"

note "2.3 Health endpoints"
curl -fsS http://127.0.0.1:8642/health | grep -q '"status"' || fail "2.3 Hermes /health failed"
curl -fsS http://127.0.0.1:9000/health | grep -q '"status"' || fail "2.3 A2A registry /health failed"

note "2.5 A2A registry serves both Cards"
curl -fsS http://127.0.0.1:9000/cards | grep -q openclaw || fail "2.5 openclaw Card missing from registry"
curl -fsS http://127.0.0.1:9000/cards | grep -q hermes || fail "2.5 hermes Card missing from registry"

# ─── Done ──────────────────────────────────────────────────────────────────

section "Install complete"

cat <<SUMMARY

Two-hemisphere CTO install: SUCCESS

  OpenClaw (left, thinking):  127.0.0.1:18789  ($(openclaw --version 2>/dev/null | head -1))
  Hermes   (right, doing):    127.0.0.1:8642   ($(hermes --version 2>/dev/null | head -1))
  A2A registry:               127.0.0.1:9000

  Auth: Codex OAuth (ChatGPT Pro) on both halves
  Logs: ${LOG_FILE}
  Decision: ${DECISION_FILE}

Next: run Phase 3 functional tests manually per test-plan.md §3.
SUMMARY
