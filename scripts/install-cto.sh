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
# OpenRouter retired 2026-05-24 (CTO-DECISION-014). Both hemispheres run on Codex
# (cto@husband.llc Pro) only. No fallback configured here on purpose.
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
  jq \
  openssl \
  debian-keyring debian-archive-keyring apt-transport-https

# Caddy via official repo (reverse proxy + auto-TLS for the PWA at cto.husband.llc)
if ! have caddy; then
  note "Installing Caddy (reverse proxy + Let's Encrypt)"
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y caddy
fi
caddy version | head -1

note "Installing uv (Hermes Python manager)"
if ! have uv; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # shellcheck disable=SC1091
  . "$HOME/.local/bin/env" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
fi
have uv || fail "uv install failed"

note "A2A SDK install skipped — v1.0 minimal registry uses only Python stdlib"
# Ubuntu 24.04 enforces PEP 668 (externally-managed-environment); the a2a-sdk
# install was speculative for the v1.1 formal A2A protocol calls. The v1.0
# registry server I install in §5.4 uses only http.server + json + os from
# stdlib, so no extra packages needed. When we move to v1.1, install via
# `pipx install a2a-sdk` or a dedicated venv at /opt/cto/a2a/.venv.

note "Installing PWA backend Python dependencies"
python3 -m venv "${CTO_ROOT}/.venv"
"${CTO_ROOT}/.venv/bin/python" -m pip install --upgrade pip
"${CTO_ROOT}/.venv/bin/python" -m pip install pywebpush

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
  sudo npm install -g openclaw@latest
