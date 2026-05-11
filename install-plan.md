# CTO Install Plan — Two-Hemisphere Build

**L0:** Plan for the install script that builds CTO on Hetzner VPS **46.224.81.84** (cx43, openclaw v2026.5.3-1 already installed but not configured, per `claude_wake_state.json`). Two hemispheres on one VPS: OpenClaw (left, thinking, port 18789) + Hermes (right, doing, port 8642 default) + **A2A protocol** as both corpus callosum AND the communication layer to John (replacing Telegram per architecture-decisions-john.md #9). Both halves on Codex OAuth via one ChatGPT Pro. Six sections plus deconfliction analysis up front.

**L1:** This is a **one-time, human-directed bundled install**, not an autonomous upgrade — SOUL.md #15 ("one material change per cycle") applies to CTO's autonomous upgrade discipline, not the initial human-driven build. Sections: (0) Pre-install conflict analysis; (1) Human-required prereqs (none done yet per John as of 2026-05-11 — remind when ready); (2) Download packages and binaries; (3) Install system prereqs (runtimes, OS tweaks); (4) Install OpenClaw + Hermes + supporting binaries; (5) Configure both halves + publish A2A Agent Cards; (6) Post-config verification + decision log entry. **No Telegram anywhere** — replaced by A2A + human interface (interface implementation is a separate phase, not v1.0 install scope). Full autonomy preserved: no hardening of the autonomy/sandbox layer, per architecture-decisions-john.md #3 and #8.

**Last updated:** 2026-05-11
**Verification:** Primary sources today — docs.openclaw.ai, hermes-agent.nousresearch.com, github.com/Gentleman-Programming/engram, plus CTO docs (wiki/openclaw-setup.md, wiki/codex-oauth-setup.md, architecture-decisions-john.md).
**Source:** Live web research 2026-05-11 + existing `scripts/install.sh` review.

---

## Preamble — How This Install Differs From an Upgrade

| Aspect | One-time human-directed install (this one) | Autonomous upgrade cycle (post-install) |
|---|---|---|
| Cadence rule | SOUL.md #15 does NOT bind — bundle is the point | One material change per cycle |
| Driver | John runs the script manually | CTO triggers via clone-test-replace |
| Scope | Both hemispheres + Codex auth + A2A wiring in one shot | One isolated change per cycle |
| Snapshot before | Skip per John's direction | Required |
| Repo push | Yes (current state, before install) | Built into upgrade cycle |

The discipline of small atomic changes resumes the moment this install lands and the daemons are running.

---

## Section 0 — Pre-Installation Conflict Analysis (Deconflict Before Install)

Co-locating OpenClaw and Hermes on one VPS. Conflicts identified and resolved before any install action.

| # | Conflict | Detail | Resolution |
|---|---|---|---|
| **1** | **Gateway ports** | OpenClaw defaults to **18789** [verified]. Hermes defaults to **8642** [verified — `curl http://localhost:8642/health` is the canonical health check per Hermes docs]. | No conflict at defaults — keep both. Both bind loopback. |
| **2** | **systemd user services** | Both install as systemd user services for the `cto` user. Names differ. Lingering must be enabled once. [verified] | `loginctl enable-linger cto` once during section 3 OS tweaks. Both daemons attach. |
| **3** | **Node.js version source** | OpenClaw uses nvm Node 22 (VPS already has nvm+node22 per wake state). Hermes installer pulls its own uv-managed Node 22 into `~/.local/share/uv/`. [verified] | No conflict — disjoint installs. Don't `nvm use` mid-install. |
| **4** | **Python version** | OpenClaw uses system Python 3.12 (Ubuntu 24.04). Hermes manages Python 3.11 via uv under `~/.hermes/`. [verified] | Disjoint. Ensure `python3.12-venv` present for OpenClaw MCPs. |
| **5** | **PATH ordering** | OpenClaw via nvm bin dir; Hermes via `~/.local/bin/hermes`. [verified] | Both coexist in `~/.bashrc`. Post-install: confirm `which openclaw` and `which hermes` resolve correctly. |
| **6** | **Codex OAuth credential stores** | OpenClaw stores in its own agent auth store. Hermes uses `~/.hermes/auth.json` and can import existing `~/.codex/auth.json`. [verified] | Run Hermes device-code flow; OpenClaw runs its own device-code flow. Same ChatGPT Pro subscription, two stores. |
| **7** | **Rate-limit pool sharing** | Both halves draw on one ChatGPT Pro subscription. Pro = 20× Plus (25× promo through 2026-05-31). | Build shared budget meter in post-config. v1.0 ships without it; v1.1 adds it. Logged as expected v1.1 work, not a BACKLOG gap. |
| **8** | **`hermes claw migrate` is the WRONG command** | This command moves OpenClaw state INTO Hermes. Our design wants both side by side. [verified] | **Do NOT use it.** Clean Hermes install only. |
| **9** | **MCP server duplication** | If both halves consume the same MCP stdio server, two processes. No port conflict, resource doubling. [verified] | Acceptable for v1.0. Future: MCP-over-HTTP behind one process. |
| **10** | **IPv6 / Telegram delay** | OpenClaw documented bug — IPv6 causes Telegram delays. **Telegram is removed from our architecture, so this is moot for us.** | Still apply the IPv6 disable for general network hygiene (cleaner DNS resolution, simpler routing). |
| **11** | **Bonjour plugin** | OpenClaw documented bug on headless. [verified] | Disable in openclaw.json: `plugins.entries.bonjour.enabled: false`. |
| **12** | **A2A registry** | Both halves need to discover each other's Agent Cards. The protocol provides this; we need a registry to host the Cards. | Use one of the production A2A SDKs (Python or JS — both available). Single registry process on VPS, both halves publish their Cards to it, both read from it. |

**Conflicts that DON'T exist (verified — don't engineer against these):**
- Data paths (`~/.openclaw/` vs `~/.hermes/` disjoint)
- Skills paths (workspace `/opt/cto/skills/` for OpenClaw, `~/.hermes/skills/` for Hermes)
- Memory backends (engram for OpenClaw; FTS5 + Honcho for Hermes — separate stores)

