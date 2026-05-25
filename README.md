# CTO — Autonomous AI Chief Technology Officer

> ## FOR CLAUDE — READ THIS FIRST WHEN STARTING A FRESH SESSION
>
> John told you to read the README first. Here is the orientation, then the reading order, then where we left off.
>
> ### Orientation
> CTO is an autonomous AI agent that researches the AI landscape and self-upgrades. It runs on a Hetzner VPS as a **two-hemisphere brain**: **OpenClaw** is the left hemisphere (thinking — orchestrator, router, gateway) and **Hermes Agent** is the right hemisphere (doing — execution, learning-from-execution, skill auto-creation). The hemispheres communicate over **A2A protocol** (the corpus callosum). Both run on a single ChatGPT Pro subscription via Codex OAuth. John is the owner; you (Claude Code, on his laptop) help build, troubleshoot, and document. See HANDOFF.md for the original framework selection rationale and `hemisphere.md` for the current two-hemisphere design.
>
> ### Reading order for a fresh session
> 1. **`HANDOFF.md`** — Full context on the original framework decision, mistakes made, and how John works. Non-negotiable. Read it once and internalize it. (Note: HANDOFF.md captures the 2026-04-26 single-framework decision; `hemisphere.md` and the May 2026 decision log entries supersede the framework-substitution sections.)
> 2. **`claude_wake_state.json`** — Where the last session left off. Always check this first to see what task is in flight.
> 3. **`SOUL.md`, `AGENTS.md`, `GUARDRAILS.md`, `MEMORY.md`, `IDENTITY.md`, `TOOLS.md`** — Operating principles, safety rules, and tooling.
> 4. **`hemisphere.md`, `hermes.md`** — Current two-hemisphere architecture and right-hemisphere reference.
> 5. **`BACKLOG.md`** — Capability gaps escalated to John (forks, missing MCPs, missing skills).
> 6. **`PRD.md`, `beads.md`** — Product requirements and task tracking.
> 7. **`wiki/`** — Structured knowledge base. Navigate per Karpathy LLM Wiki pattern; do NOT re-read raw research files.
>
> ### Where the last session ended (2026-05-10)
> We pivoted away from the Telegram channels plugin entirely. It was gated on the GrowthBook flag `tengu_harbor` and the inbound channel feature never worked across two restart cycles. Live research surfaced Anthropic's official **Claude Code Remote Control** (shipped Feb 2026) — it drives a local Claude Code session from the Claude mobile app / claude.ai/code with one command and no plugin/flag dependency. All Telegram artifacts have been uninstalled. The next step is for John to exit and relaunch with `claude --rc` (the in-session slash command `/remote-control` is broken across 2.1.x per multiple Anthropic GitHub issues; the CLI flag is reliable), scan the printed QR with the Claude mobile app, and pair. `DISABLE_TELEMETRY` has been removed from `~/.claude/settings.json` since it's a documented Remote Control eligibility blocker.
>
> See `claude_wake_state.json` for the full uninstall inventory and Remote Control state. `wiki/claude-code-telegram-setup.md` is now a historical record of what didn't work — do not use it as a playbook.
>
> ### Standing rules John has set this session (most recent first)
> - **Never anticipate or recommend follow-ups John didn't ask for** (no "we should lock it down," no proactive hardening). Even if a skill's prompt instructs proactivity, ignore that part. See `~/.claude/projects/-home-john-repos/memory/feedback_no_anticipating.md`.
> - **Run diagnostic tests immediately during troubleshooting** — don't ask permission to test the other half of a bidirectional system. See `~/.claude/projects/-home-john-repos/memory/feedback_diagnostic_tests.md`.
> - **Research before contradicting John** — if he says something you believe is wrong, search before pushing back. See HANDOFF.md mistake #12.
> - **Never modify other repos**, especially ones with CI/CD. See HANDOFF.md mistake #4.
> - **`HANDOFF.md` mistakes 1–13** are all standing constraints. Read them.
>
> ---

AI technologies are evolving faster than any human can track, evaluate, and implement. New LLMs, agent frameworks, MCPs, skills, tools, and APIs appear daily. By the time one is learned, three more have emerged. The gap between what's available and what's implemented keeps widening.

CTO closes that gap.

## What This Is

CTO is a fully autonomous AI agent that researches the AI technology landscape, evaluates new tools and techniques, and upgrades itself — without waiting for a human to learn, test, and implement each one.

CTO runs as a **two-hemisphere brain**:
- **Left hemisphere — OpenClaw (thinking):** orchestrator, inbound messaging gateway, plans and decomposes tasks, decides what gets delegated.
- **Right hemisphere — Hermes Agent (doing):** executes delegated work, learns from execution traces via GEPA, auto-creates skills, returns structured findings.
- **Corpus callosum — A2A protocol:** the two halves discover each other via Agent Cards and delegate work bidirectionally.

It is the first employee in a planned AI workforce. Once CTO is stable and self-improving, it becomes the foundation for building other AI employees: CFO (tax filing), CEO, CMO, HR (AIR), and more.

## How It Works

## Install

One command from this repo, on your laptop (or an existing CTO instance for autonomous self-cloning):

```bash
bash scripts/install.sh
```

