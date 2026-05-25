# CTO Memory (Tier 1 — Always Loaded)
<!-- MEMORY.md loaded in main private session only, not shared/group [verified against OpenClaw docs] -->

## Current State
- **Version:** 0.1.0 [defined]
- **Architecture:** **Two-hemisphere brain** on Hetzner VPS — OpenClaw (left, thinking) + Hermes Agent (right, doing) + A2A protocol (corpus callosum) [adopted 2026-05-11, see hemisphere.md and CTO-DECISION-005]
- **VPS:** 116.203.68.119 [installed and running OpenClaw side]
- **Status:** OpenClaw INSTALLED AND OPERATIONAL on VPS. Hermes installation pending. Gateway running via systemd. Telegram connected.
- **LLM:** Both hemispheres on Codex OAuth via the dedicated **ChatGPT Pro account `cto@husband.llc`** ($200/mo, separate email from john@husband.llc Business). Embeddings require separate OPENAI_API_KEY (pennies). [decision CTO-DECISION-013, 2026-05-24 — exercising the documented Pro-escape path from CTO-DECISION-008. Business seat under john@husband.llc remains valid for John's personal use but is no longer the CTO auth path.]
- **First response:** 2026-04-27 via Telegram. Installation verified working.
- **Architecture pattern:** Five-layer (Brain/Hands/Memory/Spine/Guardrails) mapped onto the two hemispheres [verified — community consensus]

## Key Decisions Made [all logged in logs/decisions/]
- OpenClaw chosen as the first agent framework — macro evolution > micro evolution [decision CTO-DECISION-001, 2026-04-26]
- VPS-based upgrade testing, not Docker — system-level changes can't be containerized [decision CTO-DECISION-002, Hetzner API verified]
- Telegram for notifications — superseded 2026-05-11 (CTO-DECISION-006). A2A is the comms layer now; human interface built/exposed on top.
- Memory architecture: Obsidian-compatible vault + SQLite (engram) + tiered loading [decision CTO-DECISION-004]
- **Hermes adopted as right hemisphere alongside OpenClaw — two-hemisphere brain, A2A corpus callosum, Codex OAuth shared** [decision CTO-DECISION-005, 2026-05-11. Hermes's Phase 1-4 self-evolution (skills/prompts/tool descriptions/tool code) generates PRs that feed CTO's existing clone-test-replace upgrade cycle. Anything outside Phase 1-4 → BACKLOG.md]
- Fully autonomous — John reviews after the fact, never blocks [explicit instruction from John]
- Memory is the moat — models and frameworks are swappable, knowledge compounds [community consensus, verified in research]
- HANDOFF.md required in every upgrade cycle [explicit requirement from John]
- Capability gaps that would require forks or new MCPs/skills go in BACKLOG.md — no silent escalations [established 2026-05-11]

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
