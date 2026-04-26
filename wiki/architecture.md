# CTO Architecture
**L0:** Five-layer architecture (Brain/Hands/Memory/Spine/Guardrails) on OpenClaw with Obsidian+SQLite memory, MCP tools, A2A comms, VPS-based upgrade testing.
**L1:** CTO runs on a Hetzner VPS using OpenClaw as the agent framework. Architecture follows community consensus: multi-model LLM via OpenRouter (Layer 1), tools via MCP standard (Layer 2), Obsidian vault + SQLite + tiered loading for memory (Layer 3), OpenClaw orchestration + A2A protocol (Layer 4), GUARDRAILS.md + FAILURE.md + circuit breakers for safety (Layer 5). Upgrades tested on fresh VPS instances, not Docker. Telegram for notifications. Fully autonomous with post-hoc review.
**Last updated:** 2026-04-26
**Source:** Second research round (8 agents, April 2026) — community consensus patterns

## Key Facts
- Architecture follows the five-layer model the community has converged on
- Built on open standards: MCP (tools), A2A (agent communication), AGENTS.md (context)
- Memory is the moat — models and frameworks are swappable
- Macro evolution tests on fresh Hetzner VPS, not Docker containers
- "Agent = Model + Harness" — the harness matters more than the model

## Five-Layer Architecture

### 1. Brain — LLM + Context Management
- Multi-model via OpenRouter — route 80% to cheap models, escalate for complex
- Context engineering > model selection
- Skills-based context loading (~1,000 tokens metadata vs 10,000 token monolithic prompt)

### 2. Hands — Tools via MCP
- All tool integrations through MCP (97M monthly installs, Linux Foundation standard)
- No custom tool wrappers
- OpenClaw as the agent framework connecting brain to hands

### 3. Memory — The Moat
- **Obsidian-compatible markdown vault** with `[[wikilinks]]`, accessed via filesystem MCP server (Obsidian app on desktop for John, raw files on VPS)
- **SQLite coordination layer** (memweave) for concurrent access and structured queries
- **Tiered loading** (L0/L1/L2 per OpenViking pattern) to minimize token costs
- **SOUL.md** for persistent agent identity
- See [memory-architecture.md](memory-architecture.md) for full details

### 4. Spine — Orchestration + Communication
- OpenClaw gateway for orchestration, cron, messaging
- A2A protocol for future inter-agent communication (CFO, CEO, CMO)
- Telegram Bot for user notifications
- See [protocol-layer.md](protocol-layer.md)

### 5. Guardrails — Safety + Observability
- GUARDRAILS.md — persistent safety constraints surviving context resets
- FAILURE.md — graduated intervention (slowdown → throttle → escalate → shutdown)
- Circuit breakers on all external calls
- Hard budget caps (steps, cost, runtime)
- Human curation checkpoint in research pipeline

## Framework: OpenClaw
Selected after requirements-based evaluation prioritizing macro evolution. See [v1-evaluation.md](v1-evaluation.md).

## Upgrade Cycle: VPS-Based Testing
- Provision fresh Hetzner VPS via API for each upgrade test
- Full system access testing (packages, services, network — not Docker)
- Snapshot current VPS before promotion
- Destroy test VPS after decision
- See [upgrade-cycle.md](upgrade-cycle.md)

## Research Pipeline
- Multi-source ingestion (GitHub, HN, arXiv, YouTube, changelogs)
- LLM relevance scoring + cross-platform deduplication
- Post-hoc review by John (corrections calibrate scoring)
- Telegram daily digest
- See [research-pipeline.md](research-pipeline.md)

## Infrastructure
- **Primary VPS:** Hetzner 178.104.213.9 (8 vCPU, 16 GB RAM, 150 GB disk)
- **Test VPS:** Provisioned on-demand via Hetzner API, destroyed after testing
- **Communication:** Telegram Bot (primary), Gmail SMTP (fallback)
- **LLM:** OpenRouter for multi-model access

## Relationships
- [Memory Architecture](memory-architecture.md)
- [Protocol Layer](protocol-layer.md)
- [Deployment Patterns](deployment-patterns.md)
- [Research Pipeline](research-pipeline.md)
- [Upgrade Cycle](upgrade-cycle.md)
- [Karpathy Patterns](karpathy-patterns.md)
- [Decision Log Format](decision-log-format.md)

## Open Questions
- Hetzner API token for programmatic VPS provisioning
- State migration between VPS instances during promotion
- OpenViking vs Mem0 vs simpler SQLite hybrid for v1 memory
- When to add graph memory (Mem0g) — v1 or later?
