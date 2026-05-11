# Hermes Agent — Comprehensive Reference

**L0:** Hermes Agent (Nous Research) — open-source self-improving AI agent framework. MIT, Python, v0.13.0 (May 7, 2026), ~144K GitHub stars. Differentiator: GEPA-based learning loop that auto-creates and self-improves skills from execution traces. Architecturally tighter-coupled than OpenClaw but as of May 10, 2026 leads OpenClaw in daily OpenRouter token volume (224B vs 186B).

**L1:** Built by Nous Research, first release Feb 25, 2026. Headline features: gateway-first messaging (Telegram/Discord/Slack/WhatsApp/Signal/CLI + 14 more), auto-skill-creation after complex tasks, GEPA execution-trace optimization (ICLR 2026 Oral paper), 4-layer memory with FTS5 cross-session recall and Honcho dialectic user modeling, 6 terminal backends (local, Docker, SSH, Daytona, Singularity, Modal), 200+ models via OpenRouter/Nous Portal/etc. Security history: dependency caught in March 24 LiteLLM supply chain attack (TeamPCP), patched in v0.5.0 four days later; v0.8.0 independent audit found 4 critical + 9 high in default config (ALLOW-ALL posture); v0.13.0 closed 8 P0 vulns and turned redaction on by default. Companion repo `hermes-agent-self-evolution` runs DSPy+GEPA optimization passes ($2-10 per run) and submits results as PRs against main.

**Last updated:** 2026-05-11
**Verification:** Each section tagged [verified] / [unverified]. Verified means directly fetched from official source (github.com/NousResearch/hermes-agent, hermes-agent.nousresearch.com, NVD/Tenable for CVEs) during this research pass on 2026-05-11. Unverified means relayed from a secondary blog/article without primary-source confirmation.
**Source:** Live web research 2026-05-11 — WebFetch against official repo, official docs, AGENTS.md, releases page, quickstart docs, plus searches for security/comparison context.

---

## Why This Document Exists

The CTO v1 framework decision (logged in `wiki/v1-evaluation.md` and `HANDOFF.md`) chose OpenClaw over Hermes Agent on 2026-04-26. The reasoning hinged on macro evolution (community ecosystem breadth) outweighing micro evolution (self-improvement). Two weeks later, the picture has shifted: Hermes shipped four major versions (v0.10 → v0.13) with substantial security and feature improvements, and as of 2026-05-10 it overtook OpenClaw in daily OpenRouter token usage. This document collects every current fact on Hermes so we can revisit the architecture decision with fresh evidence.

This is **not** a new decision. It is a reference dump for the decision.

---

## Current State (as of 2026-05-11)

| Field | Value | Verification |
|---|---|---|
| Latest version | **v0.13.0 "The Tenacity Release"** | [verified] github releases |
| Release date | May 7, 2026 | [verified] github releases |
| License | MIT | [verified] github repo |
| Primary language | Python 88.0% (TypeScript 8.9%) | [verified] github repo |
| GitHub stars | ~144,000 | [verified] github repo (May 11, 2026) |
| GitHub forks | ~22,400 | [verified] github repo |
| First release | Feb 25, 2026 | [unverified] secondary sources cite this date |
| Maintainer | Nous Research | [verified] github org |
| Repo | https://github.com/NousResearch/hermes-agent | [verified] |
| Docs | https://hermes-agent.nousresearch.com/docs/ | [verified] |

---

## What Hermes Is

A self-improving autonomous agent designed to run **persistently on infrastructure you control** — VPS, serverless (Modal/Daytona), or local — rather than as an IDE copilot. Distinguishing features:

