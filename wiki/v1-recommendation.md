# CTO v1 — Architecture Recommendation
**Last updated:** 2026-04-26
**Source:** Synthesis of all live web research (13 research agents across 2 rounds, April 2026)

## Executive Summary

After researching 20+ tools across the autonomous agent landscape — frameworks, coding agents, memory systems, LLM providers, communication channels, YouTube pipelines, and orchestration tools — here is the recommended architecture for CTO v1.

The research surfaced a much richer landscape than initially expected. Key discoveries in round 2: OpenHands (autonomous software engineering), Cline CLI 2.0 (headless coding agent), Letta (persistent memory), Darwin Godel Machine (self-improvement patterns), and Karpathy's frameworks (LLM Wiki, AutoResearch, Agentic Engineering).

## Framework: Hermes Agent (Primary) + OpenHands (Coding Engine)

### Why a two-layer architecture:

The research revealed no single tool does everything CTO needs. The strongest approach combines:

1. **Hermes Agent** — the persistent orchestration layer (24/7 service, cron, messaging, memory, self-improvement)
2. **OpenHands** — the coding execution engine (autonomous code changes in sandboxed Docker)

| Requirement | Hermes Agent | OpenHands | Combined |
|-------------|-------------|-----------|----------|
| Runs 24/7 on VPS | YES | YES | YES |
| Self-improving | YES (learning loop) | No native self-improvement | Via Hermes layer |
| Autonomous coding | No (general agent) | YES (SWE-bench 77.6%) | YES |
| Multi-model | 200+ (OpenRouter) | 100+ (LiteLLM) | YES |
| Messaging | 16 platforms | No | YES (via Hermes) |
| Cron scheduling | Built-in | No | YES (via Hermes) |
| MCP support | YES | No | YES (via Hermes) |
| Sandboxed execution | No | YES (Docker) | YES (via OpenHands) |
| License | MIT | MIT | MIT |

### Alternatives considered:

| Alternative | Why not primary |
|-------------|----------------|
| **Agent Zero** (17.3K stars) | Fallback if Hermes too immature. Docker-native, self-modifying. Smaller community. |
| **Cline CLI 2.0** (~61K stars) | Strong headless coding agent. Could replace OpenHands. Less autonomous (pair programmer, not engineer). |
| **OpenClaw** (364K stars) | 512 security vulnerabilities. Learn from patterns, don't deploy. |
| **Letta** (22.3K stars) | Best memory system but full runtime lock-in. Too constraining for v1. |
| **AutoGPT Platform** (184K stars) | Visual workflow builder. Overkill for single agent. Polyform Shield license. |
| **CrewAI** (49.9K stars) | Multi-agent collaboration, not self-modification. |
| **Devin/Manus/Cursor** | Cloud-only, cannot run on Hetzner VPS. |

### Risks to manage:
- Hermes Agent is 2 months old — expect rough edges
- Security defaults are ALLOW-ALL — must harden before deployment
- Learning loop can learn incorrect patterns — needs monitoring
- GODMODE skill should be disabled
- OpenHands can burn $50/day in API calls if uncapped — implement budget limits

## LLM Provider: OpenAI API via OpenRouter

**Why:**
- Budget-constrained — no open-ended token spend
- Multi-model routing: cheap models for routine, escalate for complex
- OpenRouter: single API key for 200+ models
- ChatGPT Pro ($200/mo) is UI-only, cannot be used programmatically

**Model strategy:**
| Task | Model | Cost |
|------|-------|------|
| Daily research summarization | GPT-5.4 nano (~$0.10/$0.40 per M) | Pennies/day |
| Technology evaluation | GPT-5.4 mini ($0.75/$4.50 per M) | ~$0.05-0.50/eval |
| Complex decisions / code changes | o4-mini ($1.10/$4.40 per M) | ~$0.10-1.00/decision |
| Emergency / hard problems | GPT-5.4 ($2.50/$15 per M) | As needed |

**Estimated monthly LLM cost: $5-30** depending on volume and model mix.

Hermes Agent supports switching models mid-session with `hermes model`. CTO can evaluate and switch its own LLM as part of self-upgrade.

## Memory: Karpathy LLM Wiki Pattern + Hermes Skills

Two complementary memory systems:

1. **LLM Wiki (Karpathy pattern)** — CTO's `wiki/` directory. Three layers:
   - `raw/` — immutable source material (transcripts, articles, changelogs)
   - `wiki/` — LLM-maintained interlinked markdown pages
   - Periodic lint/audit for contradictions and orphan pages

2. **Hermes Agent learning loop** — auto-creates reusable skills from successful tasks. 40% speedup on repeat work. FTS5 search over all sessions.

**Why not Letta?** Most sophisticated memory (3-tier self-editing), but it's a full runtime replacement with high lock-in. The wiki pattern + Hermes skills give 80% of the value with full flexibility. Letta remains an option for v2 if memory proves insufficient.

