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

CTO evolves through two distinct mechanisms:

#### Macro Evolution (Primary — Research-Driven Revolutionary Change)
The core mission. CTO absorbs what the entire AI community is producing and makes bold architectural changes:
1. Research engine discovers a significant new technology, framework, or approach
2. Decision engine evaluates whether it warrants adoption — this could mean replacing core components (LLM provider, memory system, communication stack, even the agent framework itself)
3. CTO **provisions a new Hetzner VPS** as the test environment
4. CTO deploys a candidate version to the new VPS with the proposed changes integrated
5. Candidate runs a **full test suite** validating all existing + new functionality on real infrastructure (not containerized — full system access, real packages, real services)
6. If tests pass: current CTO VPS is **archived** (snapshot + git tag), candidate VPS becomes the new primary, old VPS is destroyed
7. If tests fail: CTO iterates on the candidate VPS or destroys it with a documented reason
8. Every replaced version is archived for rollback

**Why VPS-based testing, not Docker:** CTO has full system-level access — it installs packages, manages services, runs Docker itself, modifies system config. A Docker container cannot faithfully test these capabilities. Macro evolution may change anything in the stack, including the OS-level components. Only a full VPS provides a true test environment. Hetzner's API allows programmatic VPS provisioning and destruction.

The source and direction of macro evolution comes from **research**, not experience. The entire AI community's output — YouTube channels, GitHub, changelogs, papers — is the input. The output may be revolutionary: swapping the agent framework, switching LLM providers, replacing the memory architecture, adopting an entirely new approach to communication.

#### Micro Evolution (Secondary — Experience-Driven Incremental Improvement)
CTO also improves incrementally through its own operational experience:
- Learning from repeated tasks to execute them faster
- Building reusable skills/procedures from successful work
- Refining prompts and workflows based on what works and what fails

Micro evolution is valuable but secondary. It pales in comparison to the growth available from the entire AI community's collective output. A CTO that only learns from its own experience will fall behind. A CTO that absorbs and implements the best of what the community produces will stay at the cutting edge.

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
- All decisions reported to user (Telegram primary, fallback to email)

### 4.5 Version Archiving
- Every replaced CTO version archived with:
  - Hetzner VPS snapshot [verified — API tested, EUR 0.0143/GB/month confirmed]
  - Git tag [verified — git works on VPS]
  - HANDOFF.md context transfer document
  - Decision log entry explaining what changed
  - Rollback instructions
- Rollback is a first-class operation — restore from snapshot via Hetzner API [verified — create from snapshot confirmed]

### 4.6 Communication
- **Primary:** Telegram Bot [verified — token works, bot name "CTO", username @HusbandCTObot]
  - Free, no phone needed, zero ban risk [verified]
  - Proactive messaging requires John to message bot first [verified — "chat not found" until first contact]
- **Fallback:** Gmail SMTP [verified — SMTP reachable, TLS works. Sending needs App Password], or any channel CTO determines acceptable
- **Content:** Daily research digest, upgrade decisions, test results, errors/failures
- **Tone:** Professional, concise, actionable

### 4.7 System Access
- Full system-level access on VPS
- Can install packages, modify system config, manage services
- Can edit its own code, config, and processes
- Can create and destroy Docker containers
- **Only restriction:** cannot make purchases autonomously

## 5. Architecture (High-Level)

```
┌─────────────────────────────────────────────────┐
│                    VPS (Root)                     │
│                                                   │
│  ┌──────────────┐    ┌────────────────────────┐  │
│  │  CTO Agent   │    │   Research Engine       │  │
│  │  (Primary)   │───▶│  - YouTube transcripts  │  │
│  │              │    │  - GitHub/HN/Web        │  │
│  │  Scheduler   │    │  - Changelogs           │  │
│  │  (Daily)     │    └────────────────────────┘  │
│  │              │                                 │
│  │  Decision    │    ┌────────────────────────┐  │
│  │  Engine      │───▶│   Test Environment     │  │
│  │              │    │  (Fresh Hetzner VPS)   │  │
│  │  Comms       │    │  - Deploy candidate    │  │
│  │  Module      │    │  - Run test suite      │  │
│  └──────┬───────┘    │  - Promote or destroy  │  │
│         │            └────────────────────────┘  │
│         │                                         │
│         ▼            ┌────────────────────────┐  │
│  ┌──────────────┐    │   Version Archive      │  │
│  │  Comms Out   │    │  - Git tags            │  │
│  │  (Telegram/  │    │  - Hetzner snapshots    │  │
│  │   Email/etc) │    │  - Decision log        │  │
│  └──────────────┘    └────────────────────────┘  │
│                                                   │
│  ┌────────────────────────────────────────────┐  │
│  │              Git Repository                 │  │
│  │  github.com/johnjhusband/CTO               │  │
│  └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## 6. LLM Strategy

CTO is **not locked to any provider** [verified — OpenRouter supports 200+ models via single API]. Uses multi-model routing via OpenRouter [verified — API key works, model IDs confirmed]. Model ref format: `openrouter/provider/model` [verified against docs].

Budget-constrained: prepaid credits on OpenRouter [verified — not postpaid]. $1 free credits for new accounts [verified] — insufficient for Claude Sonnet, need to add credits [verified]. Free models available with `:free` suffix [verified]. CTO must ask John before any new spending.

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

1. ~~Hetzner VPS~~ — RESOLVED: New dedicated VPS at 178.104.213.9 (cx43) [verified]
2. ~~Agent framework~~ — RESOLVED: OpenClaw selected [decision logged CTO-DECISION-001]
3. ~~YouTube~~ — RESOLVED: Browser-based for v1 [decision]
4. What does "stable CTO" look like before building CFO? Define graduation criteria. [open]
5. ~~Communication~~ — RESOLVED: Telegram Bot [verified working, decision logged CTO-DECISION-003]
6. OpenRouter needs more credits for paid models — how much should John add? [open]
7. memweave search quality is poor (0.14 scores) — alternative needed? [open, verified by testing]
8. SearXNG vs Brave for web search — SearXNG is free but needs Docker [open]