- **Persistent memory across sessions** — agent-curated, with periodic "nudges" to persist what it learns.
- **Auto-skill creation** — after a complex multi-tool task, the agent writes a `SKILL.md` capturing the procedure, pitfalls, and verification steps. Future similar tasks are 40% faster (benchmark claim from ICLR 2026 paper, [unverified] in this pass).
- **GEPA (Genetic-Pareto Prompt Evolution)** — uses natural-language reflection on execution traces to optimize prompts, skills, and tool descriptions. ICLR 2026 Oral.
- **Gateway-first messaging** — one process bridges 18+ chat platforms (Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Teams, email, etc.).
- **Six terminal backends** — local, Docker, SSH, Daytona, Singularity, Modal — pick where work actually executes.
- **Model-agnostic** — 200+ models across Nous Portal, OpenRouter, NVIDIA NIM, OpenAI, Anthropic, Gemini, Ollama, any compatible endpoint. Switch with `hermes model`.

---

## Architecture [verified — sourced from AGENTS.md]

### Agent Loop

`AIAgent` class in `run_agent.py` implements a synchronous conversation loop iterating up to `max_iterations` times. Each iteration calls the model; tool calls execute and feed back as messages. Loop terminates when the model returns non-tool content or the iteration budget is exhausted.

### Gateway

Messaging abstraction layer in `gateway/` bridges chat platforms via adapter implementations. Each adapter inherits a base class and implements `connect()`, `disconnect()`, and message handlers. Includes a session manager and background process notification system.

### Skills System

Two tiers:

- **Bundled skills** in `skills/` — active by default.
- **Optional skills** in `optional-skills/` — installed explicitly.

Skills are directories containing a `SKILL.md` with frontmatter (metadata, configuration, dependencies). The **Curator** (`agent/curator.py`, added v0.12.0) auto-archives unused agent-created skills to prevent stagnation. Compatible with the open `agentskills.io` standard.

### Memory Layers

Pluggable providers in `plugins/memory/` implement a `MemoryProvider` ABC with `sync_turn()` and `prefetch()` methods. Current implementations include:

- **Honcho** — dialectic user modeling
- **Mem0** — generic vector + summary memory
- Plus a built-in FTS5 cross-session recall layer

Memory is optionally disabled per-turn (`skip_memory=True`) for cron jobs.

### Terminal Backends (Six)

- `local` — direct execution on the host
- `docker` — containerized
- `ssh` — remote host
- `daytona` — serverless dev environment
- `singularity` — HPC-style container
- `modal` — serverless cloud runtime

### Curator (v0.12.0+)

Autonomous background agent that grades and consolidates the skill library on a schedule. Counters skill-library stagnation and quality drift.

### Safety / Guardrails

- **Prompt-cache integrity** — toolset/memory/system-prompt changes mid-conversation invalidate the cache; mutating slash commands default to deferred application (use `--now` for immediate effect).
- **Delegation constraints** — subagents spawned via `delegate_task` are role-gated. `role="leaf"` blocks recursive delegation and access to sensitive tools (`memory`, `clarify`, `send_message`). `role="orchestrator"` retains delegation, bounded by `max_spawn_depth`.
- **Cron hardening** — 3-minute hard interrupt on cron jobs; missing-fire-time recovery within 120s–2h window; file locking against duplicate ticks.
- **Message guards** — two sequential guards in the gateway: base adapter queuing when a session is active, and gateway-runner interception of control commands.
- **Test isolation** — `_isolate_hermes_home` autouse fixture redirects `HERMES_HOME` to temp dirs; `scripts/run_tests.sh` enforces CI parity (no credentials, UTC, 4 workers).

---

## Self-Evolution / GEPA [verified — sourced from hermes-agent-self-evolution repo]

Companion repository: **`NousResearch/hermes-agent-self-evolution`**.

> "Hermes Agent Self-Evolution uses DSPy + GEPA (Genetic-Pareto Prompt Evolution) to automatically evolve and optimize Hermes Agent's skills, tool descriptions, system prompts, and code."

### How GEPA Works

> "GEPA reads execution traces to understand _why_ things fail (not just that they failed), then proposes targeted improvements."

Two key properties:
- **Reflective mutation** — natural-language reasoning over traces produces new variants.
- **Pareto-optimal selection** — keeps a diverse archive of variants, not just the single best.

### Optimization Phases

- **Phase 1 (implemented):** Skill files
- **Phase 2 (planned):** Tool descriptions
- **Phase 3 (planned):** System prompts
- **Phase 4 (planned):** Tool implementation code