## Communication: Telegram Bot (Primary)

**Why Telegram over WhatsApp:**
- Free, zero ban risk, 5-minute setup
- Rich formatting (Markdown/HTML), file attachments, inline keyboards
- 30 messages/second rate limit
- Simple HTTP API — one curl command sends a message
- WhatsApp official is overkill for one person ($30-100/mo)
- WhatsApp unofficial carries high ban risk in 2026

**Stack:**
1. **Primary:** Telegram Bot API
2. **Fallback:** Gmail SMTP (100 emails/day free)
3. **Optional later:** ntfy (self-hosted push), Discord webhooks (rich logging)

## YouTube Research Pipeline

**Primary pipeline:**
1. YouTube Data API v3 for video discovery (1 unit/call, 10K units/day free)
2. `youtube-transcript-api` Python library for transcript extraction (free, no auth)
3. Gemini 2.5 Flash for summarization ($0.30/M input tokens)

**Fallback chain:**
- youtube-transcript-api fails → yt-dlp with `--write-auto-subs`
- No captions → Gemini API multimodal (YouTube URL directly, 8hrs/day limit)
- Last resort → yt-dlp audio download + Whisper transcription

**Channels to monitor:** Matt Wolfe, Matthew Berman, AI Explained, The AI Grid, Corbin Brown, Developers Digest, Yannic Kilcher + GitHub Trending, HN, product changelogs.

## Coding Tools (Callable by CTO)

CTO invokes these as tools for specific coding tasks, not as the agent itself:

| Tool | Best For | License |
|------|----------|---------|
| **OpenHands** | Autonomous multi-file engineering | MIT |
| **Cline CLI** | Quick headless coding tasks | Apache 2.0 |
| **Aider** | Git-native pair programming | Apache 2.0 |

## Infrastructure: Hetzner VPS

- **Existing:** 116.203.68.119 (shared with DFU Mortgages)
- **Decision needed:** Use existing VPS or provision dedicated CTO instance
- **Minimum specs:** CX22 (2 vCPU, 4GB RAM, ~EUR 5-7/mo) — sufficient since LLM runs via API
- **If self-hosted LLM ever needed:** AX42 dedicated (64GB RAM, ~EUR 55-60/mo)
- **Best self-hosted models (if needed):** Qwen3-8B (16GB) or Qwen3-30B-A3B (32GB+)

## Karpathy Patterns Informing the Design

See [karpathy-patterns.md](karpathy-patterns.md). Key patterns applied:

1. **LLM Wiki for memory** — compile knowledge, don't re-search every session
2. **The Karpathy Loop** — immutable test suite + modifiable code + human direction. Measurable metric = test pass rate.
3. **Agentic Engineering** — orchestrate sub-agents for research, evaluation, testing
4. **Constraint over ambition** — each upgrade targets ONE capability, narrow and measurable
5. **Success criteria over instructions** — tell CTO WHAT to achieve, not HOW
6. **Ghost awareness** — design for pattern-matching strength, add verifiable checkpoints
7. **Three-file contract** — evaluator (tests) + implementation (code) + direction (PRD)

## Future: Multi-Agent Orchestration

When CTO is stable and it's time to build CFO, CEO, CMO:

| Tool | Role |
|------|------|
| **Paperclip** (53-58K stars, MIT) | Agent company management: org charts, budgets, goals, audit trails |
| **Google ADK** (A2A protocol) | Inter-agent communication standard (150+ orgs in production) |
| **Mastra** (22.3K stars, Apache 2.0) | TypeScript agent framework with 3,300+ model router |

## Cost Summary (CTO v1)

| Item | Monthly Cost |
|------|-------------|
| Hetzner VPS (CX22) | ~EUR 5-7 |
| LLM API (OpenRouter) | ~$5-30 |
| Telegram Bot | Free |
| Gmail SMTP | Free |
| youtube-transcript-api | Free |
| Gemini Flash (summaries) | ~$1-5 |
| **Total** | **~$12-45/month** |

## What's NOT in v1
- ChatGPT Pro subscription ($200/mo) — UI-only, API is separate and cheaper
- WhatsApp integration — deferred, Telegram first
- Self-hosted LLMs — edge case, API is better and cheaper for now
- Paperclip / multi-agent orchestration — single agent only
- Multiple AI employees — CTO must be stable first
- Letta memory runtime — overkill for v1, wiki pattern is sufficient

## Open Questions for John
1. Use existing Hetzner VPS (116.203.68.119) or provision a new one for CTO?
2. Approve OpenRouter API spend (~$5-30/month estimated)?
3. Install Telegram for receiving CTO reports?
4. Approve Gemini API key for YouTube summarization (~$1-5/month)?