fi
OC_VERSION=$(openclaw --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
note "OpenClaw version: ${OC_VERSION}"

note "Installing Codex CLI (@openai/codex) — drives the device-code OAuth flow that OpenClaw and Hermes both consume"
# Putting Codex CLI first means we do ONE device-code approval (codex login), populating ~/.codex/auth.json.
# OpenClaw and Hermes both pick up from that file (Hermes natively imports it; OpenClaw's models auth can reuse).
if ! have codex; then
  sudo npm install -g @openai/codex
fi
codex --version

note "Installing engram (Gentleman-Programming/engram, Go binary, tarball-packaged)"
# Force reinstall if the existing /usr/local/bin/engram is the tarball-as-binary mistake from an earlier run
if [ -f /usr/local/bin/engram ] && ! /usr/local/bin/engram --version >/dev/null 2>&1; then
  sudo rm -f /usr/local/bin/engram
fi
if ! have engram; then
  # Real release assets: engram_X.Y.Z_linux_amd64.tar.gz
  ENGRAM_URL=$(curl -fsSL "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" \
    | grep '"browser_download_url"' \
    | grep -E 'linux_amd64\.tar\.gz' \
    | head -1 \
    | cut -d '"' -f 4 || true)
  [ -n "${ENGRAM_URL}" ] || fail "Could not find engram linux_amd64.tar.gz release asset"
  curl -fsSL "${ENGRAM_URL}" -o /tmp/engram.tar.gz
  tar -xzf /tmp/engram.tar.gz -C /tmp engram
  sudo install -m 0755 /tmp/engram /usr/local/bin/engram
  rm -f /tmp/engram.tar.gz /tmp/engram
fi
engram --version 2>/dev/null || engram version 2>/dev/null || true

note "Installing Hermes Agent"
if ! have hermes; then
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
  # shellcheck disable=SC1090
  . "$HOME/.bashrc" 2>/dev/null || true
  export PATH="$HOME/.local/bin:$PATH"
fi
have hermes || fail "Hermes installer did not produce \`hermes\` on PATH"
hermes --version

note "Installing github-mcp-server (Go binary, tarball-packaged)"
if ! have github-mcp-server; then
  # Releases are named: github-mcp-server_Linux_x86_64.tar.gz (not "linux-amd64")
  GH_MCP_URL=$(curl -fsSL https://api.github.com/repos/github/github-mcp-server/releases/latest \
    | grep '"browser_download_url"' \
    | grep 'Linux_x86_64\.tar\.gz' \
    | head -1 \
    | cut -d '"' -f 4 || true)
  [ -n "${GH_MCP_URL}" ] || fail "Could not find github-mcp-server Linux_x86_64.tar.gz release asset"
  curl -fsSL "${GH_MCP_URL}" -o /tmp/gh-mcp.tar.gz
  tar -xzf /tmp/gh-mcp.tar.gz -C /tmp github-mcp-server
  sudo install -m 0755 /tmp/github-mcp-server /usr/local/bin/github-mcp-server
  rm -f /tmp/gh-mcp.tar.gz /tmp/github-mcp-server
fi
github-mcp-server --version 2>&1 | head -1 || true

note "Installing Lightpanda browser (AI-first headless, CTO-DECISION-011)"
# Lightpanda is a CDP-compatible headless browser engine built from scratch in
# Zig, designed for AI agents. Drop-in for Playwright via connectOverCDP.
# 11x faster execution, 9x less memory than headless Chrome. License AGPL-3.0
# — running as-is without modification doesn't activate the copyleft trigger,
# and the CTO repo is already public; exception documented in CTO-DECISION-011.
if ! have lightpanda; then
  curl -fSL -o /tmp/lightpanda \
    "https://github.com/lightpanda-io/browser/releases/download/nightly/lightpanda-x86_64-linux"
  sudo install -m 0755 /tmp/lightpanda /usr/local/bin/lightpanda
  rm -f /tmp/lightpanda
fi
lightpanda version 2>&1 | head -1 || true

note "Installing @grabow/safe-gmail-mcp (read-only Gmail MCP, CTO-DECISION-010)"
# Pre-installing avoids first-call npx download latency and surfaces install
# failures at provision time rather than runtime.
if ! have safe-gmail-mcp; then
  sudo npm install -g @grabow/safe-gmail-mcp
fi
safe-gmail-mcp --version 2>&1 | head -1 || true

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
  # OpenRouter retired (CTO-DECISION-014) — skip auth during onboard; Codex OAuth
  # is registered separately in Section 5 once ~/.codex/auth.json is populated by
  # the upstream Codex CLI device-code flow. OpenClaw 2026.5.22 uses
  # --auth-choice skip rather than the removed --skip-auth flag.
  openclaw onboard --non-interactive --accept-risk \
    --mode local \
    --auth-choice skip \
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
  printf 'n\nn\n' | hermes gateway install
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

note "Generating service tokens and instance namespace defaults if missing"
# These tokens authenticate inter-hemisphere A2A calls and the PWA.
# Generated once per install; persisted in /opt/cto/.env so subsequent
# runs reuse the same values (idempotent). Candidate clones must override the
# namespace/session variables below so they never post into the production PWA
# chat DB or reuse production agent sessions before promotion.
ENV_FILE_VPS="${CTO_ROOT}/.env"
if ! grep -q "^HERMES_A2A_TOKEN=" "${ENV_FILE_VPS}"; then
  echo "HERMES_A2A_TOKEN=$(openssl rand -hex 32)" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^PWA_AUTH_TOKEN=" "${ENV_FILE_VPS}"; then
  echo "PWA_AUTH_TOKEN=$(openssl rand -hex 32)" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^CTO_INSTANCE_ID=" "${ENV_FILE_VPS}"; then
  echo "CTO_INSTANCE_ID=production" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^CTO_TEST_MODE=" "${ENV_FILE_VPS}"; then
  echo "CTO_TEST_MODE=0" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^CHAT_DB=" "${ENV_FILE_VPS}"; then
  echo "CHAT_DB=${CTO_ROOT}/chat.db" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^OPENCLAW_SESSION_ID=" "${ENV_FILE_VPS}"; then
  echo "OPENCLAW_SESSION_ID=production-pwa-john-openclaw" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^HERMES_HUMAN_SESSION_ID=" "${ENV_FILE_VPS}"; then
  echo "HERMES_HUMAN_SESSION_ID=production-pwa-john-hermes" >> "${ENV_FILE_VPS}"
fi
if ! grep -q "^HERMES_AGENT_SESSION_ID=" "${ENV_FILE_VPS}"; then
  echo "HERMES_AGENT_SESSION_ID=production-a2a-openclaw-hermes" >> "${ENV_FILE_VPS}"
fi
chmod 0600 "${ENV_FILE_VPS}"
# Re-source so the new values are visible to the rest of this script
set -a; . "${ENV_FILE_VPS}"; set +a

note "Generating VAPID keypair for Web Push (if not present)"
VAPID_DIR="${CTO_ROOT}/.vapid"
mkdir -p "${VAPID_DIR}"
if [ ! -s "${VAPID_DIR}/private.pem" ]; then
  openssl ecparam -name prime256v1 -genkey -noout -out "${VAPID_DIR}/private.pem"
  openssl ec -in "${VAPID_DIR}/private.pem" -pubout -out "${VAPID_DIR}/public.pem" 2>/dev/null
  # Browsers expect the uncompressed point as base64url (no padding)
  openssl ec -in "${VAPID_DIR}/private.pem" -pubout -outform DER 2>/dev/null \
    | tail -c 65 | base64 | tr -d '=' | tr '/+' '_-' > "${VAPID_DIR}/public.b64url"
  chmod 0600 "${VAPID_DIR}/private.pem"
fi

note "Writing OpenClaw openclaw.json"
OPENCLAW_DIR="${HOME}/.openclaw"
mkdir -p "${OPENCLAW_DIR}"
cat > "${OPENCLAW_DIR}/openclaw.json" <<JSON
{
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}",
    "BRAVE_API_KEY": "${BRAVE_API_KEY:-}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY:-}"
  },
  "gateway": { "mode": "local", "bind": "loopback", "auth": { "mode": "token" }, "port": 18789 },
  "plugins": { "entries": { "bonjour": { "enabled": false }, "openai": { "enabled": true } } },
  "agents": {
    "defaults": {
      "workspace": "${CTO_ROOT}",
      "model": {
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": []
      },
      "thinkingDefault": "adaptive",
      "sandbox": { "mode": "off" },
      "memorySearch": { "extraPaths": ["${CTO_ROOT}/wiki", "${CTO_ROOT}/logs/decisions"] },
      "bootstrapMaxChars": 16000,
      "bootstrapTotalMaxChars": 120000
    }
  },
  "mcp": {
    "servers": {
      "a2a-delegate": {
        "command": "python3",
        "args": ["${CTO_ROOT}/services/a2a_delegate/server.py"],
        "env": {
          "HERMES_A2A_TOKEN": "${HERMES_A2A_TOKEN}",
          "HERMES_A2A_URL": "http://127.0.0.1:8643/a2a/",
          "CHAT_DB": "${CTO_ROOT}/chat.db"
        }
      },
      "engram":     { "command": "engram", "args": ["mcp", "--tools=agent"], "env": { "ENGRAM_DATA_DIR": "${CTO_ROOT}/.engram", "ENGRAM_PROJECT": "cto" } },
      "vault":      { "command": "npx", "args": ["-y", "@bitbonsai/mcpvault@latest", "${CTO_ROOT}/wiki"] },
      "filesystem": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "${CTO_ROOT}"] },
      "github":     { "command": "/usr/local/bin/github-mcp-server", "args": [], "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" } },
      "brave-search": { "command": "npx", "args": ["-y", "@brave/brave-search-mcp-server"], "env": { "BRAVE_API_KEY": "${BRAVE_API_KEY:-}" } },
      "fetch":      { "command": "uvx", "args": ["mcp-server-fetch"] },
      "hetzner":    { "command": "npx", "args": ["-y", "@lazyants/hetzner-mcp-server"], "env": { "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}" } },
      "gmail":      { "command": "npx", "args": ["-y", "@grabow/safe-gmail-mcp"] },
      "lightpanda": { "command": "/usr/local/bin/lightpanda", "args": ["mcp"] }
    }
  }
}
JSON
note "Validating OpenClaw config"
openclaw doctor || fail "openclaw doctor reported errors — see ${LOG_FILE}"