### Performance / Cost Claims

> "No GPU training required. Everything operates via API calls — mutating text, evaluating results, and selecting the best variants. ~$2–10 per optimization run."

Per the ICLR 2026 paper [unverified in this pass]: outperforms GRPO (RL baseline) by 6% average and up to 20% on specific tasks, using 35× fewer rollouts. Agents with 20+ self-generated skills complete similar repeat tasks 40% faster than a fresh instance.

### Integration

> "All evolved variants are submitted as pull requests against the main hermes-agent repository, ensuring human review before integration."

### Critical scope notes for CTO design [verified 2026-05-11]

**The self-evolution framework runs OUTSIDE the agent, not inside it.** Quote from the official PLAN.md: *"hermes-agent-self-evolution operates ON hermes-agent, not inside it. Zero changes to the agent repo are needed. It reads from the hermes-agent codebase and writes evolved versions to git branches, creating PRs for human review."*

This has three consequences for the CTO design:

1. **Hermes-the-runtime does not autonomously rewrite its own running code.** A *separate* process does, and emits PRs. The agent in production is stable; mutations are proposed, not applied live.
2. **The wrapper is repo-agnostic.** Phase 4 maps any file to a `GitBasedOrganism`. It can target OpenClaw's `tools/` just as easily as Hermes's. This is what enables the two-hemisphere "Hermes patches OpenClaw" pattern documented in [`hemisphere.md`](hemisphere.md).
3. **Architecture-level changes (memory layer, LLM router, agent kernel) are NOT in scope of the self-evolution framework.** Phases 1-4 cover skills, prompts, tool descriptions, and tool implementations. Replacing the kernel or memory ABC is CTO's macro-evolution upgrade-cycle job, run on a fresh Hetzner VPS — not Hermes's self-evolution job.

### Phase scope summary

| Phase | What gets mutated | Architecture-level? | Maps to CTO |
|---|---|---|---|
| 1 | Skill files | No | Within Hermes hemisphere; also can target OpenClaw skills |
| 2 | Tool descriptions | No | Within Hermes hemisphere; also can target OpenClaw tools |
| 3 | System prompts | No | Within Hermes hemisphere |
| 4 | Tool implementation code (`tools/*.py`) | Borderline — code, not architecture | Within Hermes hemisphere; can target OpenClaw tool code |
| (not in scope) | Agent kernel, memory ABC, gateway core, framework substitution | **Yes — full architecture** | **CTO macro-evolution upgrade cycle, NOT Hermes self-evolution** |

---

## Installation [verified — sourced from quickstart.md]

### Linux / macOS / WSL2
```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc   # or source ~/.zshrc
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1 | iex
```

Documented installation time: ~60 seconds.

### First Run
```bash
hermes model         # configure model provider
hermes               # classic CLI
hermes --tui         # modern TUI (recommended)
hermes --continue    # resume most recent session (short: -c)
```

### Sample first prompts
- "Summarize this repo in 5 bullets and tell me what the main entrypoint is"
- "What's my disk usage? Show the top 5 largest directories"

---

## Configuration [verified]

Hermes separates settings into two locations:

| File | Purpose |
|---|---|
| `~/.hermes/config.yaml` | Non-secret settings — `model`, `agent`, `display`, `memory`, `gateway` sections |
| `~/.hermes/.env` | API keys and secrets only |

### Set values via CLI
```bash
hermes config set model anthropic/claude-opus-4.6
hermes config set OPENROUTER_API_KEY sk-or-...
```

### Profiles

Multiple isolated instances are supported via the `HERMES_HOME` environment variable, set by `_apply_profile_override()` before module imports. Code uses `get_hermes_home()` rather than hardcoded `~/.hermes` paths.

---

## Supported Models [verified]

