# CTO — Autonomous AI Chief Technology Officer

AI technologies are evolving faster than any human can track, evaluate, and implement. New LLMs, agent frameworks, MCPs, skills, tools, and APIs appear daily. By the time one is learned, three more have emerged. The gap between what's available and what's implemented keeps widening.

CTO closes that gap.

## What This Is

CTO is a fully autonomous AI agent that researches the AI technology landscape, evaluates new tools and techniques, and upgrades itself — without waiting for a human to learn, test, and implement each one.

It is the first employee in a planned AI workforce. Once CTO is stable and self-improving, it becomes the foundation for building other AI employees: CFO (tax filing), CEO, CMO, HR (AIR), and more.

## How It Works

1. **Daily Research** — CTO scans GitHub, HN, arXiv, YouTube, changelogs, and the broader web for new AI technologies (with a 5-minute human curation checkpoint)
2. **Evaluate** — Filters signal from noise via LLM relevance scoring, determines what's worth integrating
3. **Clone-Test-Replace** — Provisions a fresh Hetzner VPS, deploys the candidate version, runs full test suite on real infrastructure. If tests pass, the candidate becomes the new CTO. If they fail, it iterates or abandons with a documented reason.
4. **Archive** — Every replaced version is archived with Hetzner snapshots and git tags for instant rollback
5. **Report** — Every decision is logged and reported to the owner via Telegram

## Architecture

Built on the five-layer model the AI community has converged on:

1. **Brain** — Multi-model LLM via OpenRouter (cheap for routine, escalate for complex)
2. **Hands** — Tools via MCP (the universal standard, 97M monthly installs)
3. **Memory** — Obsidian vault + SQLite coordination + tiered loading (the moat)
4. **Spine** — OpenClaw framework + A2A protocol for future multi-agent
5. **Guardrails** — GUARDRAILS.md, FAILURE.md, circuit breakers, budget caps, human checkpoints

## Principles

- **Fully autonomous** — no human approval needed except for purchases
- **Macro evolution first** — revolutionary changes from research, not just incremental self-improvement
- **Not locked to any provider** — may use Claude, OpenAI, Gemini, open-source, or whatever is best
- **Memory is the moat** — models and frameworks are swappable; knowledge compounds
- **Test on real infrastructure** — VPS-based testing, not Docker containers
- **Every version archived** — rollback is always one command away
- **Human curation checkpoint** — 5 minutes/day in the research pipeline

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
│   ├── communication.md            # Telegram primary, Gmail fallback
│   ├── llm-strategy.md             # Multi-model routing via OpenRouter
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

**Phase: Research Round 2 Complete → Architecture Defined → Implementation**

Two rounds of research (21 agents total) surveyed the full autonomous AI agent landscape. OpenClaw selected as framework. Five-layer architecture defined based on community consensus. VPS provisioned at 178.104.213.9 (8 vCPU, 16 GB RAM, 150 GB disk).

## Owner

John Husband — john@husband.llc
