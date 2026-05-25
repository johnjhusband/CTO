# Tools & Conventions

## Infrastructure
- **VPS:** Hetzner 116.203.68.119, cx43 (8 vCPU, 16 GB RAM, 150 GB disk) [verified — Hetzner API confirms]
- **SSH:** cto-deploy key, user `cto` (non-root) [verified — SSH tested]
- **Git:** github.com/johnjhusband/CTO (private repo) [verified — pushes work]
- **Git on VPS:** Deploy key for SSH access to GitHub [verified — git fetch works]
- **Upgrade testing:** Fresh Hetzner VPS via API [verified — create/delete tested], never Docker, never in-place

## Two-Hemisphere Stack (as of CTO-DECISION-005, 2026-05-11)
- **Left hemisphere — OpenClaw:** installed on VPS at /opt/cto [verified 2026-04-27]. Gateway via systemd. Config: `~/.openclaw/config.yaml`. Auth: `openclaw models auth login --provider openai-codex --device-code` [verified at docs.openclaw.ai].
- **Right hemisphere — Hermes Agent:** not yet installed. Install path: `curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash`. Config: `~/.hermes/config.yaml` + `~/.hermes/.env`. Auth: device-code flow via `hermes model`, can import `~/.codex/auth.json` if OpenClaw auth ran first [verified at hermes-agent.nousresearch.com].
- **Corpus callosum — A2A protocol:** Linux Foundation, JSON-RPC 2.0 + HTTP + SSE, Agent Cards for capability discovery [verified at a2a-protocol.org]. Not yet wired between hemispheres.
- **MCP config key (OpenClaw):** `mcp.servers` (NOT `mcpServers`) [verified against OpenClaw docs]

## LLM
- **Primary:** ChatGPT Pro $200/mo on `cto@husband.llc` via Codex OAuth, shared by both hemispheres [CTO-DECISION-013, 2026-05-24 — exercising the Pro-escape clause of CTO-DECISION-008]
- **Hermes auxiliary tasks (session_search, compression):** pinned at `openai-codex/gpt-5.5` with 60s timeout via `auxiliary.session_search.*` and `auxiliary.compression.*` in `~/.hermes/config.yaml` [CTO-DECISION-015, 2026-05-25]. Same model as main loop because `gpt-5-mini` is blocked under ChatGPT-account Codex.
- **Embeddings:** separate `OPENAI_API_KEY` for `text-embedding-3` (Codex subscription does NOT cover embeddings)
- **No OpenRouter:** retired across both hemispheres 2026-05-24 [CTO-DECISION-014]. If Codex quotas ever throttle, the rollback path is to restore `~/.codex/auth.json.bak-john-business-*` (Business seat under john@husband.llc) — same OAuth mechanism, different account.

## A2A2H session-key auth
- Hermes' API server requires `Authorization: Bearer ${API_SERVER_KEY}` from anyone sending `X-Hermes-Session-Key` (the session-continuity header). Both sides need the matching value:
  - `hermes-gateway`: `API_SERVER_KEY` env var, set via systemd drop-in `~/.config/systemd/user/hermes-gateway.service.d/30-api-key.conf` [CTO-DECISION-015]
  - `cto-hermes-a2a-sidecar`: `HERMES_API_SERVER_KEY` env var, set via `~/.config/systemd/user/cto-hermes-a2a-sidecar.service.d/10-api-key.conf` [CTO-DECISION-015]
- Value sourced from `HERMES_API_SERVER_KEY` in `/opt/cto/.env` (generated once by `scripts/install-cto.sh`).

## Communication
- **Outbound (CTO → John):** A2A protocol with a human-facing interface built/exposed on top [adopted CTO-DECISION-006, 2026-05-11; human interface implementation deferred to v1.1]. Interim: John reads `/opt/cto/logs/install/*.log`, decision JSON files, and BACKLOG.md directly.
- **Inbound (Dev sessions, Claude Code on John's laptop):** Anthropic Remote Control via `claude --rc` [verified setup 2026-05-11].
- **Removed:** Telegram Bot and Gmail SMTP fallback — both retired by CTO-DECISION-006. The @HusbandCTObot can be revoked via @BotFather at John's convenience.

## Memory & Knowledge
- **Knowledge base:** wiki/ directory indexed for search via memorySearch.extraPaths [verified config key exists]
- **Knowledge layer:** Obsidian-compatible markdown vault via MCPVault MCP server [verified — MCPVault tested locally]
- **SQLite coordination:** engram (Go binary, MCP-native, 17 tools) [installed — replaced memweave which had poor search quality]
- **Hermes memory layer (when installed):** Curator agent + FTS5 cross-session recall + Honcho dialectic user modelling, in `~/.hermes/` [verified — Hermes AGENTS.md]

## Process / Logs
- **Decision logs:** logs/decisions/ as JSON per decision-log-format wiki page [verified — 5 entries exist as of 2026-05-11]
- **Capability gap log:** BACKLOG.md (top-level) + logs/backlog/*.json [established 2026-05-11]
- **Skills (OpenClaw side):** skills/ directory, snapshot-loaded at session start [verified against OpenClaw docs]
- **Skills (Hermes side, when installed):** `skills/` and `optional-skills/` under Hermes install, plus Curator-auto-created skills in `~/.hermes/`
- **Version tags:** v{x.y.z} for active, v{x.y.z}-archived-{date} for replaced [defined, not yet tested]
