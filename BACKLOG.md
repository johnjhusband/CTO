# CTO Backlog — Capability Gaps Requiring Human Attention

**Purpose:** Log items the CTO discovered it cannot autonomously resolve — code changes that would require forking OpenClaw or Hermes, missing MCPs, missing skills, and other capability gaps where the community doesn't already have a solution. Read this regularly. New items are surfaced in the daily Telegram digest.

**Discovery loop:** Both hemispheres add entries — Hermes when its self-evolution proposes a change that breaches Phase 1-4 scope, OpenClaw when it needs a skill/MCP and the community catalogue comes up empty, CTO research when a community pattern demands source-level adoption. Each entry must include a documented search trail so John can see CTO tried before escalating. New entries surface in the daily digest (A2A human interface per CTO-DECISION-006).

**Format:** Each row in the active-items table is a one-line summary. Full detail lives in `logs/backlog/BACKLOG-NNN.json` mirroring the decision-log pattern.

---

## Entry Types

| Type | What it means | Default disposition |
|---|---|---|
| `fork-trigger` | OpenClaw or Hermes lacks a capability and adding it requires changes to framework source code | **Needs John's review** — fork decision, upstream PR attempt, or defer |
| `upstream-pr-needed` | A patch that should go upstream first (less urgent than a fork; PR before fork) | CTO drafts the PR; John approves before submission to upstream |
| `missing-mcp` | A needed MCP server doesn't exist in the community | CTO researches alternatives; if none, John decides build vs defer |
| `missing-skill` | A needed skill doesn't exist in OpenClaw's catalogue or Hermes's bundled set | Hermes attempts auto-creation first; if not feasible, logged for John |
| `security` | A discrete security finding from audit, exposure review, credential hygiene, hardening, or recovery posture | Prioritize by risk; remediate through clone-test-replace or explicit approved hardening |

## Statuses

`open` → `under-review` → (`in-progress` | `escalated-to-john`) → (`resolved` | `abandoned`)

## Priority

| Level | Meaning |
|---|---|
| **P0** | Blocking core CTO operations — daily research cycle, upgrade cycle, or reporting cannot run |
| **P1** | Significantly degrades a hemisphere's capability — workarounds exist but cost real time/quality |
| **P2** | Nice to have — improves quality of life or unlocks a future capability |
| **P3** | Research backlog only — interesting pattern noted, not currently needed |

---

## Active Items

| ID | Date | Type | Priority | Affects | Capability Needed | Status |
|---|---|---|---|---|---|---|
| [BACKLOG-001](logs/backlog/BACKLOG-001.json) | 2026-05-11 | missing-skill | P0 | human-interface | Self-hosted PWA at `cto.husband.llc` — A2A2H chat + web-push, no per-clone config | escalated-to-john |
| [BACKLOG-002](logs/backlog/BACKLOG-002.json) | 2026-05-24 | fork-trigger | P2 | left-hemisphere (openclaw) | Governed OpenClaw self-repair/edit mechanism to replace temporary direct-edit exception | open |
| [BACKLOG-003](logs/backlog/BACKLOG-003.json) | 2026-05-25 | security | P1 | whole repo / live deployment | Thorough multi-layer security audit of the public CTO repo and live CTO deployment | open |
| [BACKLOG-004](logs/backlog/BACKLOG-004.json) | 2026-05-25 | upstream-pr-needed | P0 | human-interface (A2A2H) | Voice mode for A2A2H PWA — audible CTO reports and spoken replies from John | open |
| [BACKLOG-005](logs/backlog/BACKLOG-005.json) | 2026-05-25 | security | P0 | core-cto / public repo / PWA push identity | Rotate and scrub VAPID/Web Push private key leaked into repo history | open |
| [BACKLOG-006](logs/backlog/BACKLOG-006.json) | 2026-05-25 | security | P0 | core-cto / credential hygiene | Rotate live service credentials and remove secret values from operational logs/history | open |
| [BACKLOG-007](logs/backlog/BACKLOG-007.json) | 2026-05-25 | security | P1 | infrastructure / network perimeter | Add deny-by-default host/cloud firewall policy for CTO servers and clone candidates | open |
| [BACKLOG-008](logs/backlog/BACKLOG-008.json) | 2026-05-25 | security | P1 | clone-test-replace / attack surface | Quarantine or retire public clone candidates immediately after validation windows | open |
| [BACKLOG-009](logs/backlog/BACKLOG-009.json) | 2026-05-25 | security | P0 | A2A2H PWA / authentication | Replace URL query-token PWA auth with cookie/session auth and reduce token logging risk | implemented_pending_token_rotation |
| [BACKLOG-010](logs/backlog/BACKLOG-010.json) | 2026-05-25 | security | P1 | availability / recovery | Enable backup/snapshot and deletion-protection policy for production CTO state | open |
| [BACKLOG-011](logs/backlog/BACKLOG-011.json) | 2026-05-25 | security | P2 | host hardening / SSH | Complete privileged SSH/fail2ban hardening verification | open |
| [BACKLOG-012](logs/backlog/BACKLOG-012.json) | 2026-05-25 | security | P2 | patch management / dependency hygiene | Patch OpenClaw and add dependency/security scanning gates | open |
| [BACKLOG-013](logs/backlog/BACKLOG-013.json) | 2026-05-25 | security | P0 | A2A2H PWA / authentication and access control | Close PWA chat access-control bug so knowing the chat URL is not sufficient | implemented_pending_token_rotation |
| [BACKLOG-014](logs/backlog/BACKLOG-014.json) | 2026-05-25 | upstream-pr-needed | P0 | A2A2H PWA / notifications and background delivery | Reliable background notifications so John can context-switch without missing replies | implemented_pending_runtime_push_verification |
| [BACKLOG-015](logs/backlog/BACKLOG-015.json) | 2026-05-25 | missing-mcp | P1 | reporting / A2A2H human interface | Outbound email status updates to John at john@husband.llc | adapter_implemented_blocked_on_credentials |
| [BACKLOG-016](logs/backlog/BACKLOG-016.json) | 2026-05-26 | upstream-pr-needed | P0 | A2A2H PWA / inter-hemisphere transparency | Visible OpenClaw/Hermes coordination transcript or audit view in the PWA | open |
| [BACKLOG-017](logs/backlog/BACKLOG-017.json) | 2026-05-26 | feature | P0 | A2A2H PWA / chat history persistence and review | Durable, human-readable chat log export John can review without needing the PWA foregrounded | implemented_pending_mobile_verification |