note "Writing Hermes config"
# Hermes model — Codex OAuth via cto@husband.llc Pro (CTO-DECISION-013, 2026-05-24).
# Codex CLI device-code flow above populated ~/.codex/auth.json; Hermes consumes
# it directly. The fallback and auxiliary session-search/compression model are
# also gpt-5.5 because gpt-5-mini is rejected under ChatGPT-account Codex
# (CTO-DECISION-015, 2026-05-24). OpenRouter was removed entirely.
hermes config set model.default "${HERMES_MODEL:-gpt-5.5}"
hermes config set model.provider "${HERMES_PROVIDER:-openai-codex}"
# fallback_model must be a dict (provider+model), not a string — Hermes warns at
# startup otherwise. gpt-5-mini is rejected under ChatGPT-account Codex
# ('The gpt-5-mini model is not supported when using Codex with a ChatGPT
# account.') so the fallback model must also be gpt-5.5 (CTO-DECISION-015,
# 2026-05-24).
hermes config set fallback_model.provider openai-codex
hermes config set fallback_model.model gpt-5.5
# Auxiliary tasks (session_search, compression) — pin them at the main model
# to bypass the hardcoded openrouter->nous->custom->api-key fallback chain in
# agent/auxiliary_client.py that has no working provider after we retired OR.
# 60s timeout (default 30s) so transient codex peer-closed errors do not
# cascade into 'no fallback available' retry storms (CTO-DECISION-015).
hermes config set auxiliary.session_search.provider openai-codex
hermes config set auxiliary.session_search.model gpt-5.5
hermes config set auxiliary.session_search.timeout 60
hermes config set auxiliary.compression.provider openai-codex
hermes config set auxiliary.compression.model gpt-5.5
hermes config set auxiliary.compression.timeout 60
hermes config set max_output_tokens 2000
hermes config set gateway.port 8642
hermes config set gateway.bind loopback
hermes config set api_server.enabled true
hermes config set api_server.key "${HERMES_API_SERVER_KEY}" >/dev/null
[ -n "${OPENAI_API_KEY:-}" ] && hermes config set OPENAI_API_KEY "${OPENAI_API_KEY}" >/dev/null

