# Tools & Conventions

- **VPS:** Hetzner 178.104.213.9, cx43 (8 vCPU, 16 GB RAM, 150 GB disk) [verified — Hetzner API confirms]
- **SSH:** cto-deploy key, user `cto` (non-root) [verified — SSH tested]
- **Git:** github.com/johnjhusband/CTO (private repo) [verified — pushes work]
- **Git on VPS:** Deploy key for SSH access to GitHub [verified — git fetch works]
- **LLM:** OpenRouter (multi-model, single API key) [verified — API key works, model format confirmed]
- **Communication:** Telegram Bot @HusbandCTObot (primary) [verified — token works], Gmail SMTP (fallback) [unverified]
- **Knowledge base:** wiki/ directory indexed for search via memorySearch.extraPaths [verified config key exists]
- **Knowledge layer:** Obsidian-compatible markdown vault via MCPVault MCP server [verified — MCPVault tested locally]
- **SQLite coordination:** memweave [verified installed, search quality poor — may need alternative]
- **Decision logs:** logs/decisions/ as JSON per decision-log-format wiki page [verified — 4 entries exist]
- **Skills:** skills/ directory, snapshot-loaded at session start [verified against OpenClaw docs]
- **Version tags:** v{x.y.z} for active, v{x.y.z}-archived-{date} for replaced [defined, not yet tested]
- **Upgrade testing:** Fresh Hetzner VPS via API [verified — create/delete tested], never Docker, never in-place
- **MCP config key:** `mcp.servers` (NOT `mcpServers`) [verified against OpenClaw docs]
- **Telegram allowFrom format:** `"tg:ID"` (NOT bare integer) [verified against OpenClaw docs]
