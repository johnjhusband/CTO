# CTO — Autonomous AI Chief Technology Officer
**Version:** 0.1.0-draft
**Created:** 2026-04-26
**Author:** John Husband + Claude
**Status:** Draft

---

## 1. Problem Statement

AI technologies — LLMs, agent frameworks, MCPs, skills, tools, APIs — are evolving faster than any human can track, evaluate, and implement. By the time one tool is learned, three more have appeared. This creates an ever-widening gap between available capabilities and implemented capabilities.

John needs an AI workforce (CTO, CFO, CEO, CMO, etc.) but the foundation must come first: an AI agent that can build, evaluate, and upgrade itself autonomously so it stays at the cutting edge without human bottleneck.

## 2. Solution

An autonomous AI agent called **CTO** that:
- Continuously researches the AI technology landscape
- Evaluates new technologies, frameworks, and tools
- Upgrades itself through a clone-test-replace cycle
- Archives every version for rollback
- Reports all decisions to the user
- Operates with full system-level access on a VPS
- Eventually serves as the foundation for building other AI employees

## 3. Users

| User | Role | Interaction |
|------|------|-------------|
| John Husband | Owner/Operator | Receives decision reports, approves purchases, provides YouTube Premium access |
| CTO (self) | Autonomous agent | Self-modifying, self-testing, self-deploying |
| Future AI employees | Downstream consumers | Will be built by CTO once stable (CFO is next) |

## 4. Core Requirements

### 4.1 Research Engine
- **Daily research cycle** — scans for new AI technologies, tools, frameworks, LLM updates
- **Sources:** YouTube transcripts (primary — human-digested content), GitHub trending/releases, product changelogs, Hacker News, AI newsletters, arxiv (secondary)
- **YouTube Premium access** — user will provide credentials for transcript extraction
- **Signal filtering** — must distinguish hype from genuinely useful technology
- **Technology radar** — maintains a living document of what's emerging, maturing, and declining

### 4.2 Evolution Model

CTO evolves through two distinct mechanisms, each owned by a specific hemisphere as of 2026-05-11 (CTO-DECISION-005).

#### Macro Evolution (Primary — Research-Driven Revolutionary Change) — owned by CTO core
The core mission. CTO absorbs what the entire AI community is producing and makes bold architectural changes:
1. Research engine discovers a significant new technology, framework, or approach
2. Decision engine evaluates whether it warrants adoption — this could mean replacing core components (LLM provider, memory system, communication stack, the agent framework of either hemisphere, or the protocol layer between them)
3. CTO **provisions a new Hetzner VPS** as the test environment
4. CTO deploys a candidate version to the new VPS with the proposed changes integrated
5. Candidate runs a **full test suite** validating all existing + new functionality on real infrastructure (not containerized — full system access, real packages, real services)
6. If tests pass: current CTO VPS is **archived** (snapshot + git tag), candidate VPS becomes the new primary, old VPS is destroyed
7. If tests fail: CTO iterates on the candidate VPS or destroys it with a documented reason
8. Every replaced version is archived for rollback

**Why VPS-based testing, not Docker:** CTO has full system-level access — it installs packages, manages services, runs Docker itself, modifies system config. A Docker container cannot faithfully test these capabilities. Macro evolution may change anything in the stack, including the OS-level components. Only a full VPS provides a true test environment. Hetzner's API allows programmatic VPS provisioning and destruction.

The source and direction of macro evolution comes from **research**, not experience. The entire AI community's output — YouTube channels, GitHub, changelogs, papers — is the input. The output may be revolutionary: swapping a hemisphere's agent framework, switching LLM providers, replacing the memory architecture, adopting an entirely new approach to communication.

#### Micro Evolution (Secondary — Experience-Driven Incremental Improvement) — owned by Hermes (right hemisphere)
Hermes Agent's GEPA-driven self-evolution loop runs continuously, learning from execution traces:
- Auto-creates new skills after complex multi-tool tasks
- Self-improves skills, prompts, and tool descriptions during use (Phase 1-3)
- Proposes patches to tool implementation code (Phase 4) as PRs against the CTO repo
- Targets both Hermes's own code AND OpenClaw's tool code via the repo-agnostic `GitBasedOrganism` wrapper
- All proposed patches feed CTO's existing clone-test-replace upgrade cycle for validation

**Scope boundary:** Hermes self-evolution covers skills, prompts, tool descriptions, and tool implementation code (Phases 1-4). Architecture-level changes (kernel, memory ABC, gateway core, framework swap) remain macro evolution territory — they go through CTO's full clone-test-replace cycle, not Hermes's self-evolution loop. Anything Hermes proposes outside Phase 1-4 → `BACKLOG.md` for John's review (potential fork trigger).