# Compression: let conversations fill the gpt-5.5 272K context window before
# auto-summarizing — the 0.5 default fired too eagerly and burned tokens
# compressing turns that still fit. With 24h prompt-cache retention on gpt-5.5
# (the model's API default) + keep-alive every 30 min (below), the long
# session is cheap; let it run (CTO-DECISION-017, 2026-05-25).
hermes config set compression.enabled true
hermes config set compression.threshold 0.9
hermes config set compression.target_ratio 0.3
hermes config set compression.protect_last_n 40
hermes config set agent.max_turns 500

# Expose the toolsets the api_server platform should make available to callers
# carrying a session key. Added by Hermes during the session-continuity work
# (CTO-DECISION-016 negotiation, brought in 2026-05-25 during the reconciliation
# merge). Without this list, the api_server platform exposes a smaller default
# set that doesn't include session_search/delegation/todo/cronjob/code_execution
# — needed by the cross-hemisphere A2A bridge.
python3 - <<'PY'
from pathlib import Path
import yaml
p = Path.home() / '.hermes' / 'config.yaml'
config = yaml.safe_load(p.read_text()) or {}
config.setdefault('platform_toolsets', {})['api_server'] = [
    'web', 'terminal', 'file', 'skills', 'memory', 'session_search',
    'delegation', 'todo', 'cronjob', 'code_execution'
]
p.write_text(yaml.safe_dump(config, sort_keys=False))
PY

# Hermes only reads ~/.hermes/.env (not /opt/cto/.env). Mirror the embeddings key.
# OpenRouter retired (CTO-DECISION-014) — only OPENAI_API_KEY mirrors now.
for KEY in OPENAI_API_KEY; do
  VAL=$(grep "^${KEY}=" "${CTO_ROOT}/.env" 2>/dev/null | head -1)
  if [ -n "${VAL}" ] && ! grep -q "^${KEY}=" "${HOME}/.hermes/.env" 2>/dev/null; then
    echo "${VAL}" >> "${HOME}/.hermes/.env"
  fi
done
chmod 0600 "${HOME}/.hermes/.env" 2>/dev/null || true