200+ models across:
- **Nous Portal** (first-party)
- **OpenRouter** (200+ models from 94 providers)
- **NVIDIA NIM** (Nemotron)
- **Xiaomi MiMo**
- **z.ai / GLM**
- **Kimi / Moonshot**
- **MiniMax**
- **Hugging Face**
- **OpenAI**
- **Anthropic**
- **Google Gemini** (incl. OAuth via Gemini OAuth path added v0.11)
- **AWS Bedrock** (native support added v0.11)
- **Vercel ai-gateway** (added v0.11)
- **Arcee AI** (added v0.11)
- **Step Plan** (added v0.11)
- **LM Studio** (added v0.12)
- **GMI Cloud** (added v0.12)
- **Azure AI Foundry** (added v0.12)
- **Ollama** / any OpenAI-compatible endpoint

Switch with: `hermes model`. No code changes required.

---

## Supported Messaging Platforms [verified]

18+ platforms through one gateway process (as of v0.12.0):

Telegram, Discord, Slack, WhatsApp, Signal, Matrix, Teams, Email, CLI, QQBot (added v0.11.0 — 17th platform), Tencent 元宝 (added v0.12.0 — 18th platform), plus others listed in the docs (full enumeration in `gateway/platforms/`).

The gateway runs as a single process; all platforms route through the same agent and skills.

---

## Security

### History

| Date | Event |
|---|---|
| 2026-03-24 | **LiteLLM supply chain attack** — threat actor "TeamPCP" published two backdoored versions of LiteLLM (the LLM routing library Hermes depended on). Malicious code harvested API keys, cloud credentials, SSH keys, and DB passwords. Operation ran ~5 hours before detection. Hermes users running between Mar 24 and Mar 28 were exposed. [verified] — multiple sources |
| 2026-03-28 | Hermes v0.5.0 released — patched LiteLLM dependency, four days after the upstream compromise. [verified] |
| 2026 (date unspecified) | Independent security audit of v0.8.0 (~812 Python files, ~364K LOC) found **4 critical + 9 high severity** findings in default config. No malware/data exfiltration. Verdict: code is well-intentioned but default posture is **ALLOW-ALL**. [verified] — GitHub issue #7826 |
| 2026-04-27 | **CVE-2026-7113** published — missing authentication in webhooks endpoint, v0.8.0 only. CVSS 5.6 MEDIUM. [verified] — NVD |
| 2026-04 (approx) | **CVE-2026-7396** published — path traversal in WeChat Work Platform Adapter (`gateway/platforms/wecom.py`), v0.8.0 only. [verified] — Tenable / NVD |
| 2026-05-07 | v0.13.0 closed 8 P0 vulnerabilities, including "Discord role-allowlists guild-scoped" and TOCTOU windows in `auth.json` and MCP OAuth flows. Redaction turned **on by default**. [verified] — release notes |

### Current Posture (v0.13.0)

- **Redaction on by default** — credentials and sensitive strings scrubbed from logs.
- **Prompt injection scanning, credential filtering, context scanning, container hardening** — built in from day one [unverified — claim from secondary source].
- **Hermes Agent has zero reported open CVEs as of May 2026** [unverified — single secondary source; do not treat as audited fact].

### Standing Risks

- **Default ALLOW-ALL** — out-of-the-box, the agent has broad system access. The audit's central finding. Must be hardened explicitly per deployment.
- **GODMODE skill** exists — full bypass of safety prompts. Audit flagged this as a real risk for unaware users.
- **Tight coupling** — self-evolution machinery is woven into the architecture rather than being a pluggable layer. Replacing it requires touching multiple core files.
- **Young codebase** — 2.5 months old at time of writing. Less battle-tested than alternatives.
- **Single-vendor dependency on Nous Research** — relatively small team, less redundancy than OpenClaw's foundation-backed governance.

---

## Release History (Recent)

[verified — sourced from github.com/NousResearch/hermes-agent/releases]

