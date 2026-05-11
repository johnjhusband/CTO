# CTO Architecture
**L0:** **Two-hemisphere brain** on Hetzner VPS — OpenClaw (left, thinking) + Hermes Agent (right, doing) + A2A protocol (corpus callosum). Both halves on Codex OAuth via one ChatGPT Pro. Five-layer pattern (Brain/Hands/Memory/Spine/Guardrails) mapped across the hemispheres. No Docker. Fully autonomous for self-improvement. engram for SQLite.
**L1:** Two-hemisphere design adopted 2026-05-11 (CTO-DECISION-005), superseding the single-framework decision from 2026-04-26 (CTO-DECISION-001). OpenClaw is the orchestrator/thinking hemisphere: inbound messaging gateway, planning, task decomposition, final-mile delivery. Hermes is the worker/doing hemisphere: skill execution, GEPA learning loop, Phase 1-4 self-evolution (skills/prompts/tool descriptions/tool code) generating PRs against the CTO repo. A2A protocol (Linux Foundation, 150+ orgs) is the corpus callosum — each hemisphere exposes an Agent Card, either can call `a2a_delegate` on the other. No Docker — CTO manages its own system-level components directly. Fully autonomous for self-improvement; Hermes-generated PRs feed the existing clone-test-replace upgrade cycle. Anything beyond Phase 1-4 scope (kernel, memory ABC, gateway core, framework swap) → BACKLOG.md for John's review.
**Last updated:** 2026-05-11
**Verification:** Two-hemisphere expansion documented in hemisphere.md and hermes.md (both built from primary-source research 2026-05-11). Five-layer pattern verified against community consensus.
**Source:** [hemisphere.md](../hemisphere.md), [hermes.md](../hermes.md), architecture validation (4 agents) + John's decisions. See [architecture-decisions-john.md](architecture-decisions-john.md) and [architecture-validation-results.md](architecture-validation-results.md).

## Hemisphere Mapping

| Hemisphere | Framework | Role | Primary Responsibilities |
|---|---|---|---|
| **Left** | OpenClaw | Thinking — orchestrator | Inbound messaging, planning, task decomposition, delegating execution to Hermes, final-mile delivery to user |
| **Right** | Hermes Agent | Doing — worker | Skill execution, GEPA self-evolution loop (Phase 1-4: skills, prompts, tool descriptions, tool code), learning from execution traces, returning structured findings to OpenClaw |
| **Corpus callosum** | A2A protocol | Bidirectional delegation | Agent Cards for capability discovery, JSON-RPC 2.0 over HTTP, sync/streaming/async modes |

See [hemisphere.md](../hemisphere.md) for the full design, failure modes, and the BACKLOG.md flow for anything outside Hermes's Phase 1-4 scope.

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
- OpenClaw gateway for orchestration, cron, intra-VPS messaging [verified against docs]
- Cron jobs persist across restarts [verified]
- **A2A protocol** is the communication layer — hemisphere-to-hemisphere AND CTO-to-John (CTO-DECISION-006, 2026-05-11). Human-facing interface built/exposed on top of A2A in a subsequent phase.
- Telegram and Gmail SMTP removed from the spine (CTO-DECISION-006 supersedes CTO-DECISION-003).
- See [protocol-layer.md](protocol-layer.md) and [hemisphere.md](../hemisphere.md)

### 5. Guardrails — Safety + Oversight
- GUARDRAILS.md + FAILURE.md (advisory, loaded every session) [verified — OpenClaw auto-loads]
- **Fully autonomous for self-improvement** — narrowly scoped, verifiable domain [settled by John]
- John's oversight: daily reports, corrections, kill switch, spending approval [settled by John]
- Budget caps on API spend [design — not yet implemented]
- Architecture validation process before upgrades [documented and tested]
- No blocking approval gates except spending [settled by John]

## Framework: Two-Hemisphere (OpenClaw + Hermes)
OpenClaw selected as the left hemisphere for ecosystem breadth and messaging integration [decision CTO-DECISION-001, 2026-04-26]. Hermes Agent added as the right hemisphere for self-evolution depth [decision CTO-DECISION-005, 2026-05-11]. The two communicate over A2A protocol. Known OpenClaw memory and reliability issues mitigated by our augmented memory layer; Hermes brings its own memory architecture (Curator + FTS5 + Honcho) and skill auto-creation. See [architecture-decisions-john.md](architecture-decisions-john.md) and [hemisphere.md](../hemisphere.md).

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
- **Primary VPS:** Hetzner 116.203.68.119 (cx43: 8 vCPU, 16 GB RAM, 150 GB disk) [verified]
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