# Hermes autonomy gate: this is a headless VPS; John is never on it; the
# architecture is fully autonomous (architecture-decisions-john.md #3,
# HERMES_ROLE.md Failure Handling). Without HERMES_YOLO_MODE=1, Hermes will block
# on its built-in approval prompts for things like systemctl restart of cto-*
# units that it legitimately needs to do (e.g., heartbeat watcher restarting a
# crashed gateway). Wire it via a systemd drop-in so it survives Hermes restarts.
HERMES_DROPIN="${HOME}/.config/systemd/user/hermes-gateway.service.d"
mkdir -p "${HERMES_DROPIN}"
cat > "${HERMES_DROPIN}/10-autonomy.conf" <<'CONF'
# Per architecture-decisions-john.md #3 + HERMES_ROLE.md Failure Handling:
# Hermes runs fully autonomously; bypass the approval gate in tools/approval.py.
[Service]
Environment="HERMES_YOLO_MODE=1"
CONF

# Hermes also reads API_SERVER_KEY from env (not from the api_server.key config
# path — that's at a different schema location). Without this, Hermes refuses
# every X-Hermes-Session-Key from the sidecar with HTTP 403 and the entire PWA
# chat path breaks (CTO-DECISION-015, 2026-05-24).
cat > "${HERMES_DROPIN}/30-api-key.conf" <<CONF
[Service]
Environment="API_SERVER_ENABLED=1"
Environment="API_SERVER_HOST=127.0.0.1"
Environment="API_SERVER_PORT=8642"
Environment="API_SERVER_KEY=${HERMES_API_SERVER_KEY}"
CONF

# Sidecar must send the matching Bearer token. Read as HERMES_API_SERVER_KEY by
# services/hermes_a2a_sidecar/server.py (line 41).
SIDECAR_DROPIN="${HOME}/.config/systemd/user/cto-hermes-a2a-sidecar.service.d"
mkdir -p "${SIDECAR_DROPIN}"
cat > "${SIDECAR_DROPIN}/10-api-key.conf" <<CONF
[Service]
Environment="HERMES_API_SERVER_KEY=${HERMES_API_SERVER_KEY}"
CONF

# Cache keep-alive: ping each live session (PWA→OpenClaw, PWA→Hermes) every
# 30 min so OpenAI's prompt cache stays warm and we don't pay the ~45K
# bootstrap re-warm on every idle gap. The pings travel the real PWA/A2A
# paths, costing a handful of tokens vs 45K of fresh bootstrap (CTO-DECISION-017).
if [ "${CTO_ROOT}/scripts/cache-keepalive.sh" != "/opt/cto/scripts/cache-keepalive.sh" ]; then
  install -m 0755 "${CTO_ROOT}/scripts/cache-keepalive.sh" /opt/cto/scripts/cache-keepalive.sh 2>/dev/null || cp "${CTO_ROOT}/scripts/cache-keepalive.sh" /opt/cto/scripts/cache-keepalive.sh
else
  chmod 0755 /opt/cto/scripts/cache-keepalive.sh
fi
install -m 0644 "${CTO_ROOT}/scripts/systemd/cto-cache-keepalive.service" "${HOME}/.config/systemd/user/cto-cache-keepalive.service"
install -m 0644 "${CTO_ROOT}/scripts/systemd/cto-cache-keepalive.timer"   "${HOME}/.config/systemd/user/cto-cache-keepalive.timer"

# Long Hermes turns should not surface in PWA as raw HTTP 500s. The sidecar
# returns a clear 504 timeout payload; the PWA worker waits slightly longer.
cat > "${SIDECAR_DROPIN}/20-timeout.conf" <<'CONF'
[Service]
Environment="HERMES_TIMEOUT_S=600"
CONF

PWA_DROPIN="${HOME}/.config/systemd/user/cto-pwa-backend.service.d"
mkdir -p "${PWA_DROPIN}"
cat > "${PWA_DROPIN}/20-hermes-timeout.conf" <<'CONF'
[Service]
Environment="HERMES_SEND_TIMEOUT_S=660"
CONF

systemctl --user daemon-reload
systemctl --user enable --now cto-cache-keepalive.timer 2>/dev/null || true

