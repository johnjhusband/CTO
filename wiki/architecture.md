# CTO Architecture
**L0:** Five-layer architecture (Brain/Hands/Memory/Spine/Guardrails) on OpenClaw with Obsidian-compatible vault + SQLite memory, MCP tools, A2A comms, VPS-based upgrade testing.
**L1:** CTO runs on a Hetzner VPS [verified — cx43 at 178.104.213.9] using OpenClaw [verified — npm package exists v2026.4.24, not yet installed]. Architecture follows community consensus [verified — multiple independent sources]: multi-model LLM via OpenRouter [verified — API works] (Layer 1), tools via MCP standard [verified — 139M monthly downloads verified via npm] (Layer 2), Obsidian-compatible vault + SQLite + tiered loading for memory (Layer 3) [partially verified — MCPVault works, memweave search quality poor], OpenClaw orchestration [verified — cron, heartbeat, gateway confirmed against docs] + A2A protocol [unverified — not in OpenClaw natively] (Layer 4), GUARDRAILS.md + FAILURE.md + circuit breakers for safety (Layer 5) [design — not implemented].
**Last updated:** 2026-04-26
**Source:** Second research round (8 agents, April 2026) — community consensus patterns. Verification against official docs completed.

## Key Facts
- Architecture follows the five-layer model the community has converged on [verified — HyperTrends, 47Billion, Beam.ai, TrueFoundry sources]
- Built on open standards: MCP (tools) [verified — Linux Foundation], A2A (agent communication) [verified — Linux Foundation], AGENTS.md (context) [verified — 60K+ repos claim from research]
- Memory is the moat — models and frameworks are swappable [verified — community consensus from Gartner, Databricks, multiple sources]
- Macro evolution tests on fresh Hetzner VPS, not Docker containers [verified — API tested, conceptually sound]
- "Agent = Model + Harness" — the harness matters more than the model [verified — Harrison Chase, LangChain CEO, Sequoia podcast]

## Five-Layer Architecture

### 1. Brain — LLM + Context Management
- Multi-model via OpenRouter [verified — API key works, 200+ models accessible]
- Route 80% to cheap models, escalate for complex [design principle from community research, unverified in practice]
- Skills-based context loading (~1,000 tokens vs 10,000 monolithic prompt) [unverified — claim from Google ADK research]

### 2. Hands — Tools via MCP
- All tool integrations through MCP [verified — official standard, Linux Foundation]
- MCP config in OpenClaw: `mcp.servers` key [verified against docs]
- No custom tool wrappers [design principle]
- OpenClaw as the agent framework [verified — selected, not yet installed]

### 3. Memory — The Moat
- **Obsidian-compatible markdown vault** with `[[wikilinks]]` [verified — MCPVault tested, wikilinks parseable]
- Accessed via filesystem MCP server on VPS, Obsidian app on desktop for John [verified — Obsidian can't run headless]
- **SQLite coordination layer** (memweave) [verified installed, search quality poor at 0.14 scores — may need alternative]
- **Tiered loading** (L0/L1/L2 per OpenViking pattern) [verified — OpenViking exists 23K stars [verified via GitHub API]. Our L0/L1 headers exist. OpenClaw doesn't natively understand the convention — must be taught via AGENTS.md]
- **SOUL.md** for persistent agent identity [verified — OpenClaw auto-loads it first every session]
- See [memory-architecture.md](memory-architecture.md) for full details

### 4. Spine — Orchestration + Communication
- OpenClaw gateway for orchestration, cron, messaging [verified against docs]
- A2A protocol for future inter-agent communication [verified A2A exists as Linux Foundation standard. Unverified whether OpenClaw supports A2A natively — research suggests it doesn't]
- Telegram Bot for user notifications [verified — token works, bot exists]
- See [protocol-layer.md](protocol-layer.md)

### 5. Guardrails — Safety + Observability
- GUARDRAILS.md — persistent safety constraints [design — advisory only, not enforced by OpenClaw]
- FAILURE.md — graduated intervention [design — not implemented]
- Circuit breakers on all external calls [design — not implemented]
- Hard budget caps (steps, cost, runtime) [design — not implemented]
- Post-hoc review by John (corrections calibrate scoring) [design — explicit from John]

## Framework: OpenClaw
Selected after requirements-based evaluation [verified — decision logged CTO-DECISION-001]. See [v1-evaluation.md](v1-evaluation.md).

## Upgrade Cycle: VPS-Based Testing
- Provision fresh Hetzner VPS via API [verified — create/delete tested]
- Full system access testing [verified — conceptually sound, Docker can't test system-level]
- Snapshot current VPS before promotion [verified — snapshot API confirmed]
- Destroy test VPS after decision [verified — delete stops billing confirmed]
- Cost per test cycle: ~EUR 0.05 [verified — Hetzner pricing confirmed]
- See [upgrade-cycle.md](upgrade-cycle.md)

## Research Pipeline
- Multi-source ingestion (GitHub, HN, arXiv, YouTube, changelogs) [design — not implemented]
- LLM relevance scoring + cross-platform deduplication [design — not implemented]
- Post-hoc review by John [design — explicit from John]
- Telegram daily digest [verified — bot works]
- SearXNG for web search [verified — official OpenClaw provider]
- See [research-pipeline.md](research-pipeline.md)

## Infrastructure
- **Primary VPS:** Hetzner 178.104.213.9 (cx43: 8 vCPU, 16 GB RAM, 150 GB disk) [verified — Hetzner API confirms]
- **Test VPS:** Provisioned on-demand via Hetzner API [verified — tested]
- **Communication:** Telegram Bot @HusbandCTObot (primary) [verified], Gmail SMTP (fallback) [verified — reachable, TLS works]
- **LLM:** OpenRouter [verified — API key works]

## Open Questions
- ~~Hetzner API token~~ RESOLVED [verified — token works, SSH key uploaded]
- State migration between VPS instances during promotion [open]
- memweave search quality is poor — alternative needed? [open, verified by testing]
- A2A not native in OpenClaw — how to add for multi-agent future? [open]
- SearXNG vs Brave for web search [open — SearXNG is free but needs Docker]