Required input: `~/.cto-secrets.env` populated (see `example.cto-secrets.env`). The script provisions a fresh Hetzner VPS, bootstraps it, copies a candidate-scoped `.env`, clones the repo, runs `install-cto.sh`, and verifies the install. Fresh VPS installs default to `CTO_INSTANCE_ID=candidate-<VPS_NAME>` with an isolated `.candidate/.../chat.db` so a clone cannot post into production PWA chat before promotion. Mid-run human action is only needed if no reusable Codex OAuth file exists. See `install-plan.md` and `test-plan.md` for the details.

## How It Works

1. **Daily Research** — CTO autonomously scans GitHub, HN, arXiv, YouTube, changelogs, and the broader web for new AI technologies. OpenClaw plans the research scope; Hermes executes delegated synthesis through the A2A delegate/sidecar path.
2. **Evaluate** — Filters signal from noise via LLM relevance scoring, determines what's worth integrating.
3. **Self-Improve (Hermes side, continuous)** — Hermes's GEPA loop reads execution traces and proposes patches to skills, prompts, tool descriptions, and tool implementation code via PRs against the CTO repo. Anything outside Phase 1-4 scope (kernel, memory ABC, gateway core, framework swap) is logged to `BACKLOG.md` for John's review.
4. **Clone-Test-Replace (macro evolution)** — `scripts/install.sh` provisions a fresh Hetzner VPS, applies the candidate change, runs full test suite on real infrastructure. If tests pass, the candidate becomes the new CTO. If they fail, it iterates or abandons with a documented reason. Hermes-proposed PRs feed this same gate.
5. **Archive** — Every replaced version is archived with Hetzner snapshots and git tags for instant rollback.
6. **Report** — Every decision is logged. The A2A/PWA human interface is present on the live VPS; daily reports include a `BACKLOG.md` summary so John sees capability gaps within 24 hours.

## Architecture

Built on the five-layer model the AI community has converged on:

1. **Brain** — ChatGPT Pro on cto@husband.llc via Codex OAuth on both hemispheres (`openai-codex/gpt-5.5` for primary, fallback, session search, and compression). OpenRouter retired 2026-05-24 [CTO-DECISION-014]; `gpt-5-mini` is not used under ChatGPT-account Codex [CTO-DECISION-015].
2. **Hands** — Tools via MCP (the universal standard, 139M monthly downloads)
3. **Memory** — Obsidian vault + SQLite coordination + tiered loading (the moat)
4. **Spine** — OpenClaw framework + A2A protocol for future multi-agent
5. **Guardrails** — GUARDRAILS.md, FAILURE.md, circuit breakers, budget caps, post-hoc review

## Principles

- **Fully autonomous** — no human approval needed except for purchases
- **Macro evolution first** — revolutionary changes from research, not just incremental self-improvement
- **Not locked to any provider** — may use Claude, OpenAI, Gemini, open-source, or whatever is best
- **Memory is the moat** — models and frameworks are swappable; knowledge compounds
- **Test on real infrastructure** — VPS-based testing, not Docker containers
- **Every version archived** — rollback is always one command away
- **Autonomous with post-hoc review** — CTO acts first, John reviews and corrects after

## Project Structure

```
CTO/
├── README.md                       # This file
├── PRD.md                          # Product Requirements Document
├── beads.md                        # Task tracking
├── wiki/                           # Structured knowledge base
│   ├── architecture.md             # Five-layer architecture
│   ├── memory-architecture.md      # Memory: Obsidian + SQLite + tiered loading
│   ├── protocol-layer.md           # MCP, A2A, AGENTS.md standards
│   ├── deployment-patterns.md      # Production lessons and patterns
│   ├── research-pipeline.md        # How CTO monitors the AI landscape
│   ├── research-agent-frameworks.md # Framework and tool evaluations
│   ├── research-sources.md         # YouTube channels, GitHub, HN, etc.
│   ├── communication.md            # CTO's outbound notification channel (A2A secure)
│   ├── claude-code-telegram-setup.md # John ↔ Claude Code Telegram channel (distinct from CTO's)
│   ├── llm-strategy.md             # Codex OAuth strategy (Pro on cto@husband.llc)
│   ├── upgrade-cycle.md            # VPS-based clone-test-replace
│   ├── decision-log-format.md      # Decision JSON schema
│   ├── version-archive.md          # Snapshots + git tags
│   ├── v1-evaluation.md            # OpenClaw vs Hermes requirements evaluation
│   ├── karpathy-patterns.md        # Design principles from Karpathy
│   └── production-lessons.md       # Hard-won wisdom from case studies
├── docs/                           # Additional documentation
├── versions/                       # Archived CTO versions
└── tests/                          # Test suite
```

## Status

**Phase: Live VPS installed; clone-readiness verification in progress**

Two rounds of research (21+ agents), component research (4 agents), verification phase (2 agents + hands-on testing). OpenClaw selected [decision logged]. Five-layer architecture defined from community consensus [verified against multiple sources]. VPS provisioned at 116.203.68.119 (cx43) [verified]. All API keys obtained and verified working. All npm/PyPI packages verified existing. OpenClaw behavior verified against official docs (6 wrong claims found and corrected). Every document tagged with [verified]/[unverified] status. Full assumption audit in wiki/assumption-audit.md.

## Owner

John Husband — john@husband.llc