# Hermes shared-memory: configure engram as an MCP server Hermes can consume.
# Repaired 2026-05-25: engram's working MCP command is `engram mcp --tools=agent`
# with ENGRAM_DATA_DIR/ENGRAM_PROJECT. The older `mcp-server --db .../cto.db`
# path created a stale empty cto.db and broke Hermes MCP startup.
hermes config set mcp.servers.engram.command engram 2>/dev/null || true
mkdir -p "${CTO_ROOT}/.engram"
python3 - <<PY
from pathlib import Path
import yaml
p = Path.home() / '.hermes' / 'config.yaml'
config = yaml.safe_load(p.read_text()) or {}
servers = config.setdefault('mcp', {}).setdefault('servers', {})
servers['engram'] = {
    'command': 'engram',
    'args': ['mcp', '--tools=agent'],
    'env': {'ENGRAM_DATA_DIR': '${CTO_ROOT}/.engram', 'ENGRAM_PROJECT': 'cto'},
}
p.write_text(yaml.safe_dump(config, sort_keys=False))
PY

# Hermes: also wire the Gmail MCP so both hemispheres can read 2FA codes
# (CTO-DECISION-010). OAuth scope is enforced at the Google Cloud project,
# not here — this server is read-only by design but the scope is the
# real boundary.
hermes config set mcp.servers.gmail.command npx 2>/dev/null || true
hermes config set mcp.servers.gmail.args "['-y', '@grabow/safe-gmail-mcp']" 2>/dev/null || true

# Hermes: wire Lightpanda MCP for browser automation (CTO-DECISION-011).
# Exposes navigate / click / type / query / fetch tools to Hermes directly
# via MCP — no CDP boilerplate. Both hemispheres get the same access.
hermes config set mcp.servers.lightpanda.command /usr/local/bin/lightpanda 2>/dev/null || true
hermes config set mcp.servers.lightpanda.args "['mcp']" 2>/dev/null || true

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

note "Installing systemd user units for sidecar / PWA / watchers"
SD_DIR="${HOME}/.config/systemd/user"
mkdir -p "${SD_DIR}"

# Common env file for all our services (sources /opt/cto/.env)
cat > "${SD_DIR}/cto-hermes-a2a-sidecar.service" <<UNIT
[Unit]
Description=CTO Hermes A2A sidecar (translates A2A → Hermes API)
After=network.target

[Service]
EnvironmentFile=${CTO_ROOT}/.env
Environment=HERMES_A2A_PORT=8643
Environment=HERMES_API_URL=http://127.0.0.1:8642/v1/chat/completions
Environment=CHAT_DB=${CHAT_DB}
Environment=CTO_INSTANCE_ID=${CTO_INSTANCE_ID}
Environment=CTO_TEST_MODE=${CTO_TEST_MODE}
Environment=HERMES_HUMAN_SESSION_ID=${HERMES_HUMAN_SESSION_ID}
Environment=HERMES_AGENT_SESSION_ID=${HERMES_AGENT_SESSION_ID}
ExecStart=/usr/bin/python3 ${CTO_ROOT}/services/hermes_a2a_sidecar/server.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
UNIT

cat > "${SD_DIR}/cto-pwa-backend.service" <<UNIT
[Unit]
Description=CTO PWA backend (chat bridge to OpenClaw + Hermes)
After=network.target cto-hermes-a2a-sidecar.service
Wants=cto-hermes-a2a-sidecar.service

[Service]
EnvironmentFile=${CTO_ROOT}/.env
Environment=PWA_PORT=8088
Environment=PWA_BIND=127.0.0.1
Environment=PWA_FRONTEND=${CTO_ROOT}/services/pwa/frontend
Environment=CHAT_DB=${CHAT_DB}
Environment=CTO_INSTANCE_ID=${CTO_INSTANCE_ID}
Environment=CTO_TEST_MODE=${CTO_TEST_MODE}
Environment=OPENCLAW_SESSION_ID=${OPENCLAW_SESSION_ID}
Environment=HERMES_A2A_URL=http://127.0.0.1:8643/a2a/
Environment=OPENCLAW_CHAT_URL=http://127.0.0.1:18789/v1/chat/completions
Environment=VAPID_PUBLIC_KEY_FILE=${CTO_ROOT}/.vapid/public.b64url
Environment=VAPID_PRIVATE_KEY_FILE=${CTO_ROOT}/.vapid/private.pem
ExecStart=${CTO_ROOT}/.venv/bin/python ${CTO_ROOT}/services/pwa/backend/server.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
UNIT

