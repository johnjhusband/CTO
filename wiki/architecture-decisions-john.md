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

### 9. Communication: Replace Telegram with A2A-Based Interface
Telegram has limitations: bot conflict when cloning (two CTOs can't share one bot), no programmatic bot creation via BotFather, `/approve` cards don't work on mobile. Investigating A2A (Google's Agent-to-Agent protocol) as the communication layer with a human-facing interface built on top. If A2A is open source, building a human interface is simpler than a full agent-to-agent system.

### 10. Git Access: Read/Write
CTO needs read AND write access to its git repo. The previous deploy key was read-only, which blocked CTO from pushing changes. Deploy keys or PATs must have write access.