Micro evolution was previously framed as secondary because it could not match community output. With Hermes as a dedicated right hemisphere, micro evolution now has its own engine that runs in parallel with macro evolution rather than competing with it. Macro evolution remains the primary mission (community > self), but Hermes compounds the operational capability between macro upgrade cycles.

### 4.3 Autonomy Model
| Action | Autonomy Level |
|--------|---------------|
| Research | Fully autonomous |
| Evaluate/test on candidate VPS | Fully autonomous |
| Self-upgrade (clone-test-replace) | Fully autonomous, reports decision |
| Install free tools/packages | Fully autonomous |
| Spend money | **Must ask John for approval and purchase** |
| Rollback to previous version | Fully autonomous |

### 4.4 Decision Logging
- Every upgrade decision documented: what was evaluated, what was adopted/rejected, why
- Decision log is persistent and searchable
- All decisions reported to user via the A2A human interface (CTO-DECISION-006); interim file at `/opt/cto/logs/digest/`

### 4.5 Version Archiving
- Every replaced CTO version archived with:
  - Hetzner VPS snapshot [verified — API tested, EUR 0.0143/GB/month confirmed]
  - Git tag [verified — git works on VPS]
  - HANDOFF.md context transfer document
  - Decision log entry explaining what changed
  - Rollback instructions
- Rollback is a first-class operation — restore from snapshot via Hetzner API [verified — create from snapshot confirmed]

### 4.6 Communication
- **Protocol:** A2A (Agent-to-Agent, Linux Foundation; CTO-DECISION-006, 2026-05-11). One stack carries hemisphere-to-hemisphere AND CTO-to-John traffic.
- **Human interface:** built or exposed on top of A2A. v1.0 install ships the A2A registry and Agent Cards. The human-facing interface (web UI / phone-accessible client) is a subsequent phase. Interim: John reads decision logs, BACKLOG.md, and `/opt/cto/logs/digest/*.md` directly via Claude Code Remote Control.
- **Content:** Daily research digest, upgrade decisions, test results, errors/failures, backlog summary.
- **Tone:** Professional, concise, actionable.
- **Removed:** Telegram and Gmail SMTP — superseded by CTO-DECISION-006 (see logs/decisions/CTO-DECISION-006.json).

### 4.7 System Access
- Full system-level access on VPS
- Can install packages, modify system config, manage services
- Can edit its own code, config, and processes
- Can create and destroy Docker containers
- **Only restriction:** cannot make purchases autonomously

## 5. Architecture (High-Level)

Two-hemisphere design as of 2026-05-11 (CTO-DECISION-005). Single Hetzner VPS hosts both halves; they communicate via A2A protocol.

```
┌──────────────────────────────────────────────────────────────────┐
│                           Hetzner VPS                              │
│                                                                    │
│  ┌─────────────────────────┐         ┌─────────────────────────┐  │
│  │  LEFT HEMISPHERE         │   A2A   │  RIGHT HEMISPHERE        │  │
│  │  OPENCLAW (thinking)     │◄───────►│  HERMES (doing)          │  │
│  │                          │ corpus  │                          │  │
│  │  • Gateway / messaging   │ callosum│  • Skill execution       │  │
│  │  • Inbound routing       │         │  • GEPA learning loop    │  │
│  │  • Plans, decomposes     │         │  • Skill auto-creation   │  │
│  │  • Delegates to Hermes   │         │  • Phase 1-4 self-evol   │  │
│  │  • Final-mile delivery   │         │  • Returns findings      │  │
│  │  • Codex OAuth           │         │  • Codex OAuth           │  │
│  └──────────┬───────────────┘         └──────────┬───────────────┘  │
│             │                                     │                  │
│             └──────────────┬──────────────────────┘                  │
│                            │                                         │
│                            ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  SHARED LAYER                                                  │  │
│  │  • A2A registry (Agent Cards for both hemispheres)            │  │
│  │  • Audit log (every cross-hemisphere call)                    │  │
│  │  • Budget meter (rate-limit awareness for shared subscription)│  │
│  │  • Circuit breaker (quarantine misbehaving hemisphere)        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                            │                                         │
│                            ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  RESEARCH ENGINE → TEST ENVIRONMENT → VERSION ARCHIVE          │  │
│  │  (Daily research → fresh Hetzner VPS test → snapshot+tag)      │  │
│  │  Hermes-generated PRs and macro-evolution candidates both go  │  │
│  │  through the same clone-test-replace gate                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                            │                                         │
│                            ▼                                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  COMMS OUT (A2A human interface — per CTO-DECISION-006)        │  │
│  │  Daily digest includes BACKLOG.md summary; John sees gaps 24h │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Git: github.com/johnjhusband/CTO (read+write via deploy key)     │
│  LLM: ChatGPT Pro $200/mo via Codex OAuth — shared by both halves │
│  Embeddings: separate OPENAI_API_KEY (pennies)                    │
└──────────────────────────────────────────────────────────────────┘
```

