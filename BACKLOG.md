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
| [BACKLOG-002](logs/backlog/BACKLOG-002.json) | 2026-05-24 | fork-trigger | P2 | left-hemisphere (openclaw) | Governed OpenClaw self-repair/edit mechanism to replace the temporary direct-edit exception | open |
| [BACKLOG-003](logs/backlog/BACKLOG-003.json) | 2026-05-25 | security | P1 | whole repo (and the running deployment whose attack surface is now visible to the public) | Thorough multi-layer security audit of the public CTO repo and the live CTO deployment | open |
| [BACKLOG-004](logs/backlog/BACKLOG-004.json) | 2026-05-25 | upstream-pr-needed | P0 | human-interface (A2A2H) | Voice mode for A2A2H PWA — CTO reports can be heard aloud and John can reply by speaking | open |
| [BACKLOG-005](logs/backlog/BACKLOG-005.json) | 2026-05-25 | security | P0 | core-cto / public repo / PWA push identity | Rotate and scrub VAPID/Web Push private key leaked into repo history | dry_run_verified_pending_coordinated_history_scrub |
| [BACKLOG-006](logs/backlog/BACKLOG-006.json) | 2026-05-25 | security | P0 | core-cto / credential hygiene | Rotate live service credentials and remove secret values from operational logs/history | open |
| [BACKLOG-007](logs/backlog/BACKLOG-007.json) | 2026-05-25 | security | P1 | infrastructure / network perimeter | Add deny-by-default host/cloud firewall policy for CTO servers and clone candidates | open |
| [BACKLOG-008](logs/backlog/BACKLOG-008.json) | 2026-05-25 | security | P1 | clone-test-replace / attack surface | Quarantine or retire public clone candidates immediately after validation windows | open |
| [BACKLOG-010](logs/backlog/BACKLOG-010.json) | 2026-05-25 | security | P1 | availability / recovery | Enable backup/snapshot and deletion-protection policy for production CTO state | open |
| [BACKLOG-011](logs/backlog/BACKLOG-011.json) | 2026-05-25 | security | P2 | host hardening / SSH | Complete privileged SSH/fail2ban hardening verification | open |
| [BACKLOG-012](logs/backlog/BACKLOG-012.json) | 2026-05-25 | security | P2 | patch management / dependency hygiene | Patch OpenClaw and add dependency/security scanning gates | open |
| [BACKLOG-015](logs/backlog/BACKLOG-015.json) | 2026-05-25 | missing-mcp | P1 | reporting / A2A2H human interface | Outbound email status updates to John at john@husband.llc on a regular cadence and major events | adapter_implemented_blocked_on_credentials |
| [BACKLOG-014](logs/backlog/BACKLOG-014.json) | 2026-05-25 | upstream-pr-needed | P0 | A2A2H PWA / notifications and background delivery | Make PWA deliver CTO replies while backgrounded so John can context-switch without missing messages | open |

## Escalated to John (Awaiting Decision)

None.

## Resolved / Abandoned

| ID | Resolution Date | Type | Capability | Resolution |
|---|---|---|---|---|
| BACKLOG-001 | 2026-05-26 | missing-skill | Self-hosted PWA at cto.husband.llc — chat with OpenClaw/Hermes from phone, web-push notifications, A2A wire format | Resolved 2026-05-26: the A2A2H/PWA umbrella build is delivered and in active use. Evidence: John is using the PWA daily; durable chat log exists at logs/pwa-chat/; push enrollme... |
| BACKLOG-009 | 2026-05-26 | security | Replace URL query-token PWA auth with cookie/session auth and reduce token logging risk | Resolved 2026-05-26: URL/query-token auth was replaced with signed HttpOnly/SameSite cookie sessions; API query-token auth is rejected; unauthenticated shell/API access returns... |
| BACKLOG-013 | 2026-05-26 | security | Close PWA chat access-control bug so knowing the chat URL is not sufficient to read or use CTO chat | Resolved 2026-05-26: the PWA access-control failure is closed. The chat shell and APIs require authenticated cookie sessions, unauthenticated and query-token API access are reje... |
| BACKLOG-017 | 2026-05-27 | feature | Durable, human-readable chat log export John can review at any time without needing the PWA in the foreground | Resolved 2026-05-27: durable markdown chat logs, authenticated /chat-log/ and /api/chat/export, visible Chat history/Review full logs links, and foreground full-history resync are implemented and verified. Evidence: logs/pwa-chat/, logs/repairs/BACKLOG-017-runtime-chat-log-verification-2026-05-26T2040Z.md, services/pwa/frontend/index.html, services/pwa/frontend/app.js, service-worker cto-shell-v12. |
| BACKLOG-016 | 2026-05-27 | upstream-pr-needed | Visible inter-hemisphere coordination transcript or audit view in the PWA | Resolved 2026-05-27: sanitized A2A request/response audit rows, authenticated /api/messages exposure, Show agent coordination toggle, a2a_* frontend rendering, default-hidden coordination rows, and runtime verification are complete. Evidence: logs/repairs/BACKLOG-016-runtime-visible-a2a-ui-verification-2026-05-27T0218Z.md, services/pwa/frontend/index.html, services/pwa/frontend/app.js, services/pwa/frontend/style.css, services/pwa/backend/server.py. |
| BACKLOG-018 | 2026-05-27 | missing-mcp | Per-tick automated check and porting of CTO chat-bridge improvements to A2A2H, plus one-time backfill | Resolved 2026-05-27: maintenance protocol, role docs, per-tick policy, one-time backfill, pushed A2A2H origin, last-sync tracker, and no-drift check are complete. Evidence: wiki/A2A2H_MAINTENANCE.md, wiki/A2A2H_LAST_SYNC.md, logs/repairs/a2a2h-backfill-2026-05-26.md, A2A2H origin/master a72c2cdc. |

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
