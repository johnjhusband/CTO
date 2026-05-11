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
- **Primary:** ChatGPT Pro $200/mo via Codex OAuth, shared by both hemispheres [verified — both halves support `openai-codex` provider, see wiki/codex-oauth-setup.md and hermes.md Provider section]
- **Embeddings:** separate `OPENAI_API_KEY` for `text-embedding-3` (Codex subscription does NOT cover embeddings)
- **Fallback:** OpenRouter (multi-model, single API key) [verified — API key works, model format confirmed]

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