**Conflict explicitly retired by architecture-decisions-john.md #9:**
- *Telegram bot conflict* — Telegram is removed entirely. Replaced by A2A with a human interface (separate phase from this install).

---

## Section 1 — Human-Required Prerequisites

> **Status as of 2026-05-11:** John has indicated none of these are done yet. **Remind John when he's ready to run the install.**

These cannot be automated. John completes them before running the install script. The script fails fast if any required item is missing.

### 1.1 Subscriptions and tokens
1. **ChatGPT Business** (existing — John already pays $30/seat). Workspace admin toggles **must** be enabled at https://chatgpt.com/admin/settings → Settings and Permissions:
   - **"Allow members to use Codex Local"** = ON
   - **"Enable device code authentication for Codex CLI"** = ON
   - Wait up to 10 minutes for propagation.
   - [Both enabled by John 2026-05-11 — verified by him in workspace UI.]
2. **GitHub Personal Access Token** with `repo` scope (private CTO repo). [pending]
3. **Hetzner Cloud API token** at console.hetzner.cloud, Read & Write (for the upgrade-cycle MCP). [pending]
4. **(Optional) OpenAI API key** for embeddings — Codex subscription does NOT cover embeddings. Pennies/month. [pending]
5. **(Optional) OpenRouter API key with $5+ credits** as fallback if Codex OAuth is throttled. [pending — John's prior OpenRouter experience makes quota pressure on Business expected, but the fallback path is OpenRouter]
6. **NOT NEEDED — ChatGPT Pro $200/mo:** Per CTO-DECISION-008, Business is the primary tier. Pro is the documented future escape (on a separate email) only if observed Business Codex quotas constrain CTO operation. Do not sign up for Pro today.

### 1.2 VPS state (already true per wake state, verify before install)
7. **VPS at 46.224.81.84** — cx43 (8 vCPU, 16 GB RAM, 150 GB disk), Ubuntu 24.04 [verified — wake state].
8. **Non-root user `cto`** with sudo, nvm + Node 22 already present [verified — wake state].
9. **OpenClaw v2026.5.3-1** present at `/opt/cto` (NOT configured, NOT running per wake state).
10. **CTO repo cloned to `/opt/cto`** with read+write deploy key [partial verification per wake state — push not yet confirmed].
11. **`/opt/cto/.env` exists** with the secrets from §1.1 populated. **The install script reads this file; missing keys → hard fail.**

### 1.3 Script-checked at runtime
The script's first action verifies each item is present. Missing env vars print a precise message naming what's missing.

---

## Section 2 — Download Packages and Binaries

The script pulls only published packages and binaries. No curl-piping anything already in the repo.

### 2.1 npm packages (global)
- `openclaw@latest` (CLI, gateway, daemon installer — must be v2026.5.6+ for device-code SSH bug fix per OpenClaw issue #74212)
- `@openai/codex` (upstream Codex CLI — drives the device-code OAuth flow that both hemispheres consume; one approval populates `~/.codex/auth.json`)
- `@bitbonsai/mcpvault@latest` (Obsidian-compatible vault MCP)
- `@modelcontextprotocol/server-filesystem` (filesystem MCP)
- `@brave/brave-search-mcp-server` (web search MCP)
- `@lazyants/hetzner-mcp-server` (Hetzner Cloud MCP)

[Package names verified — wiki/openclaw-setup.md and wiki/component-prerequisites.md confirm current correct names.]

### 2.2 Python packages (system, OpenClaw-side MCPs)
- `uvx` (via `uv` install) — runs `mcp-server-fetch` from PyPI on demand
- A2A SDK (Python) — `pip install a2a-sdk` for the A2A registry process [verified — a2a-protocol.org lists Python as a production SDK]

### 2.3 Binary downloads
- **engram** — `github.com/Gentleman-Programming/engram` Go binary, latest release. Linux/amd64. [verified — search result, primary GitHub]
- **github-mcp-server** — `github.com/github/github-mcp-server` Go binary, latest release.
- **hcloud CLI** — `github.com/hetznercloud/cli` latest release.

### 2.4 Hermes installer
- `curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash` — pulls uv-managed Python 3.11, Node 22, ripgrep, ffmpeg under `~/.hermes/`. [verified — hermes-agent.nousresearch.com]

---

## Section 3 — Install OpenClaw and Hermes System Prerequisites

System-level prep both halves need. Idempotent — safe to re-run.

### 3.1 System updates
```bash
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
```

### 3.2 Required system packages
```bash
sudo apt-get install -y \
  git \
  curl \
  build-essential \
  python3.12-venv \
  python3-pip \
  ufw \
  fail2ban \
  sqlite3
```

### 3.3 Node 22 via nvm — already present on VPS per wake state, verify
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
node --version | grep -q "^v22\." || { echo "FAIL: Node 22 not active"; exit 1; }
```

### 3.4 uv (Hermes prereq)
```bash
command -v uv || curl -LsSf https://astral.sh/uv/install.sh | sh
. "$HOME/.local/bin/env" 2>/dev/null || true
```

### 3.5 A2A SDK (Python) for the registry process
```bash
pip install --user a2a-sdk
```

### 3.6 OS tweaks
```bash
# Disable IPv6 for cleaner DNS/routing on the VPS
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6=1" | sudo tee /etc/sysctl.d/99-cto.conf

# Enable systemd user lingering — required so user services survive SSH logout
sudo loginctl enable-linger "$(whoami)"
```

### 3.7 Verification gate
```bash
node --version | grep -q "^v22\." || exit 1
python3 --version | grep -q "Python 3.12" || exit 1
command -v git curl uv pip || exit 1
loginctl show-user "$(whoami)" | grep -q "Linger=yes" || exit 1
python3 -c "import a2a" || exit 1
```

---

## Section 4 — Install OpenClaw and Hermes

Install binaries. No configuration yet.

### 4.1 OpenClaw (already installed per wake state — verify, upgrade if stale)
```bash
command -v openclaw && openclaw --version || npm install -g openclaw@latest
```

### 4.2 engram (Go binary, MCP-native SQLite — replaces memweave)
```bash
ENGRAM_REPO="Gentleman-Programming/engram"
ENGRAM_URL=$(curl -s "https://api.github.com/repos/${ENGRAM_REPO}/releases/latest" \
  | grep "browser_download_url.*linux.*amd64" | head -1 | cut -d '"' -f 4)
curl -sSL "$ENGRAM_URL" -o /tmp/engram
sudo install -m 0755 /tmp/engram /usr/local/bin/engram
engram --version
```

### 4.3 Hermes Agent
```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
. "$HOME/.bashrc" 2>/dev/null || true
hermes --version  # expect v0.13.0+ as of 2026-05-11
```

### 4.4 OpenClaw daemon (systemd user service)
```bash
# OAuth provider deferred to Section 5. Use OpenRouter (optional fallback) for onboard so it succeeds.
# --skip-bootstrap prevents OpenClaw from generating its own SOUL.md/AGENTS.md/etc.
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice "openrouter-api-key" \
  --openrouter-api-key "${OPENROUTER_API_KEY:-noop}" \
  --gateway-port 18789 \
  --gateway-bind loopback \
  --install-daemon \
  --daemon-runtime node \
  --skip-bootstrap \
  --skip-health \
  --workspace /opt/cto
```

### 4.5 Hermes daemon (systemd user service)
```bash
hermes gateway install
systemctl --user daemon-reload
```

### 4.6 GitHub MCP server (Go binary)
```bash
GH_MCP_URL=$(curl -s https://api.github.com/repos/github/github-mcp-server/releases/latest \
  | grep "browser_download_url.*linux-amd64" | head -1 | cut -d '"' -f 4)
curl -sSL "$GH_MCP_URL" -o /tmp/github-mcp-server
sudo install -m 0755 /tmp/github-mcp-server /usr/local/bin/github-mcp-server
```

### 4.7 hcloud CLI
```bash
curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
sudo tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-amd64.tar.gz hcloud
rm hcloud-linux-amd64.tar.gz
hcloud version
```

### 4.8 Verification gate
```bash
for bin in openclaw hermes engram github-mcp-server hcloud; do
  command -v "$bin" || { echo "FAIL: $bin missing"; exit 1; }
done
systemctl --user list-unit-files | grep -E "openclaw|hermes" || { echo "FAIL: gateway units missing"; exit 1; }
```

---

## Section 5 — Configure OpenClaw and Hermes

### 5.1 Codex OAuth — single device-code approval drives both hemispheres [updated 2026-05-11]

**Strategy:** Run the upstream Codex CLI's device-code flow ONCE. That populates `~/.codex/auth.json`. Both OpenClaw and Hermes consume that auth state — Hermes natively imports it; OpenClaw v2026.5.6+ can reuse it (the older bug #74212 that swallowed the SSH device code was fixed in 2026.5.6).

```bash
# Step 1 — ONE device-code flow via upstream Codex CLI
codex login --device-auth
# Prints URL + 8-char code. John opens URL on phone, signs into Business workspace,
# enters code, clicks Authorize. ~/.codex/auth.json is now populated.

# Token sanity check
jq '{auth_mode, last_refresh, has_access_token: ((.tokens.access_token // "") != "")}' ~/.codex/auth.json

# Step 2 — Register profile with OpenClaw (reuses ~/.codex/auth.json on v2026.5.6+)
openclaw models auth login --provider openai-codex --device-code
# If OpenClaw asks for a SECOND device code, approve again on phone.

# Step 3 — Register profile with Hermes (auto-imports ~/.codex/auth.json)
hermes model add openai-codex --device-code  # or interactive: hermes model
```

**Token auto-refresh:** Once authenticated, OpenAI's docs commit to: *"If `last_refresh` is older than about 8 days, Codex refreshes the token bundle before the run continues... If a request gets a 401, Codex also has a built-in refresh-and-retry path."* No manual re-auth needed during normal operation.

**To revoke later:** `chatgpt.com` → Settings → Security → Connected Devices / Active Sessions → find the Codex CLI / OpenClaw / Hermes entries → revoke. CTO loses access on next refresh attempt.

### 5.2 OpenClaw config — write `/home/cto/.openclaw/openclaw.json`

Full reference in `wiki/openclaw-setup.md`. Key blocks below — **no Telegram (removed per architecture-decisions-john.md #9), no sandbox gating (full autonomy per #3, #8)**:

```json
{
  "env": {
    "OPENROUTER_API_KEY": "${OPENROUTER_API_KEY}",
    "GITHUB_TOKEN": "${GITHUB_TOKEN}",
    "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}",
    "BRAVE_API_KEY": "${BRAVE_API_KEY}",
    "OPENAI_API_KEY": "${OPENAI_API_KEY}"
  },
  "gateway": { "bind": "loopback", "auth": { "mode": "token" }, "port": 18789 },
  "skills": { "autoInstall": false },
  "plugins": { "entries": { "bonjour": { "enabled": false } } },
  "agents": {
    "defaults": {
      "workspace": "/opt/cto",
      "model": {
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": ["openrouter/openrouter/auto"]
      },
      "thinkingDefault": "adaptive",
      "sandbox": { "mode": "off" },
      "memorySearch": { "extraPaths": ["/opt/cto/wiki", "/opt/cto/logs/decisions"] }
    }
  },
  "mcp": {
    "servers": {
      "engram":   { "command": "engram", "args": ["mcp-server"] },
      "vault":    { "command": "npx", "args": ["-y", "@bitbonsai/mcpvault@latest", "/opt/cto/wiki"] },
      "filesystem": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-filesystem", "/opt/cto"] },
      "github":   { "command": "/usr/local/bin/github-mcp-server", "args": [], "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}" } },
      "brave-search": { "command": "npx", "args": ["-y", "@brave/brave-search-mcp-server"], "env": { "BRAVE_API_KEY": "${BRAVE_API_KEY}" } },
      "fetch":    { "command": "uvx", "args": ["mcp-server-fetch"] },
      "hetzner":  { "command": "npx", "args": ["-y", "@lazyants/hetzner-mcp-server"], "env": { "HETZNER_API_TOKEN": "${HETZNER_API_TOKEN}" } }
    }
  }
}
```

Validate with `openclaw doctor` before proceeding.

### 5.3 Hermes config — `~/.hermes/config.yaml` + `~/.hermes/.env`
```bash
hermes config set model openai-codex/gpt-5.5
# Keep default port 8642 — no conflict with OpenClaw 18789
hermes config set gateway.port 8642
hermes config set gateway.bind loopback

# Hermes API server (for A2A and HTTP health checks)
hermes config set api_server.enabled true
hermes config set api_server.key "${HERMES_API_SERVER_KEY}"

# File permissions on .env (sensitive)
chmod 0600 ~/.hermes/.env

# Optional embedding key
[ -n "${OPENAI_API_KEY:-}" ] && hermes config set OPENAI_API_KEY "${OPENAI_API_KEY}"
```

### 5.4 A2A registry (the corpus callosum AND the path to the human interface)

Per architecture-decisions-john.md #9, A2A is the comms layer (replacing Telegram). For this install we set up:
1. A small A2A registry process where both hemispheres publish their Agent Cards.
2. Each hemisphere's Agent Card declares its capabilities.
3. Each hemisphere has `a2a_delegate` configured against the registry.

```bash
# Create registry dir + service
mkdir -p /opt/cto/a2a/registry
cat > /opt/cto/a2a/registry/server.py <<'EOF'
# Minimal A2A registry — serves Agent Cards over HTTP + JSON-RPC 2.0
# Implementation pulls from a2a-sdk per a2a-protocol.org spec
# (Body of script written separately; this is the install plan, not the script)
EOF

# systemd user service
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/cto-a2a-registry.service <<'EOF'
[Unit]
Description=CTO A2A Registry (Agent Card discovery + delegation)
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/cto/a2a/registry/server.py
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now cto-a2a-registry
```

Both Agent Cards published at registry startup. Card JSONs live in `/opt/cto/a2a/registry/cards/`.

### 5.5 Human interface (deferred — separate phase)
The human-facing interface on top of A2A is out of scope for v1.0 install. v1.0 ships with the A2A registry and both Agent Cards published; the interface (web UI / phone-accessible client) is a v1.1 build. Until it exists, John interacts with CTO via direct A2A calls from his laptop's Claude Code session (already paired via Remote Control).

### 5.6 Verification gate
```bash
openclaw doctor      # schema valid, gateway reachable
ss -tlnp | grep -E ":18789|:8642"   # both ports bound, loopback
systemctl --user is-active openclaw-gateway hermes-gateway cto-a2a-registry
curl -s http://127.0.0.1:8642/health   # Hermes health
curl -s http://127.0.0.1:18789/healthz  # OpenClaw health (if equivalent endpoint exists; confirm during install)
```

---

## Section 6 — Post-Configuration Tasks

### 6.1 Start daemons
```bash
systemctl --user start openclaw-gateway hermes-gateway cto-a2a-registry
systemctl --user enable openclaw-gateway hermes-gateway cto-a2a-registry
```

### 6.2 Firewall (network-layer defense in depth — NOT autonomy gating)
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw --force enable

sudo systemctl enable --now fail2ban
```
Gateway ports stay loopback-bound. UFW protects against external access to anything else.

### 6.3 First Codex OAuth check
```bash
# Confirm both auth profiles work
openclaw models test --provider openai-codex
hermes model test  # equivalent — confirm exact command during install
```

### 6.4 A2A smoke test — bidirectional delegation
See `test-plan.md` Section 2 for the canonical first-real-prompt test that exercises both hemispheres end-to-end.

### 6.5 Initialise the backlog
- `BACKLOG.md` already at repo root
- `logs/backlog/INDEX.md` already present
- Daily report definition in `HEARTBEAT.md` already updated (Telegram section will be removed via the cascading Telegram-removal doc pass)

### 6.6 Decision log entries
- `logs/decisions/CTO-DECISION-005.json` — two-hemisphere adoption (already logged 2026-05-11)
- `logs/decisions/CTO-DECISION-006.json` — formal Telegram removal + A2A human-interface adoption (write during install)
- `logs/decisions/CTO-DECISION-007.json` — initial two-hemisphere install state (versions, ports, profile names, registry config) — written by the script at completion as the rollback reference point

### 6.7 Repo push
```bash
cd /opt/cto
git add -A
git commit -m "Initial two-hemisphere install (DECISION-005, DECISION-006, DECISION-007)"
git push origin main
```
**Snapshot skipped per John's direction.**

### 6.8 Final install report (no Telegram)
Script writes a structured summary to `/opt/cto/logs/install/install-$(date +%Y%m%d-%H%M%S).log` containing:
- Versions installed (openclaw, hermes, engram, mcp servers, hcloud, a2a-sdk)
- Ports bound
- Codex OAuth auth profile names for both halves
- A2A registry status + Agent Card paths
- BACKLOG.md initial entry count
- Test plan checklist results from §6.4

John reviews the log file via Remote Control. No external messaging in v1.0.

---

## Idempotency

Every section safe to re-run. Package installs check `command -v` first. Config writes check existing state. systemd `enable` is idempotent. Script never modifies CTO repo state (only writes to `~/.openclaw/`, `~/.hermes/`, `/opt/cto/a2a/`, `/usr/local/bin/`, `/etc/sysctl.d/`).

## What This Replaces

`scripts/install.sh` (OpenClaw-only, OpenRouter-only, last touched 2026-05-03). Archive the old one to `scripts/archive/install-openclaw-only.sh` after the new script validates.

## Relationships

- [hemisphere.md](hemisphere.md) — architecture being installed
- [hermes.md](hermes.md) — right hemisphere reference
- [test-plan.md](test-plan.md) — verification plan run during/after install
- [BACKLOG.md](BACKLOG.md) — gaps surface here
- [wiki/openclaw-setup.md](wiki/openclaw-setup.md), [wiki/codex-oauth-setup.md](wiki/codex-oauth-setup.md), [wiki/architecture-decisions-john.md](wiki/architecture-decisions-john.md)
- [logs/decisions/CTO-DECISION-005.json](logs/decisions/CTO-DECISION-005.json) — two-hemisphere decision
- [logs/decisions/CTO-DECISION-006.json](logs/decisions/CTO-DECISION-006.json) — Telegram removal + A2A human interface

## Sources

Live research 2026-05-11:
- [OpenClaw Install Docs](https://docs.openclaw.ai/install)
- [Hermes Agent Installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation)
- [Hermes Agent API Server](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server) — port 8642 default, `/health` endpoint
- [engram on GitHub](https://github.com/Gentleman-Programming/engram) — Go binary, MCP-native SQLite + FTS5
- [A2A Protocol](https://a2a-protocol.org/latest/)
- [github-mcp-server releases](https://github.com/github/github-mcp-server)
- [hcloud CLI releases](https://github.com/hetznercloud/cli)
