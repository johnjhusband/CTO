# Two-Hemisphere CTO Architecture — Research Notes

**L0:** Design proposed by John (2026-05-11): OpenClaw as left hemisphere (**thinking** — orchestrator, planner, router), Hermes as right hemisphere (**doing** — worker, executor, learner-through-execution), bidirectional task delegation. This is the **orchestrator-worker pattern** with each side running on **OpenAI Codex OAuth via ChatGPT Pro subscription** — both halves verified to support this auth path against primary docs, both share the same $200/mo subscription, total LLM cost stays flat-rate not per-token. Corpus callosum is **A2A protocol** (Linux Foundation, 150+ orgs, 22K stars, 5 SDK languages). Prior art exists: HermesClaw repo (Hermes+OpenClaw coexistence) and OpenClaw A2A plugin bridge (formal A2A client pattern).

**L1:** Right-tool-right-job specialisation makes the two-brain design **cheaper, not more expensive**, than monolithic frontier. Documented 2026 industry data: orchestrator-worker cuts 40-60% on a per-token basis; tiered intelligence stacks deliver 87.4% cost-per-intelligence-unit reduction; hierarchical agents hit 97.7% of full-frontier accuracy at 61% cost. **And with Codex OAuth both halves run flat-rate on one ChatGPT Pro subscription** — token billing doesn't apply at all on the model side (embeddings still need a separate API key, $-pennies). The "15× tokens" figure cited in earlier drafts is the *naive same-frontier-model-everywhere* case, not this design. Two-brain AI is a real architectural pattern, not an analogy stretch — backed by 2026 Frontiers cognitive theory, with working analogues in SOFAI (System 1/2 + metacognitive layer), Talker-Reasoner, and Anthropic's orchestrator-subagent. A2A handles delegation between the halves — each exposes an Agent Card; either calls `a2a_delegate` to task the other; internals stay private. Failure-mode taxonomy (MAST, 1,600 traces, 14 modes) is well-documented with known mitigations.

**Last updated:** 2026-05-11
**Verification:** [verified] sections are direct WebFetch from primary source today (Anthropic engineering blog, github.com/AaronWong1999/hermesclaw, freecodecamp A2A plugin guide, a2a-protocol.org). [unverified] means relayed from secondary sources without primary-source confirmation. Specific token/cost numbers are quoted from Anthropic's own writeup; treat as one data point, not a guarantee for our workload.
**Source:** Live web research 2026-05-11.

---

## IMPLEMENTATION STATE (v1.1 build, in progress 2026-05-12)

The v1.0 install left a gap: A2A registry + Agent Cards were published but neither agent consumed them. v1.1 closes that gap. Current state of what's now in scope:

| Element | v1.1 status |
|---|---|
| OpenClaw + Hermes daemons | ✅ installed by `scripts/install-cto.sh` |
| A2A registry process | ✅ installed (Python HTTP server, port 9000) |
| `a2a_delegate` MCP server on OpenClaw | 🟡 in progress (Wave 2) |
| Hermes A2A endpoint sidecar (`/a2a` on 8642) | 🟡 in progress (Wave 2) |
| Bearer-token auth between halves (`HERMES_A2A_TOKEN`) | 🟡 in progress (Wave 2) |
| System-prompt extensions per hemisphere | ✅ written (`OPENCLAW_ROLE.md`, `HERMES_ROLE.md`) |
| Heartbeat watcher (Hermes restarts OpenClaw on crash) | 🟡 in progress (Wave 3) |
| Health watcher (outcome-based, Approach C) | 🟡 in progress (Wave 3) |
| Anomaly watcher (baseline-relative, Approach A — context only, no auto-action) | 🟡 in progress (Wave 3) |
| Autonomous-repair runner | 🟡 in progress (Wave 3) |
| Shared memory (engram via MCP, both hemispheres) | 🟡 in progress (Wave 2 wiring) |
| PWA at `cto.husband.llc` (BACKLOG-001 build) | 🟡 in progress (Wave 4) |

## CHAT MODEL (PWA observability + @-mention routing)

The PWA chat is a **three-party conversation** — John, OpenClaw, Hermes — with full observability of inter-hemisphere traffic:

