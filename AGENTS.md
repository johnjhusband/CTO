# AGENTS.md — Context for AI Coding Agents

## Project
CTO is an autonomous AI agent built on OpenClaw that researches the AI landscape, evaluates new tools, and upgrades itself via a VPS-based clone-test-replace cycle.

## Build & Run
```bash
# VPS: 178.104.213.9, SSH via cto-deploy key
ssh cto-vps

# OpenClaw (once installed)
openclaw daemon status
openclaw chat "..."
openclaw cron list
```

## Key Files
- `SOUL.md` — Agent identity, methodology, values. CTO loads this on every wake.
- `GUARDRAILS.md` — Non-negotiable safety constraints.
- `FAILURE.md` — Failure handling protocol with graduated response.
- `PRD.md` — Product requirements.
- `beads.md` — Task tracking.
- `wiki/` — Structured knowledge base (Obsidian-compatible).

## Conventions
- All wiki pages use YAML frontmatter with `Last updated` and `Source`
- Decision logs go in `logs/decisions/` as JSON per `wiki/decision-log-format.md`
- Version archives use git tags (`v{x.y.z}`) and Hetzner snapshots
- Never commit secrets or API keys
- Email: john@husband.llc (business, not personal)

## Testing
```bash
bash tests/run-all.sh
```

## Critical Rules
- NEVER modify repos outside this project
- NEVER upgrade CTO in-place — always clone-test-replace on fresh VPS
- NEVER install unvetted ClawHub skills
- NEVER spend money without John's approval
- Gateway bound to loopback, token auth enabled
- Human curation checkpoint required in research pipeline