## Escalated to John (Awaiting Decision)

| ID | Escalated | Type | Capability | What John Needs to Decide |
|---|---|---|---|---|
| BACKLOG-001 | 2026-05-11 | missing-skill | Self-hosted PWA (A2A2H chat + push) | When to build (v1.1 scope per CTO-DECISION-006). DNS: husband.llc lives at Namecheap; John creates `cto.husband.llc` A record when ready. |

## Resolved / Abandoned

| ID | Resolution Date | Type | Capability | Resolution |
|---|---|---|---|---|
| _none yet_ | | | | |

---

## When CTO Adds an Entry

CTO **must** add a backlog entry whenever:

1. **Hermes self-evolution proposes a change to framework source code** beyond Phase 1-4 scope (skills, prompts, tool descriptions, `tools/*.py`) — log as `fork-trigger` (kernel/architecture change) or `upstream-pr-needed` (improvement worth contributing back).
2. **OpenClaw needs a capability and no skill/plugin exists** that delivers it — log as `missing-skill` only after a documented search of ClawHub + GitHub + the wider community returned nothing.
3. **An MCP integration is needed and no public MCP server provides it** — log as `missing-mcp` after a documented search of the MCP registry and community catalogues.
4. **CTO research discovers a community pattern that requires source-level adoption** in either framework — log as `fork-trigger`.

Every entry must include a `search_trail` showing what was searched and where. **No silent escalations.** If CTO didn't search first, it's not a backlog item — it's an unfinished research task.

## When CTO Does NOT Add an Entry

- A skill that Hermes can auto-create via its Curator / GEPA loop — this is normal operation, not a gap.
- A Phase 1-4 change (skills, prompts, tool descriptions, tool code) Hermes can ship as a PR through the standard upgrade cycle — that's the normal patch flow, not a fork trigger.
- A capability that exists in the community but hasn't been installed yet — that's a TODO, not a backlog gap.
- Anything CTO could solve with research it hasn't done. Do the research first.

---

## How John Sees This

Every daily digest (A2A human interface per CTO-DECISION-006; interim file at `/opt/cto/logs/digest/digest-YYYY-MM-DD.md`) includes a one-paragraph backlog summary:

- New entries opened in the last 24h, grouped by type and priority
- Any P0/P1 items still open
- Any items with `status: escalated-to-john` waiting for a decision

John can also read this file directly at any time. The active-items table is the dashboard.

---

## Schema (`logs/backlog/BACKLOG-NNN.json`)

```json
{
  "id": "BACKLOG-001",
  "timestamp": "2026-05-11T22:00:00Z",
  "type": "fork-trigger | upstream-pr-needed | missing-mcp | missing-skill",
  "priority": "P0 | P1 | P2 | P3",
  "status": "open | under-review | in-progress | escalated-to-john | resolved | abandoned",
  "surfaced_by": "hermes | openclaw | cto-research | john",
  "surfaced_from": "task ID, decision ID, research finding ID, or execution trace ID",
  "affects": "left-hemisphere (openclaw) | right-hemisphere (hermes) | both | core-cto",
  "capability_needed": "one-line description of what's missing",
  "details": "longer description: what's needed, why, what triggered the gap, what blocks autonomous resolution",
  "search_trail": [
    "Searched ClawHub category X for Y — N results, none matched",
    "Searched A2A registry for Z — no match",
    "Checked openclaw/openclaw issues — no open feature request matches",
    "Checked NousResearch/hermes-agent issues — no match",
    "Web search '<exact query>' — nothing relevant in top 10 results"
  ],
  "proposed_resolution": "fork | upstream PR | build MCP | build skill | adopt community fork | defer | abandon",
  "blast_radius": "what would change if we did the proposed resolution",
  "rollback_plan": "how to undo if it doesn't work",
  "john_review_date": null,
  "resolution_date": null,
  "resolution_notes": null,
  "related_decision_log": null
}
```

## Relationships

- [SOUL.md](SOUL.md) — principle 11 (never touch what isn't yours), principle 6 (never downgrade design for convenience), principle 4 (follow community, not assumptions) — backlog protects all three.
- [AGENTS.md](AGENTS.md) — operating manual, includes the trigger rules for adding entries.
- [HEARTBEAT.md](HEARTBEAT.md) — daily report includes backlog summary.
- [hemisphere.md](hemisphere.md) — defines what Hermes's Phase 1-4 covers (autonomous) vs what triggers a backlog entry (escalation).
- [hermes.md](hermes.md) — Phase 1-4 scope table; anything outside that scope is a backlog candidate.
- [logs/decisions/INDEX.md](logs/decisions/INDEX.md) — when a backlog item is resolved with a material change, a decision log entry is also created.