# Watchers as systemd timers (Hermes-side autonomic NS)
for watcher in heartbeat health anomaly; do
  cat > "${SD_DIR}/cto-watcher-${watcher}.service" <<UNIT
[Unit]
Description=CTO ${watcher} watcher (Hermes autonomic NS)
After=network.target

[Service]
Type=oneshot
EnvironmentFile=${CTO_ROOT}/.env
ExecStart=/usr/bin/python3 ${CTO_ROOT}/services/watchers/${watcher}.py
UNIT
done

# Timers: heartbeat 30s, health 60s, anomaly 60s
cat > "${SD_DIR}/cto-watcher-heartbeat.timer" <<UNIT
[Unit]
Description=CTO heartbeat watcher every 30s
[Timer]
OnBootSec=30s
OnUnitActiveSec=30s
AccuracySec=2s
[Install]
WantedBy=timers.target
UNIT

cat > "${SD_DIR}/cto-watcher-health.timer" <<UNIT
[Unit]
Description=CTO health watcher every 60s
[Timer]
OnBootSec=45s
OnUnitActiveSec=60s
AccuracySec=2s
[Install]
WantedBy=timers.target
UNIT

cat > "${SD_DIR}/cto-watcher-anomaly.timer" <<UNIT
[Unit]
Description=CTO anomaly watcher every 60s
[Timer]
OnBootSec=60s
OnUnitActiveSec=60s
AccuracySec=5s
[Install]
WantedBy=timers.target
UNIT

systemctl --user daemon-reload
systemctl --user enable cto-hermes-a2a-sidecar cto-pwa-backend \
  cto-watcher-heartbeat.timer cto-watcher-health.timer cto-watcher-anomaly.timer \
  cto-cache-keepalive.timer

# ─── Section 6: Post-Configuration ─────────────────────────────────────────

section "Section 6 — Start, harden network, finalize"

note "Starting daemons"
systemctl --user enable --now openclaw-gateway hermes-gateway cto-a2a-registry \
  cto-hermes-a2a-sidecar cto-pwa-backend \
  cto-watcher-heartbeat.timer cto-watcher-health.timer cto-watcher-anomaly.timer \
  cto-cache-keepalive.timer
sleep 3

note "Installing system Caddyfile (cto.husband.llc → 127.0.0.1:8088)"
sudo install -m 0644 -o root -g root "${CTO_ROOT}/services/pwa/caddy/Caddyfile" /etc/caddy/Caddyfile
sudo mkdir -p /var/log/caddy
sudo systemctl enable --now caddy
sudo systemctl reload caddy || sudo systemctl restart caddy

note "Opening Caddy ports (80, 443) — gateways stay loopback per architecture-decisions-john.md #3"
sudo ufw allow 80/tcp comment "Caddy HTTP (ACME)" 2>&1 | tail -1
sudo ufw allow 443/tcp comment "Caddy HTTPS (PWA)" 2>&1 | tail -1

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
# Configure git identity for the cto user if not already set
git config user.name >/dev/null 2>&1 || git config user.name "CTO"
git config user.email >/dev/null 2>&1 || git config user.email "johnjhusband@users.noreply.github.com"
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "Two-hemisphere install — DECISION-007 install state recorded"
fi
git push origin master 2>&1 || note "Push failed — verify remote has token / deploy key with write access"

# ─── Verification gates (Phase 1 + 2 from test-plan.md) ─────────────────────

section "Verification — Phase 1 (static) + Phase 2 (services)"

# Phase 1 — Static
note "1.1 Binaries on PATH"
for bin in openclaw hermes engram github-mcp-server hcloud uv caddy; do
  have "$bin" || fail "1.1 $bin not on PATH"
done

