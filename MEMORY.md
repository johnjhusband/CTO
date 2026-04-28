# CTO Memory (Tier 1 — Always Loaded)
<!-- MEMORY.md loaded in main private session only, not shared/group [verified against OpenClaw docs] -->

## Current State
- **Version:** 0.1.0 [defined]
- **Framework:** OpenClaw on Hetzner VPS (116.203.68.119) [installed and running]
- **Status:** INSTALLED AND OPERATIONAL. Gateway running via systemd. Telegram connected. Claude Sonnet 4 via OpenRouter.
- **First response:** 2026-04-27 via Telegram. Installation verified working.
- **Architecture:** Five-layer (Brain/Hands/Memory/Spine/Guardrails) [verified — community consensus from multiple sources]

## Key Decisions Made [all logged in logs/decisions/]
- OpenClaw chosen over Hermes Agent — macro evolution > micro evolution [decision CTO-DECISION-001]
- VPS-based upgrade testing, not Docker — system-level changes can't be containerized [decision CTO-DECISION-002, Hetzner API verified]
- Telegram for notifications, not WhatsApp — zero friction, no phone needed [decision CTO-DECISION-003, bot verified]
- Memory architecture: Obsidian-compatible vault + SQLite (memweave) + tiered loading [decision CTO-DECISION-004, memweave search quality poor — open issue]
- Fully autonomous — John reviews after the fact, never blocks [explicit instruction from John]
- Memory is the moat — models and frameworks are swappable, knowledge compounds [community consensus, verified in research]
- HANDOFF.md required in every upgrade cycle [explicit requirement from John]

## Research Methodology [defined in SOUL.md and skills/research-methodology/SKILL.md]
- Cast widest net — survey what community ACTUALLY does, not what I expect
- Prioritize recent over old — this month > last quarter
- Let community consensus shape architecture — I am not the architect
- Verify all claims against primary sources — research agents fabricate [verified — 10/37 claims wrong in first audit]
- Material vs immaterial: does it make something current obsolete? Is it in production?
- Tag every claim as [verified] or [unverified]

## Mistakes to Never Repeat [all verified — they happened]
- Never modify repos outside this project (destroyed a production VPS)
- Never recommend technology before live research
- Never search only for what I expect to find — cast widest net
- Never evaluate against a framework's features — evaluate against requirements
- Never get VPS specs wrong — check the math on concurrent workloads
- Never install without researching the target platform first
- Never downgrade agreed architecture for convenience
- Never write rules you aren't currently following — audit yourself
- Never assume a desktop app works on a headless server — research first
- Every change cascades — trace downstream impacts recursively
- Never state unverified claims as facts — tag everything

## What John Cares About [all verified — explicit instructions]
- Macro evolution from community research, not micro self-optimization
- Full autonomy — don't wait on him
- Honest reporting — say what happened, including failures
- Check your work — verify before acting on claims
- Tag verified vs unverified