| Version | Date | Codename | Highlights |
|---|---|---|---|
| **v0.13.0** | 2026-05-07 | The Tenacity Release | Multi-agent Kanban for task delegation; `/goal` command for cross-turn focus (Ralph loop); native video analysis; 8 P0 security fixes including Discord role-allowlists guild-scoped; redaction on by default; gateway auto-resumes interrupted sessions; 7 new language localizations. 864 commits, 588 PRs merged, 282 issues closed (13 P0, 36 P1), 295 contributors. |
| **v0.12.0** | 2026-04-30 | The Curator Release | Autonomous background **Curator** agent grades and consolidates skill libraries on a schedule; 4 new inference providers (LM Studio, GMI Cloud, Azure AI Foundry, MiniMax); Tencent 元宝 became 18th messaging platform; native Spotify integration; Google Meet plugin; 57% reduction in visible TUI cold-start time. 1,096 commits, 550 PRs, 213 issues. |
| **v0.11.0** | 2026-04-23 | The Interface Release | Complete React/Ink rewrite of interactive CLI with pluggable transport architecture; native AWS Bedrock support; 5 new inference paths (NVIDIA NIM, Arcee AI, Step Plan, Gemini OAuth, Vercel ai-gateway); QQBot became 17th platform; plugin surface expanded to include slash commands and tool dispatch. 1,556 commits, 761 PRs. |
| v0.8.0 | 2026-04-08 [unverified date] | n/a | First open-source agent with GEPA-based self-evolution. The version that the independent security audit covered. Two CVEs (path traversal, missing webhook auth) trace back to this version. |
| v0.5.0 | 2026-03-28 | n/a | LiteLLM supply-chain patch (4 days after upstream compromise). |
| v0.1.0 | 2026-02-25 [unverified] | n/a | First public release. |

---

## Current Standing vs OpenClaw (May 2026)

[unverified — single secondary source: MarkTechPost 2026-05-10. Treat directional, not authoritative.]

| Metric | Hermes | OpenClaw |
|---|---|---|
| Daily OpenRouter tokens (2026-05-10) | **224 billion** | 186 billion |
| Cumulative OpenRouter tokens | 6.35T | **9.17T** |
| GitHub stars | ~144K (some sources ~114K) | ~370K |
| Skills / plugins | ~118 bundled + community | 44,000+ ClawHub |
| Messaging platforms | 18 | 50+ |
| Architecture philosophy | Depth of learning (tight) | Breadth of reach (loose) |

**The headline shift:** as of 2026-05-10, **daily** Hermes token usage on OpenRouter exceeded OpenClaw's for the first time. Cumulative still favors OpenClaw heavily. The article frames this as "breadth of reach versus depth of learning," with market data suggesting developers increasingly value compounding capability improvements over channel coverage.

This signal does **not** by itself overturn the 2026-04-26 CTO architecture decision. It is one data point worth weighing.

---

## Relationships to Other CTO Docs

- [`wiki/v1-evaluation.md`](wiki/v1-evaluation.md) — the original OpenClaw vs Hermes evaluation (2026-04-26). The reasoning that selected OpenClaw is intact; whether the inputs have shifted enough to warrant re-evaluation is the open question.
- [`wiki/research-agent-frameworks.md`](wiki/research-agent-frameworks.md) — full landscape including OpenHands, Cline, Agent Zero, Letta, etc. Hermes is one entry among many.
- [`HANDOFF.md`](HANDOFF.md) — captures the decision rationale and warns explicitly: *"If you find micro evolution becoming a bottleneck, evaluating Hermes as a component or building similar capabilities is a legitimate macro evolution decision."*
- [`PRD.md`](PRD.md) — the requirements that the framework decision is measured against.
- [`SOUL.md`](SOUL.md) — operating principles; "macro evolution > micro evolution" is a core SOUL claim that influenced the original decision.

---

## Open Questions for the CTO Architecture Re-evaluation