- Default messages from John route to **OpenClaw**.
- John can address Hermes directly via `@Hermes <message>` (PWA backend parses the @-mention, routes to Hermes's A2A endpoint with `sender: "john"`).
- John can address OpenClaw explicitly via `@OpenClaw <message>` (same as default but explicit).
- Every A2A delegation (OpenClaw → Hermes) and its response (Hermes → OpenClaw) is **logged to chat** so John sees the internal conversation. Sender is rendered visibly (color-coded, icon).
- Hermes never speaks unprompted unless: (a) responding to a delegation, (b) responding to a direct @-mention, (c) raising an escalation (heartbeat / health / repair failure), or (d) a daily-digest-trigger event.

## SHARED MEMORY (engram via MCP)

Both hemispheres consume the same engram instance at `/opt/cto/.engram/` via MCP. Shared corpus: research findings, decisions, John's stated preferences, cross-session context. Hermes-only memory (auto-created skills): stays in `~/.hermes/skills/`. OpenClaw-only state (session history): stays in `~/.openclaw/`.

Engram does FTS5 keyword search + LLM-as-semantic-judge. Vector search via `sqlite-vec` extension is deferred — adopt only if observed recall ceiling demands it. (Per the "simplest thing that works" principle.)

---

## The Design (per John, 2026-05-11)

- **Left hemisphere:** OpenClaw
- **Right hemisphere:** Hermes
- **Property:** They can task each other (bidirectional delegation, not master-slave)
- **Goal:** A CTO with breadth *and* depth — community ecosystem (OpenClaw) and compounding self-improvement (Hermes) in one operational organism

This is a deliberate departure from the 2026-04-26 single-framework decision (`wiki/v1-evaluation.md`). It says: don't pick one — use both, with each specialised for what it does best.

---

## Why the Hemisphere Analogy Holds Up [verified — 2026 Frontiers cognitive theory + community architecture literature]

From the Hemispheric Disparity Theory (Frontiers in Psychology, 2026):

> "Conscious experience arises from the dynamic interplay between a left hemisphere specialised in order and abstraction through dynamic temporal modelling, and a right hemisphere specialised in contextual integration, coherence, and model updating through attentional networks."

Mapping to our two agents, with John's "thinking/doing" framing aligned:

| Brain function | Hemisphere | Mapped to | What it does | Why it fits |
|---|---|---|---|---|
| Order, abstraction, temporal modelling — **thinking** | Left | **OpenClaw** | Orchestrator: receives inbound, plans, decides what should happen, delegates | Gateway-first design, structured cron, messaging routing, decision layer over a 44K-skill catalogue. The orchestrator role wants a capable model — Codex/GPT-5.5 fits. |
| Contextual integration, coherence, model updating — **doing** | Right | **Hermes** | Worker: executes the plan, runs skills, learns from execution outcomes | Execution-with-learning is Hermes's signature: skill auto-creation from execution traces, GEPA optimises *the doing*, Curator + FTS5 recall + Honcho user model all keyed off what actually got done. |

This is not a stretched analogy — "Dual-Brain System Architecture" is an established class of AI design with explicit role separation, subsystem specialisation, and controlled information exchange. The community converged here without our nudge. The orchestrator-worker pattern is the production-validated mapping: 40-60% cost savings cited across 2026 sources, with the orchestrator using a capable model and the worker using whatever fits the task. In our flat-rate ChatGPT Pro design, both run on the same subscription — but the *thinking/doing* split still matters because it concentrates the heavy reasoning in OpenClaw (fewer, denser calls) and the execution loop in Hermes (many smaller calls, with learning baked in).

---

## Sibling Architectures (Prior Art We Should Learn From)

### SOFAI — Slow and Fast AI (Kahneman-inspired)
A "metacognitive agent" oversees both a **fast (S1) solver** (data-driven, pattern-matching, past-experience-based) and a **slow (S2) solver** (symbolic, rule-based, reasoning-over). The metacog decides which to invoke. Combining the two yields higher decision quality *with less* resource consumption than using either alone.

**Implication for our design:** We probably need a metacognitive layer that decides whether a task lands at OpenClaw or Hermes. Without it, every task bounces or duplicates. Anthropic's lead-researcher pattern fills this role.

### Talker-Reasoner Architecture
Two-agent split:
- **Talker** — fast intuitive conversation, customer-facing, low-latency.
- **Reasoner** — slow planning, complex belief-state maintenance.

The Talker handles the user; it queues hard problems for the Reasoner to chew on asynchronously, then surfaces results back.

**Implication for our design:** OpenClaw (Talker-like) handles inbound messaging + routing; Hermes (Reasoner-like) gets long-running research/synthesis. Pushed back to OpenClaw for delivery.

### Anthropic Orchestrator-Subagent [verified — anthropic.com/engineering/multi-agent-research-system]
Lead agent decomposes complex queries into specialised tasks, spawns subagents for parallel exploration, then consolidates findings. Key findings:

- **Context persists in external memory.** The LeadResearcher saves its plan to Memory because context-window truncation (>200K tokens) destroys handoff fidelity otherwise.
- **Subagents return *structured findings*, not raw output.** This is Anthropic's term for it: "minimising the game of telephone."
- **Cost:** "Agents typically use about 4× more tokens than chat interactions, and multi-agent systems use about 15× more tokens than chats."
- **When it wins:** 90.2% better than single Opus 4 on internal evals — "token usage by itself explains 80% of the variance."
- **Where it shines:** parallel breadth-first work, info exceeding single context, complex tool interfacing.
- **Where it loses:** simple queries (overhead exceeds benefit), sequential dependencies that can't parallelise.

---

## Practical Reference Implementations

### HermesClaw — Hermes + OpenClaw on one account [verified — github.com/AaronWong1999/hermesclaw]
A thin Python proxy (~870 lines) that lets Hermes Agent, OpenClaw, and OpenCode share **one WeChat account**. Three ports:

- **Proxy A (19999)** — handles OpenClaw
- **Proxy B (19998)** — handles Hermes Agent
- **ACP Bridge** — subprocess protocol for OpenCode

The proxy doesn't process media, call agent APIs, or touch agent memory. It only queues and forwards raw iLink protocol messages. User commands `/hermes`, `/openclaw`, `/opencode`, `/both`, `/three` route messages explicitly.

**Lesson for us:** A shared messaging surface with explicit routing keywords is a real working pattern. But this is **co-existence**, not **collaboration** — the agents don't task each other; the user routes each message to one.

For our design, we need more than HermesClaw: we need A2A so agents can delegate without a human in the loop.

### OpenClaw A2A Plugin Bridge [verified — freecodecamp.org/news/openclaw-a2a-plugin-architecture-guide]
Treats OpenClaw as an **A2A client, not server** — the local gateway never gets exposed publicly. Components:

| Component | Purpose |
|---|---|
| `a2a_delegate` tool | Explicit entry point: OpenClaw calls this to delegate a task to a remote agent |
| Agent Card cache | Stores remote agent capabilities, ETag revalidation |
| Session-to-Task Mapper | Maps OpenClaw conversational sessions to A2A task contexts |
| Task Poller | Polls for completion of long-running remote tasks |
| Gateway diagnostics method | Health-check endpoint for the relay |
| HTTP callback route | For future async push-back from remote agents |
| Background service | Cache warming + maintenance |

Key design principle (quote):

> "Treat the OpenClaw session as the long-lived conversational boundary, and treat each A2A task as one delegated execution inside that boundary."

The relay should: resolve allowlisted remote Agent Cards, reuse existing A2A `contextId` for the same `sessionKey`, create a fresh remote `Task` per delegated turn, normalise remote artifacts back to local replies, and **never expose the OpenClaw Gateway directly to the public internet**.

**Lesson for us:** This is exactly the left-hemisphere half of our design. OpenClaw can already do this. We need to verify Hermes can do the symmetric thing (act as A2A client / server).

---

## A2A as the Corpus Callosum [verified — a2a-protocol.org + IBM + Linux Foundation]

A2A is the standard inter-agent wire format. Production-ready, 150+ orgs, 22K GitHub stars, Linux Foundation governance.

| Property | Detail |
|---|---|
| Transport | HTTP + Server-Sent Events + JSON-RPC 2.0 |
| Discovery | Agent Cards (capability advertisement) |
| Interaction modes | Synchronous request/response, streaming for real-time, async push for long-running |
| Privacy | "Without exposing internal memory, tools, or proprietary logic" — each agent's internals stay private |
| SDKs | Python, JavaScript, Java, Go, .NET (all production-ready) |
| Production users | Google, Microsoft, AWS, Salesforce, SAP, ServiceNow, Workday, IBM |

A2A is purpose-built for the exact pattern we want: two opaque agentic systems discover each other's capabilities, negotiate, and exchange tasks without sharing state.

**Both hemispheres expose Agent Cards.** Either can call the other. The protocol handles auth, task lifecycle, streaming progress, and async completion callbacks.

---

## Proposed Hemisphere Architecture (CTO Application)

```
                    ┌──────────────────────────────────────────┐
                    │            METACOGNITIVE LAYER            │
                    │   (router: which hemisphere owns this?)   │
                    │   SOFAI-style, lightweight LLM-based      │
                    └──────────────────┬────────────────────────┘
                                       │
              ┌────────────────────────┴────────────────────────┐
              │                                                  │
   ┌──────────▼──────────┐                          ┌────────────▼──────────┐
   │   LEFT HEMISPHERE    │      A2A protocol       │   RIGHT HEMISPHERE     │
   │      OPENCLAW        │ ◄────(corpus callosum)──►│       HERMES           │
   │                      │      JSON-RPC + SSE     │                        │
   │ • Gateway-first      │     Agent Cards         │ • Self-improving       │
   │ • 18+ msg platforms  │                         │ • GEPA optimisation    │
   │ • Operational, fast  │                         │ • Skill auto-creation  │
   │ • Community skills   │                         │ • FTS5 recall          │
   │ • Routes inbound     │                         │ • Curator agent        │
   │   messaging          │                         │ • Honcho user model    │
   │                      │                         │                        │
   │ A2A client +         │                         │ A2A client +           │
   │ a2a_delegate tool    │                         │ a2a_delegate tool      │
   └──────────────────────┘                         └────────────────────────┘
              │                                                  │
              │              ┌──────────────────┐                │
              └──────────────►   SHARED LAYER  ◄─────────────────┘
                             │ • A2A registry   │
                             │ • Audit log      │
                             │ • Budget meter   │
                             │ • Circuit breakr │
                             └──────────────────┘
```

### Hemisphere assignments (orchestrator-worker mapping)

**OpenClaw (left, thinking) — orchestrator:**
- Receives inbound user messaging (via A2A human interface — Telegram/Discord/etc. are NOT used per CTO-DECISION-006). OpenClaw remains gateway-first internally; the human-facing surface is A2A.
- Decides which work needs doing, in what order, by which hemisphere
- Decomposes complex requests into delegable sub-tasks
- Owns the conversation thread with the user
- Delegates execution work to Hermes via A2A
- Synthesises Hermes's returned artifacts back into user-facing replies
- Cron-scheduled research planning (when + what to research; the *what* gets handed to Hermes for execution)

**Hermes (right, doing) — worker:**
- Executes delegated tasks: skill runs, multi-step research, tool chains, browser automation
- Learns from execution traces — auto-creates skills, GEPA-optimises them
- Returns structured findings to OpenClaw, not raw output
- Owns long-horizon execution where the learning loop pays off
- Can delegate back to OpenClaw for anything in OpenClaw's messaging/operational wheelhouse (e.g., "post this notification")

**Bidirectional, but asymmetric.** OpenClaw → Hermes is the dominant flow (orchestrator → worker). Hermes → OpenClaw happens for operational follow-ups (notifications, scheduled rollouts, gateway-only actions). The corpus callosum (A2A) doesn't care which direction; the discipline lives in the Agent Card capability declarations.

**Examples:**
- User: "research the AI landscape this week and report by Sunday."
  - OpenClaw plans the research scope, delegates the actual scanning + synthesis to Hermes, receives structured findings, formats and delivers the Sunday report.
- Hermes finishes a skill-improvement GEPA pass overnight.
  - Hermes delegates "notify John this skill upgrade landed" to OpenClaw, which surfaces it through the A2A human interface (and writes to `/opt/cto/logs/digest/` as the interim record per CTO-DECISION-006).

### Shared layer (critical — do not skip)

- **A2A registry** — both Agent Cards published here; each hemisphere discovers the other.
- **Audit log** — every cross-hemisphere call logged with task ID, hemisphere, prompt, cost, outcome.
- **Budget meter** — hard kill on token spend per task (anti-infinite-loop).
- **Circuit breaker** — N consecutive failures from one hemisphere → quarantine that hemisphere for cooldown.

---

## Self-Modification — Which Hemisphere Can Change What [verified 2026-05-11]

This is the question John pushed on: *what is Hermes actually capable of modifying — skills only, or architecture too? Can Hermes edit its own code? Can Hermes edit OpenClaw's code? Should we fork either?*

Answers, each backed by primary-source research today (full sources in Sources section):

### Q1: Can Hermes update its very architecture (not just skills)?

**Partially. Bounded by design, not impossible.**

Hermes Agent itself (the runtime) doesn't rewrite its own architecture autonomously — there's no native "swap my memory layer" or "replace my LLM router" operation. But the companion repo **`hermes-agent-self-evolution`** explicitly targets code modification in four phases:

| Phase | Target | Status |
|---|---|---|
| Phase 1 | Skill files | Implemented |
| Phase 2 | Tool descriptions | Planned |
| Phase 3 | System prompts | Planned |
| **Phase 4** | **Tool implementation code (`tools/*.py`)** | **Planned — Darwinian Evolver wraps tool files as `GitBasedOrganism`, composite fitness via pytest + benchmarks + bug repro** |

Phase 4 *is* code-level architecture modification — just bounded to tool implementations rather than the agent kernel. The kernel itself (the `AIAgent` loop, the gateway, the memory ABC) is not in scope of the self-evolution framework. Replacing the kernel is **CTO's macro-evolution job**, run through the existing clone-test-replace upgrade cycle on a fresh Hetzner VPS — not something Hermes does to itself.

### Q2: Can Hermes edit its own code?

**Yes — via the external self-evolution CLI, not in-process.**

Critical detail from the official Hermes self-evolution PLAN.md (quote): *"hermes-agent-self-evolution operates ON hermes-agent, not inside it. Zero changes to the agent repo are needed. It reads from the hermes-agent codebase and writes evolved versions to git branches, creating PRs for human review."*

So Hermes-the-runtime doesn't modify its own running code. A *separate* Hermes-driven process reads the codebase, runs DSPy + GEPA, and emits a PR. Validation gates:

- Full test suite must pass
- Skill files ≤ 15KB
- Tool descriptions ≤ 500 chars
- Caching compatibility check
- Semantic preservation check
- **All automated PRs require human merge** — quote from PLAN.md

For our CTO design, "human merge" maps cleanly onto the existing upgrade cycle: CTO is John's autonomous agent, and the CTO itself plays the human-merge role under the discipline of clone-test-replace on a fresh VPS. The PR gate becomes the CTO's existing test-and-promote gate.

### Q3: Should we have Hermes update OpenClaw?

**Yes — this is named in 2026 industry writing as the "mature architecture" pattern.** Quote from research: *"the mature architecture involves using OpenClaw to run the agent in production (tools + workflows + skills + messaging) and using a Hermes-style loop to improve it (evals + regression tests + controlled patches)."*

The Phase 4 wrapper is **repo-agnostic** by design: it maps any file to a `GitBasedOrganism` and runs a fitness function over it. Pointing it at OpenClaw's `tools/` directory (or skill files, or config) is a configuration choice, not a code change to Hermes itself.

There's also the broader **HyperAgents** pattern (Meta, ICLR 2026, arXiv 2603.19461): "task and meta agents co-modify themselves, enabling metacognitive self-improvement." A task agent solves the target work; a meta agent modifies *both itself and the task agent.* The meta-modification procedure is itself editable. The DGM-Hyperagents variant (DGM-H) outperformed baselines across coding, paper review, robotics, and Olympiad math — code self-modification generalises beyond coding.

**Mapping to our two-hemisphere CTO:**
- OpenClaw = task agent (runs production: messaging, routing, orchestration)
- Hermes = meta agent (proposes improvements to itself AND to OpenClaw)
- Both modifications gated through CTO's existing clone-test-replace upgrade cycle on a fresh Hetzner VPS

This does **not** violate SOUL.md principle 11 ("Never touch what isn't yours"). OpenClaw is part of the CTO project — it's the left hemisphere of our own brain. Hermes patching OpenClaw's tool files inside our repo is not touching an outside system. The boundary that matters: never push to `openclaw/openclaw` upstream without explicit John approval. Carry patches in our own repo or a CTO-controlled fork.

### Q4: Should we consider forking either project?

**Not initially. Fork only when forced.**

Findings from production patterns research:

- **OpenClaw's release cadence is "unusually aggressive"** in 2026 — managing patches and rebasing customizations against a moving target is a real cost.
- **"Teams that outgrow OpenClaw's defaults often find themselves forking the project rather than extending it cleanly due to the codebase being less modular."** [verified — community quote]
- A real example: **`ClawTeam-OpenClaw`** fork ([github.com/win4r/ClawTeam-OpenClaw](https://github.com/win4r/ClawTeam-OpenClaw)) maintains a fork with "all upstream fixes synced." Practical, doable, not free.

**Default position: don't fork either project.** Reasons:
1. Both move fast (OpenClaw weekly, Hermes ~2 weeks). Rebase cost compounds.
2. Patches live more naturally in a CTO-owned **patches/skills layer** that overlays the upstream codebase at startup — most things can be customized without touching framework source.
3. If a patch *must* land in framework source: upstream the PR first. If rejected, *then* fork.
4. Forking turns the CTO from "user of community frameworks" into "maintainer of two custom frameworks." That's a different job and contradicts SOUL.md value: "the community is the architect."

**When forking becomes the right call:**
- A patch that doesn't get accepted upstream after a reasonable attempt, but is required for CTO operation
- Upstream stalls or pivots away from a feature CTO depends on
- A security CVE that upstream hasn't patched after a documented window

**If we fork:** rebase weekly, automate the sync test (does upstream `main` merge cleanly into our fork?), keep the patch set small and well-documented. CTO's existing decision-log discipline applies to every fork-carrying patch.

### What this means for hemisphere assignment

**Hermes (right, doing) — natural owner of:**
- Skill creation / improvement (its core differentiator)
- Long-horizon execution where the learning loop pays off
- **Generating patches against the CTO's tool code — both Hermes's own tools AND OpenClaw's tools** — via Phase 4 self-evolution framework
- Producing evaluation suites + regression tests for proposed changes
- The "meta-agent" role in a HyperAgents-style co-modification setup

**OpenClaw (left, thinking) — natural owner of:**
- Inbound user messaging, routing, conversation thread ownership
- Decomposing user requests into delegable subtasks
- Production execution of the CTO's operational duties (cron, gateway, skills)
- The "task agent" role in HyperAgents framing
- The final-mile delivery (A2A human interface; daily digest written to `/opt/cto/logs/digest/`)

**CTO upgrade cycle (the shared spine) — owner of:**
- Reviewing/merging Hermes-generated PRs (replaces "human merge" gate)
- Provisioning fresh Hetzner VPS for candidate testing
- Running full test suite + benchmark suite on candidate
- Promote or destroy based on results
- Writing HANDOFF.md
- Snapshot + git tag + decision log

**Architecture-level changes (LLM provider swap, memory layer replacement, agent framework substitution) remain CTO's macro-evolution job, NOT delegated to Hermes.** SOUL.md principle 6 binds: never downgrade the design for convenience.

### When Hermes (or OpenClaw) needs something outside its native scope — the backlog flow

Either hemisphere can encounter a capability it can't autonomously deliver. The discipline is:

| Situation | Hemisphere action | Output |
|---|---|---|
| Hermes self-evolution proposes a Phase 1-4 change (skills, prompts, tool descriptions, `tools/*.py`) | Generate PR → CTO clone-test-replace cycle reviews | Normal patch flow, no backlog entry |
| Hermes self-evolution wants to change something beyond Phase 1-4 (kernel, memory ABC, gateway core, framework swap) | **Stop. Log a `fork-trigger` entry in BACKLOG.md.** | Backlog entry; awaits John's review |
| Hermes Phase 1-4 patch is worth upstreaming | Log an `upstream-pr-needed` entry | Backlog entry; John approves before submission |
| OpenClaw needs a skill, none exists in ClawHub or community after a documented search | Log a `missing-skill` entry | Backlog entry; Hermes may attempt auto-creation, otherwise John triages build-vs-defer |
| OpenClaw (or Hermes) needs an MCP and no public server provides it after a documented search | Log a `missing-mcp` entry | Backlog entry; John triages build-vs-defer |
| CTO research turns up a community pattern that requires source-level adoption in either framework | Log a `fork-trigger` entry | Backlog entry; John reviews |

Every entry includes a documented `search_trail` — no silent escalations. Full schema, statuses, and operating rules in [`BACKLOG.md`](BACKLOG.md) at repo root. The backlog is surfaced in the daily digest (A2A human interface per CTO-DECISION-006) so John sees new entries within 24 hours.

**The boundary line:** if it's inside Hermes's Phase 1-4 scope and an upstream-friendly change, ship it through the upgrade cycle. If it requires a fork, a custom MCP, or a missing skill, it's a backlog entry. The backlog is the only path that involves John before action.

---

## How Hermes-Proposed Patches Flow Through the CTO Upgrade Cycle

```
┌──────────────────────────────────────────────────────────────────┐
│ Hermes self-evolution loop (right hemisphere, daily/scheduled)    │
│                                                                    │
│ 1. Hermes reads execution traces (its own + OpenClaw's)            │
│ 2. GEPA identifies failure patterns and proposes mutations         │
│ 3. Phase 1-4 targets: skills, prompts, tool descriptions, tool code│
│ 4. Output: git branch + PR against CTO repo with proposed change   │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
┌──────────────────────────────────────────────────────────────────┐
│ CTO clone-test-replace gate (existing upgrade cycle)               │
│                                                                    │
│ 5. Research the target — does the patch's blast radius extend     │
│    beyond what was claimed? Recurse dependency chain.              │
│ 6. Provision fresh Hetzner VPS                                     │
│ 7. Apply Hermes's patch to candidate                               │
│ 8. Full test suite on real infrastructure                          │
│ 9. Architecture validation against community sentiment (per        │
│    wiki/architecture-validation-process.md)                        │
│ 10. Pass: snapshot prod, promote candidate, archive old, HANDOFF   │
│     Fail: iterate 3x or destroy candidate with documented reason   │
│ 11. Report via A2A human interface (digest to /opt/cto/logs/digest)│
└──────────────────────────────────────────────────────────────────┘
```

**One material change per cycle** [SOUL.md principle 15]. Hermes can generate many patches; CTO merges them one at a time through the upgrade gate. This bounds blast radius and keeps the rollback story clean.

---

## Failure Modes — Design Against These [verified — MAST taxonomy, 1,600 traces, 14 modes]

| Mode | What it looks like | Mitigation |
|---|---|---|
| **Infinite loops** | OpenClaw delegates to Hermes, Hermes delegates back, ping-pong until budget exhaust. "Thousands of dollars lost in minutes." | Hard budget cap per task. Max delegation depth (e.g., 3). Loop detector on the audit log — if same task ID bounces twice, kill. |
| **Coordination overhead** | 100–500ms per handoff × N handoffs = 1–5s pure overhead for a 10-step chain. | Limit handoff depth. Prefer batching at delegation time. Async push for long tasks so we don't poll-block. |
| **Context loss** ("context collapse") | Agent passes raw conversation history; receiver context window saturates; key decisions vanish. | Pass **structured task contracts**, not raw history. Anthropic's "structured findings" pattern. External memory for the plan (LeadResearcher pattern). |
| **Specification/design failures (41.8% of MAST)** | Ambiguous task boundaries, missing termination conditions, role confusion. | Explicit Agent Cards. Explicit task contracts: input schema, output schema, success criteria. |
| **Inter-agent misalignment (36.9%)** | Hermes optimises for a different objective than OpenClaw expected. | Shared success criteria embedded in the task contract. Both hemispheres see the same goal definition. |
| **Verification failures (21.3%)** | Delegated work returned but not validated; receiver assumes success. | Receiver must run an explicit verification step on returned artifacts. Cheaper LLM call is fine; just don't trust blindly. |
| **Token cost explosion** | "Multi-agent systems use about 15× more tokens than chats" (Anthropic). | Budget per task. Per-day budget per hemisphere. Daily report includes spend breakdown. |
| **Spawn explosion** | Anthropic's early failure: agents spawned excessive subagents for simple queries. | Metacognitive layer rejects multi-agent for trivial tasks. Single-agent fallback path is always available. |

---

## Cost Model — Corrected [verified 2026-05-11]

**Earlier draft was wrong.** I cited Anthropic's "multi-agent uses 15× more tokens than chat" as a ceiling on this design. That figure is the *naive same-frontier-model-everywhere* case — not this design. The orchestrator-worker pattern with thinking/doing specialisation is documented across 2026 industry sources as **cheaper than monolithic frontier**, not more expensive. And in our specific design both halves run on **Codex OAuth against one ChatGPT Pro subscription**, so the model side is flat-rate, not per-token at all.

### Per-token economics with proper specialisation [verified]

| Pattern | Cost outcome | Source |
|---|---|---|
| Tiered Intelligence Stack (3 tiers, deliberate routing) | **$2.31 vs $18.40 per M tokens** — 87.4% reduction vs all-frontier | AICC Report 2026 |
| Hierarchical multi-agent (frontier orchestrator + budget workers) | **97.7% of full-frontier accuracy at ~61% cost** | Industry guides 2026 |
| Orchestrator-worker with model-tier matching | **40-60% cost reduction** | Stevens Online / Azure Architecture |
| Right-tool routing on specialised tasks | **30-60% savings**, up to 15-50× on specific tasks | MindStudio / Morph |
| Smaller models on worker tasks (Llama 3.1 8B, Phi-3 Mini) | **10-50× cheaper per token** | NVIDIA |

The right-tool-for-the-right-job principle wins because most worker calls don't need frontier reasoning — classification, extraction, summarisation, tool invocation, skill execution all work on budget-tier models. The orchestrator's per-token cost is small relative to total spend because the orchestrator runs on relatively few tokens compared to actual task execution.

### Our actual cost model — Codex OAuth on John's existing Business seat [verified — CTO-DECISION-008]

Both OpenClaw and Hermes verified to support `openai-codex` OAuth against a ChatGPT subscription. Reality: John has an existing **ChatGPT Business standard seat at $30/seat** (single seat). Pro $200/mo cannot be added to the same email since John has no Personal workspace. Implications:

- **Model cost: $30/month** — John's existing Business seat, which already includes Codex.
- **Codex 5-hour quotas on Business [verified — OpenAI Codex rate card]:**
  - GPT-5.4-mini: 1,200-7,000 local msgs / 5h
  - GPT-5.3-Codex: 600-3,000 local + 200-1,200 cloud msgs / 5h
  - GPT-5.4: 400-2,000 / 5h
  - Code Reviews: 400-1,000 / 5h
- **Expected quota pressure.** John explicitly expects we may hit limits, drawing parallel to prior OpenRouter quota issues. Instrument quota observation from day one. Treat first throttle as expected, not a surprise.
- **Escape if Business quotas constrain operation:** ChatGPT Pro on a *separate email* (~$200/mo additional), re-point the Codex OAuth profiles. **No PAYG Codex seats** — John explicitly avoiding accidental-overspend risk.
- **Embeddings: separate, pennies.** Codex subscription does NOT include embeddings. We need a tiny `OPENAI_API_KEY` for `text-embedding-3`.
- **Inter-agent A2A traffic: not metered.** A2A is JSON-RPC over HTTP; the only model spend is when an agent calls its LLM. The protocol itself is free.

### Cost ceiling

- **Day 1:** $30/month (existing Business seat) + pennies for embeddings.
- **If quotas hold:** indefinite operation at $30/month.
- **If quotas constrain and Pro is added on a separate email:** $30 + $200 = $230/month ceiling. Adding Pro is a deliberate decision, not an automatic billing event.
- **Worst case is bounded.** No PAYG. No accidental overspend.

### Standing risks (real, not cost-shaped)

- **Rate-limit exhaustion** — heavy GEPA passes + many skill executions on Hermes could burn through Codex quotas during a 5-hour window. Need a budget-aware throttle on Hermes; instrument quota observation early.
- **Codex OAuth can drift** — both halves maintain separate credential stores; one expired token kills its hemisphere. Need a health monitor on both.
- **Single-seat single-account dependency** — if John's Business seat is suspended or downgraded, both hemispheres lose LLM access simultaneously. OpenRouter fallback config in both hemispheres mitigates this if pre-configured with a working key.

---

## Provider Strategy — Codex OAuth for Both Hemispheres [verified 2026-05-11]

Both halves verified at primary sources to support OpenAI Codex authentication via ChatGPT subscription OAuth — not API key. Same $200/mo subscription powers both.

### OpenClaw side [verified — docs.openclaw.ai/providers/openai + wiki/codex-oauth-setup.md]

- **Provider name:** `openai-codex`
- **Model route:** `openai/gpt-5.5` (canonical) via Codex OAuth
- **Headless VPS path (we need this):** `openclaw models auth login --provider openai-codex --device-code`
- **Setup sequence:**
  ```bash
  openclaw models auth login --provider openai-codex --device-code
  openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5
  openclaw gateway restart
  openclaw models status
  ```
- **Credentials:** OpenClaw stores in its own agent auth store (path not specified in current docs; older versions used `~/.openclaw/auth-profiles/openai-codex.json`).
- **Caveat:** Onboarding no longer auto-imports OAuth material from `~/.codex/auth.json` (per current OpenClaw docs). Must run the device-code flow explicitly.
- **Minimum version:** v2026.4.22+ for device-code support.
- **Prerequisite:** Enable **Device Code Authorization** in ChatGPT Security Settings first.

### Hermes side [verified — hermes-agent.nousresearch.com/docs/integrations/providers]

- **Provider name:** `openai-codex` (same name as OpenClaw — coincidence, not interop)
- **Auth flow:** Device code (open URL, enter code) — works headless natively
- **Credential store:** `~/.hermes/auth.json`
- **Key shortcut:** Hermes **can import existing Codex CLI credentials from `~/.codex/auth.json` when present** — quoted directly from the official Hermes provider docs. So if you run `codex login` once on the VPS, Hermes can reuse those credentials instead of doing a second device-code flow.
- **Available models:** `gpt-5.5` reasoning model accessible through ChatGPT Codex OAuth (Hermes docs don't enumerate the full list but model picker has live discovery wired in).
- **No Codex CLI installation required** — Hermes implements the device-code flow itself.

### One subscription, both halves — workflow

1. Subscribe to ChatGPT Pro at chatgpt.com/pricing ($200/mo) — manual step, no programmatic creation.
2. Enable Device Code Authorization in ChatGPT Security Settings.
3. On VPS, do **one** device-code flow per hemisphere:
   - `openclaw models auth login --provider openai-codex --device-code`
   - In Hermes: configure `openai-codex` provider via `hermes model`, complete device code
4. Set both hemispheres' default model to `openai/gpt-5.5` (canonical OpenAI ID).
5. Add a tiny `OPENAI_API_KEY` to both configs for embeddings — subscription auth does **not** cover embeddings.

### Risks to flag

- **Rate-limit pressure.** Both halves drawing on one subscription's quota at once. Pro $200 = 20× Plus (25× promo through May 31). If GEPA pass + skill execution + research scan all fire at once, we throttle. Need a coordinated rate-limit awareness layer (the shared budget meter from the architecture diagram).
- **Auth drift.** Two separate credential stores. If OpenClaw's expires, OpenClaw stalls; same for Hermes. Need a health monitor on both.
- **Codex subscription model availability** can change. OpenAI has shifted what's accessible via OAuth before. Watch for changes in available model IDs.

---

## What Already Works vs. What We'd Need to Build

| Component | Status | Notes |
|---|---|---|
| OpenClaw as A2A client | **Documented pattern** | freecodecamp guide is a recipe, not magic. |
| **OpenClaw + Codex OAuth (headless)** | **Verified working** | docs.openclaw.ai confirms `--device-code` flow; `wiki/codex-oauth-setup.md` has full playbook. |
| Hermes as A2A client/server | **Unverified — needs check** | Hermes has gateway + delegation primitives (`delegate_task`, role-gated subagents per AGENTS.md). Whether it speaks A2A natively or needs a shim — still needs verification. |
| **Hermes + Codex OAuth (headless)** | **Verified working** | hermes-agent.nousresearch.com/docs/integrations/providers confirms `openai-codex` provider with device-code flow + `~/.codex/auth.json` import. |
| HermesClaw-style messaging coexistence | **Working repo** | Practical example but human-routed, not autonomous. Useful as a fallback if A2A integration takes longer than expected. |
| Metacognitive router | **Build new** | Lightweight LLM call. SOFAI is the reference architecture. In orchestrator-worker form, this is largely subsumed by OpenClaw (the orchestrator decides what gets delegated). |
| A2A registry, audit, budget, circuit breaker | **Build new** | Standard production hardening. Not novel; needed. Budget layer especially matters with shared ChatGPT subscription. |
| Inter-hemisphere skill format | **Open question** | OpenClaw skills are Node, Hermes skills are Python directories with `SKILL.md`. They can call each other via A2A but cannot share skill code directly. |

---

## Open Questions Before Committing

1. **Does Hermes natively speak A2A?** Need to verify against current Hermes (v0.13.0) docs and code. If not, what's the shim?
2. **Where does the metacognitive router live?** Inside OpenClaw, inside Hermes, or its own process? SOFAI puts it separately; that probably wins for our case (lets us reason about it independently).
3. **What's the task-contract schema?** Anthropic uses structured findings; A2A uses Tasks + Artifacts. We need to pick one canonical format both hemispheres respect.
4. **Single A2A registry or two?** If both expose Agent Cards on the same registry, capability advertisement is trivial. If separate, the metacog needs to know both.
5. **Failure recovery — who owns the cleanup?** If Hermes hangs mid-delegation, does OpenClaw timeout and retry? Where does the partial state live?
6. **Does this break the 2026-04-26 decision?** That decision picked one framework partly because macro evolution needs loose coupling. Two-hemisphere is *more* coupled by definition. Is the dual-specialisation worth the coupling cost?
7. **Budget reality check.** 15× token multiplier vs current CTO budget — does this need a new budget conversation with John before we build?
8. **Cognitive coherence — is one CTO or two?** The CTO is supposed to be a *single* AI employee. Two hemispheres with bidirectional delegation is fine technically; ensure the *user-facing identity* stays singular (decisions logged under one CTO, reports come from one CTO, John talks to one CTO).

---

## Relationships to Other CTO Docs

- [`hermes.md`](hermes.md) — fresh reference for the right hemisphere (2026-05-11)
- [`wiki/v1-evaluation.md`](wiki/v1-evaluation.md) — the single-framework decision this design proposes to revisit
- [`wiki/a2a-communication.md`](wiki/a2a-communication.md) — existing CTO docs on A2A; we'd extend these
- [`wiki/research-agent-frameworks.md`](wiki/research-agent-frameworks.md) — full landscape; nothing else looks better than these two for the dual-hemisphere role
- [`HANDOFF.md`](HANDOFF.md) — captures HANDOFF.md mistake #9 (don't downgrade architecture for implementation convenience). Same principle applies here in reverse: don't upgrade architecture for novelty.
- [`PRD.md`](PRD.md) — the requirements the design must serve, not the other way around
- [`SOUL.md`](SOUL.md) — operating principles; "macro evolution > micro evolution" was the philosophical basis for picking one framework. Two-hemisphere says: both matter, take both.

---

## Sources

Live research 2026-05-11:

- [NousResearch/hermes-agent-self-evolution — GitHub](https://github.com/NousResearch/hermes-agent-self-evolution)
- [hermes-agent-self-evolution PLAN.md (Phase 4 code modification)](https://github.com/NousResearch/hermes-agent-self-evolution/blob/main/PLAN.md)
- [Hermes Agent Architecture — official docs](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture)
- [Hyperagents — Meta AI / ICLR 2026 (task + meta agent co-modification)](https://arxiv.org/abs/2603.19461)
- [Meta researchers introduce 'hyperagents' to unlock self-improving AI — VentureBeat](https://venturebeat.com/orchestration/meta-researchers-introduce-hyperagents-to-unlock-self-improving-ai-for-non-coding-tasks)
- [Self-Improving AI Agents: The 2026 Guide — o-mega](https://o-mega.ai/articles/self-improving-ai-agents-the-2026-guide)
- [Self-Evolving Agents: Open-Source Projects Redefining AI in 2026 — Medium](https://evoailabs.medium.com/self-evolving-agents-open-source-projects-redefining-ai-in-2026-be2c60513e97)
- [The Open Source AI Stack: Hermes Agent + OpenClaw + AonUI — atalupadhyay](https://atalupadhyay.wordpress.com/2026/05/08/the-open-source-ai-stack-hermes-agent-openclaw-aonui/)
- [Hermes Agent vs OpenClaw: Which AI Agent Framework Wins in 2026 — AIWorkflowHub](https://aiworkflow.openclawhub.tools/blog/hermes-agent-vs-openclaw-which-ai-agent-framework-wins-2026)
- [win4r/ClawTeam-OpenClaw — production fork example with synced upstream fixes](https://github.com/win4r/ClawTeam-OpenClaw)
- [Migrate from OpenClaw — Hermes Agent official docs](https://hermes-agent.nousresearch.com/docs/guides/migrate-from-openclaw)
- [Hemispheric Disparity Theory — Frontiers in Psychology (2026)](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2026.1727527/abstract)
- [Dual-Brain System Architecture — Emergent Mind](https://www.emergentmind.com/topics/dual-brain-system-architecture)
- [A2A Protocol — official](https://a2a-protocol.org/latest/)
- [A2A Protocol Specification](https://a2a-protocol.org/latest/specification/)
- [a2aproject/A2A — GitHub](https://github.com/a2aproject/A2A)
- [What Is Agent2Agent (A2A) Protocol? — IBM](https://www.ibm.com/think/topics/agent2agent-protocol)
- [Google A2A Protocol: How Agent-to-Agent Coordination Works — Atlan](https://atlan.com/know/google-a2a-protocol/)
- [How we built our multi-agent research system — Anthropic Engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Agents Thinking Fast and Slow: A Talker-Reasoner Architecture — arXiv](https://arxiv.org/html/2410.08328v1)
- [Thinking Fast and Slow in Human and Machine Intelligence — Communications of the ACM](https://cacm.acm.org/research/thinking-fast-and-slow-in-human-and-machine-intelligence/)
- [Fast, slow, and metacognitive thinking in AI — npj Artificial Intelligence](https://www.nature.com/articles/s44387-025-00027-5)
- [AaronWong1999/hermesclaw — GitHub (Hermes + OpenClaw co-existence proof)](https://github.com/AaronWong1999/hermesclaw)
- [How to Set Up OpenClaw and Design an A2A Plugin Bridge — freeCodeCamp](https://www.freecodecamp.org/news/openclaw-a2a-plugin-architecture-guide/)
- [Hermes Agent vs OpenClaw: 2026 Ultimate Comparison — CometAPI](https://www.cometapi.com/hermes-vs-openclaw/)
- [Hermes Agent vs OpenClaw — a2a-mcp.org blog](https://a2a-mcp.org/blog/hermes-agent-vs-openclaw)
- [Heterogeneous agents, one fabric — Synadia](https://www.synadia.com/blog/heterogeneous-agents-one-fabric)
- [Why Do Multi-Agent LLM Systems Fail? (MAST taxonomy) — arXiv](https://arxiv.org/html/2503.13657v1)
- [Are Your Multi-Agent Systems Failing for These 7 Reasons? — Galileo](https://galileo.ai/blog/why-multi-agent-systems-fail)
- [Multi-Agent System Reliability — Maxim AI](https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/)
- [Why Multi-Agent LLM Systems Fail — orq.ai](https://orq.ai/blog/why-do-multi-agent-llm-systems-fail)
- [The Multi-Agent Trap — Towards Data Science](https://towardsdatascience.com/the-multi-agent-trap/)
- [Multi-Agent System Architecture Guide for 2026 — Clickittech](https://www.clickittech.com/ai/multi-agent-system-architecture/)
- [Multi-Agent AI Systems: The Complete Enterprise Guide for 2026 — Neomanex](https://neomanex.com/posts/multi-agent-ai-systems-orchestration)