See `hemisphere.md` for the full design, `hermes.md` for the right hemisphere reference, and `BACKLOG.md` for the capability-gap escalation mechanism.

## 6. LLM Strategy

CTO is **not locked to any provider**. Current auth path (CTO-DECISION-013, 2026-05-24, exercising the escape clause of CTO-DECISION-008): dedicated **ChatGPT Pro on `cto@husband.llc`** ($200/mo, separate email from john@husband.llc Business) via the `openai-codex` provider on both hemispheres, device-code OAuth. The Business seat is retained for John's personal use; the Pro account is exclusively CTO's. Embeddings still require a small separate `OPENAI_API_KEY` for `text-embedding-3` (Codex subscription does not cover embeddings).

Pro quotas (~20× Plus) are roughly an order of magnitude above Business standard-seat, giving headroom for autonomous research + heartbeat + occasional GEPA passes. Quota instrumentation remains a day-one concern — quotas observable via `openclaw models status` `5h`/`Week` counters.

**No OpenRouter.** Removed across both hemispheres on 2026-05-24 [CTO-DECISION-014]. Hermes' session-summarization auxiliary that previously hit `openrouter/free` is now `openai-codex/gpt-5-mini`. OpenClaw's model fallback list is empty. If Codex ever fails, the documented rollback is to restore `~/.codex/auth.json.bak-john-business-*` on the VPS (Business seat under john@husband.llc) — same OAuth mechanism, different account. No PAYG Codex seats — explicitly avoiding accidental-overspend risk.

## 7. Test Plan

### 7.1 Core Tests (must pass every upgrade cycle)
- [ ] CTO can start and reach healthy state
- [ ] Research engine can fetch and parse YouTube transcripts
- [ ] Research engine can search web sources
- [ ] Decision engine can evaluate a technology and produce a recommendation
- [ ] Clone-test-replace cycle completes end-to-end
- [ ] Version archive creates retrievable backup
- [ ] Rollback restores previous version successfully
- [ ] Communication module sends a message to user
- [ ] Decision log is written and readable
- [ ] Daily scheduler triggers research cycle

### 7.2 Self-Upgrade Tests
- [ ] New capability is functional in clone
- [ ] All existing tests still pass in clone
- [ ] Archive of previous version is complete
- [ ] Promotion from clone to primary succeeds
- [ ] Failed upgrade does not corrupt primary

## 8. Success Criteria

| Metric | Target |
|--------|--------|
| Daily research cycle runs | Every 24 hours without human intervention |
| Self-upgrade success rate | >80% of attempted upgrades succeed |
| Rollback time | <5 minutes to restore any previous version |
| Decision log completeness | 100% of upgrades documented |
| User notification delivery | 100% of decisions reported |
| Time to evaluate new technology | <24 hours from discovery to test result |

## 9. Future Scope (Not v1)

- Build CFO (AI tax filing assistant) — first downstream AI employee
- Build CEO, CMO, HR (AIR) and other AI employees
- Inter-employee communication protocol
- Shared knowledge base across AI employees
- Budget management system (when CTO gets spending authority)

## 10. Risks

| Risk | Mitigation |
|------|-----------|
| Self-upgrade breaks CTO | Clone-test-replace cycle; archived versions for rollback |
| LLM API costs spiral | Money-gated: CTO must ask before spending |
| Research returns noise | Signal filtering; YouTube human-digested content as primary source |
| Infinite upgrade loops | Daily cadence cap; must document reason for each upgrade |
| Security exposure from system access | VPS is dedicated to CTO; no shared production workloads |
| YouTube API/access changes | Multiple research sources; fallback to web scraping |

## 11. Open Questions (Updated After Verification Phase)

1. ~~Hetzner VPS~~ — RESOLVED: New dedicated VPS at 116.203.68.119 (cx43) [verified]
2. ~~Agent framework~~ — RESOLVED: OpenClaw selected [decision logged CTO-DECISION-001]
3. ~~YouTube~~ — RESOLVED: Browser-based for v1 [decision]
4. What does "stable CTO" look like before building CFO? Define graduation criteria. [open]
5. ~~Communication~~ — RESOLVED: A2A protocol + human interface (CTO-DECISION-006, 2026-05-11). Supersedes the earlier Telegram-Bot choice (CTO-DECISION-003).
6. ~~OpenRouter credits~~ — RESOLVED: OpenRouter retired (CTO-DECISION-014, 2026-05-24). Both hemispheres run on Codex (cto@husband.llc Pro) only.
7. ~~memweave~~ — RESOLVED: Replaced with engram (Go binary, MCP-native). memweave had poor search quality (0.14 scores).
8. SearXNG vs Brave for web search — SearXNG is free but needs Docker [open]
