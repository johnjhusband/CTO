# Architecture Decisions — John's Requirements
**L0:** John's explicit requirements that override validation findings. Memory augments OpenClaw. OpenRouter for testing. Full autonomy for self-improvement. No Docker. CTO manages itself.
**L1:** John reviewed the architecture validation results and made clear decisions. These are not open questions — they are settled requirements.
**Last updated:** 2026-04-27

## John's Decisions (Settled — Not Open Questions)

### 1. Memory: Augment OpenClaw, Don't Depend On It
OpenClaw's native memory is broken. We know this. We are adding our own memory layer on top (Obsidian-compatible vault + SQLite via engram + tiered loading). OpenClaw's memory problems are mitigated by our design, not by fixing OpenClaw.

### 2. LLM Provider: ChatGPT Pro ($200/mo) via Codex OAuth
OpenRouter proved unreliable (ran out of credits, key limit confusion, outages). Switching to ChatGPT Pro $200/month subscription accessed through OpenClaw's `openai-codex` provider via OAuth. Flat rate, no per-token billing. [verified — OpenAI explicitly allows subscription access through OpenClaw]. OpenRouter remains available as fallback if needed.

### 3. Autonomy: Fully Autonomous for Self-Improvement
The validation found 88% of orgs report AI agent incidents. That applies to general-purpose agents. CTO is narrowly scoped — its only job is to improve itself. This is a verifiable domain (the community confirmed self-improvement works in verifiable domains). Full autonomy for self-improvement is critical to the mission. John provides oversight via reports, corrections, and kill switch — not pre-approval gates.

### 4. No Docker — Non-Negotiable
Docker prevents CTO from managing its own system-level components (packages, services, network, cron). This defeats a core tenet: CTO must be able to manage itself. The VPS-based clone-test-replace cycle tests on fresh VPS instances instead. Security isolation comes from dedicated VPS and dedicated user, not containers.

### 5. Web Search: OpenClaw's Built-In Search
OpenClaw has native web search that auto-detects available providers [verified]. No separate search API (Brave, SearXNG, Tavily) is needed. If CTO determines a dedicated search API would improve research quality, it can adopt one as a macro evolution decision.

### 6. SQLite Coordination: engram
Replacing memweave (single-author, no benchmarks, poor search quality verified at 0.14 scores) with engram (Go binary, zero dependencies, MCP-native, single binary deployment). CTO can manage engram at the system level.

### 7. John's Oversight Model
John provides oversight through:
- Reviewing daily Telegram reports (after the fact, not blocking)
- Correcting bad decisions (corrections feed back into SOUL.md and scoring)
- Kill switch (can stop the agent)
- Approving spending (the only blocking gate)
- Periodic architecture review

The autonomy of this agent for self-improvement is critical. Do not add blocking approval gates.

### 8. Elevated Exec: Auto-Approved
CTO can run sudo/elevated commands without human approval. The OpenClaw `/approve` mechanism doesn't work from Telegram mobile (no approval card appears). John accepted the security risk for full autonomy. Configure `tools.elevated.allowFrom` to include all channels.

### 9. Communication: A2A Replaces Telegram — Settled 2026-05-11 (CTO-DECISION-006)
Telegram is removed from the architecture. A2A protocol is the communication layer: it carries hemisphere-to-hemisphere traffic (the corpus callosum from CTO-DECISION-005) AND CTO-to-John traffic. A human-facing interface is built or exposed on top of A2A in a subsequent phase — interim, John uses Claude Code Remote Control sessions for direct interaction. The settled rationale (originally framed "Investigating" on 2026-04-27): Telegram bot conflict when cloning, no programmatic bot creation via BotFather, `/approve` cards broken on mobile (OpenClaw #23856, #51245, #48499), proactive-messaging bootstrap friction. A2A is open standard (Linux Foundation, 150+ orgs); single-protocol comms stack simplifies the architecture.

### 10. Git Access: Read/Write
CTO needs read AND write access to its git repo. The previous deploy key was read-only, which blocked CTO from pushing changes. Deploy keys or PATs must have write access.

### 11. Two-Hemisphere Architecture (2026-05-11)
Adopt Hermes Agent as the right hemisphere alongside OpenClaw (left hemisphere). OpenClaw thinks — orchestrator, gateway, planner, router. Hermes does — worker, skill execution, GEPA self-evolution. A2A protocol is the corpus callosum (Linux Foundation, 150+ orgs in production). Both run on the same ChatGPT Pro $200/mo subscription via Codex OAuth (flat rate, no per-token billing). This supersedes the 2026-04-26 single-framework decision (CTO-DECISION-001) — that decision picked OpenClaw because macro evolution outweighs micro evolution; the two-hemisphere design preserves macro as the primary mission while giving micro a dedicated engine that doesn't compete with macro for cycles. Hermes's Phase 1-4 self-evolution (skills, prompts, tool descriptions, tool implementation code) generates PRs against the CTO repo and feeds the existing clone-test-replace upgrade cycle for validation. Anything outside Phase 1-4 (kernel, memory ABC, gateway core, framework swap) → BACKLOG.md for John's review. See `hemisphere.md`, `hermes.md`, and CTO-DECISION-005.
