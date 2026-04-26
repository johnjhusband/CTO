# Decision Log Format
**L0:** Every upgrade decision logged as structured JSON (adopted/rejected/deferred) with rationale, test results, and rollback info.
**L1:** Persistent, searchable decision log. Each entry: technology evaluated, source, category, action (adopt/reject/defer), rationale, test results (pass/fail/iterations), rollback instructions (snapshot ID, git tag). Stored as JSON in logs/decisions/. Index in INDEX.md. All decisions reported to John via Telegram. Decisions made autonomously — John reviews after the fact.
**Last updated:** 2026-04-26
**Verification:** Design document — JSON schema is our design. No external factual claims.
**Source:** PRD.md, user requirements

## Key Facts
- Every upgrade decision must be logged — adopted OR rejected
- Log is persistent, searchable, and versioned in git
- User receives every decision via communication channel
- Log serves as audit trail of CTO's judgment over time

## Log Entry Format

```json
{
  "id": "CTO-DECISION-001",
  "timestamp": "2026-04-26T10:00:00Z",
  "version_before": "0.1.0",
  "version_after": "0.2.0",
  "technology": "Name of technology evaluated",
  "source": "Where CTO learned about it (URL, video, changelog)",
  "category": "framework|tool|llm|mcp|skill|process|library|infrastructure",
  "action": "adopted|rejected|deferred",
  "summary": "One-line summary of what was evaluated",
  "rationale": "Why CTO decided to adopt/reject/defer",
  "test_results": {
    "passed": true,
    "total_tests": 15,
    "failed_tests": 0,
    "iterations": 1,
    "notes": "Any relevant test details"
  },
  "rollback": {
    "archived_version": "v0.1.0",
    "docker_image": "cto:v0.1.0",
    "git_tag": "v0.1.0-archived-20260426",
    "instructions": "docker stop cto-primary && docker run cto:v0.1.0"
  },
  "reported_to_user": true,
  "report_channel": "whatsapp"
}
```

## Storage
- Decision log lives at: `CTO/logs/decisions/`
- One JSON file per decision: `CTO-DECISION-{NNN}.json`
- Index file: `CTO/logs/decisions/INDEX.md` — searchable summary table

## Relationships
- [Upgrade Cycle](upgrade-cycle.md) — decisions are the output of the cycle
- [Architecture](architecture.md) — decision log is a core component

## Open Questions
- Should decisions be queryable via an API endpoint?
- Retention policy — keep all decisions forever or prune after N months?
