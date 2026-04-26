# CTO — Autonomous AI Chief Technology Officer

AI technologies are evolving faster than any human can track, evaluate, and implement. New LLMs, agent frameworks, MCPs, skills, tools, and APIs appear daily. By the time one is learned, three more have emerged. The gap between what's available and what's implemented keeps widening.

CTO closes that gap.

## What This Is

CTO is a fully autonomous AI agent that researches the AI technology landscape, evaluates new tools and techniques, and upgrades itself — without waiting for a human to learn, test, and implement each one.

It is the first employee in a planned AI workforce. Once CTO is stable and self-improving, it becomes the foundation for building other AI employees: CFO (tax filing), CEO, CMO, HR (AIR), and more.

## How It Works

1. **Daily Research** — CTO scans YouTube transcripts, GitHub, changelogs, and the broader web for new AI technologies, frameworks, and tools
2. **Evaluate** — Filters signal from noise, determines what's worth integrating
3. **Clone-Test-Replace** — Clones itself into a Docker container, applies the upgrade, runs a full test suite. If tests pass, the clone becomes the new CTO. If they fail, it iterates or abandons with a documented reason
4. **Archive** — Every replaced version is archived with git tags and Docker images for instant rollback
5. **Report** — Every decision is logged and reported to the owner

## Principles

- **Fully autonomous** — no human approval needed except for purchases
- **Self-improving** — CTO upgrades itself, including its own LLM, framework, and tools
- **Not locked to any provider** — may use Claude, OpenAI, Gemini, open-source models, or whatever is best at the time
- **Every version archived** — rollback is always one command away
- **Test before deploy** — nothing goes live without passing the test suite in a sandbox

## Project Structure

```
CTO/
├── README.md           # This file
├── PRD.md              # Product Requirements Document
├── beads.md            # Task tracking
├── wiki/               # Structured knowledge base
│   ├── architecture.md
│   ├── research-agent-frameworks.md
│   ├── research-sources.md
│   ├── communication.md
│   ├── llm-strategy.md
│   ├── upgrade-cycle.md
│   ├── decision-log-format.md
│   ├── version-archive.md
│   ├── v1-recommendation.md
│   ├── v1-evaluation.md
│   └── karpathy-patterns.md
├── docs/               # Additional documentation
├── versions/           # Archived CTO versions
└── tests/              # Test suite
```

## Status

**Phase: Research Complete → Framework Decision Pending**

All technology research is complete (April 26, 2026). 13 research agents evaluated 20+ tools across the autonomous agent landscape. See:
- [v1 Evaluation](wiki/v1-evaluation.md) — requirements-based comparison of OpenClaw vs Hermes Agent
- [v1 Recommendation](wiki/v1-recommendation.md) — full architecture proposal (being updated)
- [Karpathy Patterns](wiki/karpathy-patterns.md) — design principles from Karpathy's work

Next step: finalize framework decision, then begin CTO-001 (Core Agent Scaffold).

## Owner

John Husband — johnjhusband@gmail.com