1. **Has the macro vs micro reasoning aged well?** The original argument: micro evolution is secondary because community output dwarfs self-improvement. Two weeks of release history shows Hermes shipping faster than OpenClaw — does that erode the "community output is bigger" claim?
2. **Does the May 10 OpenRouter token-volume crossover represent a sustained trend or a noisy daily reading?** Need 30-day moving average, not a single day.
3. **Is Hermes's tight coupling actually a problem in practice?** The original concern: replacing Hermes requires abandoning native self-improvement. But if Hermes itself is the destination rather than a stepping stone, that concern dissolves.
4. **Can OpenClaw's self-improvement gap be closed?** Skill Workshop, Self-Improving Agent skill, Evolver — community plugins that cover ~60-70% of Hermes's native capabilities per the original eval. Has that gap closed, widened, or stayed the same in the last 14 days?
5. **Security calculus.** Hermes had a serious supply-chain incident (LiteLLM, March 24) and an audit-flagged ALLOW-ALL default posture. v0.13.0 fixes a lot. OpenClaw has its own well-documented security issues. On *current* posture, which is safer to run autonomously on a VPS?
6. **Where does Codex OAuth fit?** The CTO's LLM strategy depends on ChatGPT Pro via Codex OAuth. Does Hermes support that auth path the same way OpenClaw does? Need to verify.
7. **If we switched, what would the migration cost?** OpenClaw is installed on the VPS (per `claude_wake_state.json`). A Hermes install is ~60 seconds. But re-implementing the skills, memory layout, and gateway configuration is the real work.

---

## Sources

Live research, 2026-05-11:

- [Hermes Agent — official docs](https://hermes-agent.nousresearch.com/docs/)
- [NousResearch/hermes-agent — GitHub](https://github.com/NousResearch/hermes-agent)
- [hermes-agent AGENTS.md](https://github.com/NousResearch/hermes-agent/blob/main/AGENTS.md)
- [hermes-agent quickstart.md](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/getting-started/quickstart.md)
- [hermes-agent releases](https://github.com/NousResearch/hermes-agent/releases)
- [NousResearch/hermes-agent-self-evolution](https://github.com/NousResearch/hermes-agent-self-evolution)
- [Hermes Agent Documentation Mirror — mudrii/hermes-agent-docs](https://github.com/mudrii/hermes-agent-docs)
- [awesome-hermes-agent — 0xNyk](https://github.com/0xNyk/awesome-hermes-agent)
- [Security Audit Issue #7826 — github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/issues/7826)
- [hermes-agent security overview — github](https://github.com/NousResearch/hermes-agent/security)
- [CVE-2026-7113 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2026-7113)
- [CVE-2026-7396 — Tenable](https://www.tenable.com/cve/CVE-2026-7396)
- [The Hermes Agent Supply Chain Hack — getclaw.sh](https://getclaw.sh/blog/hermes-agent-supply-chain-hack-litellm-what-founders-need-to-know)
- [Supply Chain Attacks Surge March 2026 — Zscaler ThreatLabz](https://www.zscaler.com/blogs/security-research/supply-chain-attacks-surge-march-2026)
- [Hermes Agent Security Threat Model — Repello AI](https://repello.ai/blog/hermes-agent-security)
- [Hermes Agent v0.8.0 Self-Improving AI Tutorial — byteiota](https://byteiota.com/hermes-agent-v0-8-0-self-improving-ai-agent-tutorial/)
- [Run a Self-Improving AI Agent with Hermes and GMI Cloud](https://www.gmicloud.ai/en/blog/run-your-own-ai-agent-with-hermes-and-gmi-cloud)
- [Hermes Agent 2026: First Production-Ready Self-Improving Open-Source AI Agent — innobu](https://www.innobu.com/en/articles/hermes-agent-self-improvement-open-source-2026.html)
- [OpenClaw vs Hermes Agent: Why Nous Research's Self-Improving Agent Now Leads OpenRouter — MarkTechPost (2026-05-10)](https://www.marktechpost.com/2026/05/10/openclaw-vs-hermes-agent-why-nous-researchs-self-improving-agent-now-leads-openrouters-global-rankings/)
- [Hermes Agent vs OpenClaw: Honest Comparison — Hundred Tabs](https://hundredtabs.com/blog/hermes-agent-vs-openclaw)
- [42 Days, 8 Major Versions, 0 CVEs: Hermes Agent — Odaily](https://www.odaily.news/en/post/5210179)
- [Hermes Agent Review — Kisztof on Medium](https://kisztof.medium.com/hermes-agent-review-nous-researchs-self-improving-ai-agent-e72bc244435a)