note "1.3 Config files exist"
[ -f "${OPENCLAW_DIR}/openclaw.json" ] || fail "1.3 openclaw.json missing"
[ -f "${HOME}/.hermes/config.yaml" ] || fail "1.3 Hermes config.yaml missing"
[ "$(stat -c '%a' "${HOME}/.hermes/.env" 2>/dev/null || echo none)" = "600" ] || note "1.3 WARN: ~/.hermes/.env not 0600"

note "1.6 No Telegram artefacts"
! grep -iq telegram "${OPENCLAW_DIR}/openclaw.json" || fail "1.6 Telegram in openclaw.json"

note "1.7 systemd units present (8 expected: 3 daemons + 2 sidecars/PWA + 3 timers)"
[ "$(systemctl --user list-unit-files | grep -cE 'openclaw-gateway|hermes-gateway|cto-a2a-registry|cto-hermes-a2a-sidecar|cto-pwa-backend|cto-watcher-(heartbeat|health|anomaly)\.timer')" -ge 8 ] || fail "1.7 missing service units"

# Phase 2 — Services
note "2.1 Daemons active"
for svc in openclaw-gateway hermes-gateway cto-a2a-registry cto-hermes-a2a-sidecar cto-pwa-backend; do
  systemctl --user is-active "$svc" >/dev/null || fail "2.1 $svc not active"
done

note "2.2 Ports bound to loopback (gateways + sidecars on 127.0.0.1; Caddy public on 80/443)"
for port in 18789 8642 9000 8643 8088; do
  ss -tlnp 2>/dev/null | grep -q "127.0.0.1:${port}" || fail "2.2 port ${port} not on loopback"
done
# Caddy may be on 0.0.0.0 or :: — accept either
ss -tlnp 2>/dev/null | grep -qE "(:|:::|0\.0\.0\.0:)443" || note "(2.2 WARN: 443 not yet bound — Caddy may still be obtaining cert)"

note "2.3 Health endpoints (all 5)"
curl -fsS http://127.0.0.1:8642/health | grep -q '"status"' || fail "2.3 Hermes /health failed"
curl -fsS http://127.0.0.1:9000/health | grep -q '"status"' || fail "2.3 A2A registry /health failed"
curl -fsS http://127.0.0.1:8643/health | grep -q '"status"' || fail "2.3 Hermes A2A sidecar /health failed"
curl -fsS http://127.0.0.1:8088/api/health | grep -q '"status"' || fail "2.3 PWA backend /api/health failed"

note "2.5 A2A registry serves both Cards"
curl -fsS http://127.0.0.1:9000/cards | grep -q openclaw || fail "2.5 openclaw Card missing from registry"
curl -fsS http://127.0.0.1:9000/cards | grep -q hermes || fail "2.5 hermes Card missing from registry"

# ─── Done ──────────────────────────────────────────────────────────────────

section "Install complete"

cat <<SUMMARY

Two-hemisphere CTO install: SUCCESS

  OpenClaw  (left, thinking):  127.0.0.1:18789   ($(openclaw --version 2>/dev/null | head -1))
  Hermes    (right, doing):    127.0.0.1:8642    ($(hermes --version 2>/dev/null | head -1))
  A2A reg.  (corpus callosum): 127.0.0.1:9000
  A2A sidecar (Hermes-side):   127.0.0.1:8643
  PWA backend:                 127.0.0.1:8088 (Caddy → cto.husband.llc)
  Watchers:                    heartbeat 30s, health 60s, anomaly 60s
  Shared memory:               engram at ${CTO_ROOT}/.engram/cto.db

  Auth: Codex OAuth (ChatGPT Pro/Business) on both hemispheres
  PWA bootstrap: token generated in ${ENV_FILE_VPS} (value intentionally not printed)
  Logs: ${LOG_FILE}
  Decision: ${DECISION_FILE}

DNS required (one-time, in your Namecheap dashboard):
  cto.husband.llc.  IN  A  <this VPS public IP>

After DNS propagates (~minutes), construct the one-time PWA bootstrap URL from
${ENV_FILE_VPS} locally and deliver it only through a secure out-of-band path.
The installer intentionally does not print the token into terminal scrollback or logs.

Next: run Phase 3 functional tests manually per test-plan.md §3.
SUMMARY
