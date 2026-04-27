# CTO Architecture
**L0:** Five-layer architecture on OpenClaw (augmented memory, no Docker). Fully autonomous for self-improvement. OpenRouter for testing, OpenAI for production. engram for SQLite. Built-in web search.
**L1:** CTO runs on Hetzner VPS [verified — cx43 at 178.104.213.9] using OpenClaw [verified — v2026.4.24] with augmented memory layer. No Docker — CTO manages its own system-level components directly. Fully autonomous for self-improvement (narrowly scoped, verifiable domain). OpenRouter for testing [verified], OpenAI subscription for production. engram for SQLite coordination (replacing memweave). OpenClaw's built-in web search [verified — auto-detects providers]. Telegram for notifications [verified]. Architecture validated against community sentiment — see validation results and John's decisions.
**Last updated:** 2026-04-27
**Source:** Architecture validation (4 agents) + John's decisions. See [architecture-decisions-john.md](architecture-decisions-john.md) and [architecture-validation-results.md](architecture-validation-results.md).

## Five-Layer Architecture

### 1. Brain — LLM + Context Management
- OpenRouter for testing [verified — API works], OpenAI Pro/Max for production [settled by John]
- Multi-model routing: cheap for routine, escalate for complex [design]
- Context engineering > model selection [verified — community consensus]
- Skills snapshot-loaded at session start [verified against docs]

### 2. Hands — Tools via MCP
- MCP for tool integrations [verified — 139M downloads, Linux Foundation standard]
- OpenClaw's built-in web search [verified — auto-detects providers, no separate API needed]
- MCPVault for wiki access [verified — tested locally]
- GitHub MCP server (Go binary) [verified — exists]
- Hetzner MCP for VPS management [verified — @lazyants/hetzner-mcp-server]
- MCP config key: `mcp.servers` [verified against docs]

### 3. Memory — Augmenting OpenClaw
OpenClaw's native memory is known to be broken [verified — validation found deal-breaking issues]. Our memory layer augments it:
- **OpenClaw native:** SOUL.md, AGENTS.md, IDENTITY.md, USER.md, TOOLS.md auto-loaded [verified]
- **MEMORY.md:** Curated hot memory, main private session only [verified]
- **Obsidian-compatible vault:** wiki/ with [[wikilinks]], accessed via MCPVault [verified]
- **SQLite coordination:** engram (Go binary, MCP-native, zero deps) [replacing memweave — settled by John]
- **Tiered headers:** L0/L1/L2 on wiki pages [implemented]
- **SOUL.md:** Persistent identity with 15 metacognition principles [implemented]
- See [memory-architecture.md](memory-architecture.md)

### 4. Spine — Orchestration + Communication
- OpenClaw gateway for orchestration, cron, messaging [verified against docs]
- Cron jobs persist across restarts [verified]
- Telegram Bot @HusbandCTObot for notifications [verified — token works]
- A2A protocol for future multi-agent [not in OpenClaw natively — future macro evolution]
- See [protocol-layer.md](protocol-layer.md)

### 5. Guardrails — Safety + Oversight
- GUARDRAILS.md + FAILURE.md (advisory, loaded every session) [verified — OpenClaw auto-loads]
- **Fully autonomous for self-improvement** — narrowly scoped, verifiable domain [settled by John]
- John's oversight: daily reports, corrections, kill switch, spending approval [settled by John]
- Budget caps on API spend [design — not yet implemented]
- Architecture validation process before upgrades [documented and tested]
- No blocking approval gates except spending [settled by John]

## Framework: OpenClaw (Augmented)
OpenClaw selected for ecosystem breadth and messaging integration [decision CTO-DECISION-001]. Known memory and reliability issues mitigated by our augmented memory layer [settled by John]. See [architecture-decisions-john.md](architecture-decisions-john.md).

## No Docker — Non-Negotiable
CTO manages its own system-level components. Docker prevents this. Security isolation via dedicated VPS + dedicated user. Upgrade testing on fresh Hetzner VPS instances. [Settled by John — not open for discussion.]

## Upgrade Cycle
- Architecture validation against community sentiment [new — documented]
- Research the target before touching infrastructure [documented]
- Fresh Hetzner VPS for testing [verified — API tested]
- HANDOFF.md before every promotion [documented]
- Snapshot + git tag for rollback [verified]
- See [upgrade-cycle.md](upgrade-cycle.md)

## Infrastructure
- **Primary VPS:** Hetzner 178.104.213.9 (cx43: 8 vCPU, 16 GB RAM, 150 GB disk) [verified]
- **Test VPS:** On-demand via Hetzner API [verified — create/delete tested]
- **Communication:** Telegram Bot @HusbandCTObot [verified]
- **LLM:** OpenRouter (testing) [verified], OpenAI (production) [available]
- **Web search:** OpenClaw built-in [verified]
- **SQLite:** engram [selected, replacing memweave]

## Relationships
- [John's Architecture Decisions](architecture-decisions-john.md) — settled requirements
- [Validation Results](architecture-validation-results.md) — what the community says
- [Memory Architecture](memory-architecture.md)
- [Protocol Layer](protocol-layer.md)
- [Deployment Patterns](deployment-patterns.md)
- [Upgrade Cycle](upgrade-cycle.md)
- [OpenClaw Setup](openclaw-setup.md)
