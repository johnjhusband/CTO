# CTO Heartbeat — Recurring Tasks
<!-- OpenClaw reads HEARTBEAT.md every 30 minutes [verified against docs]. Extends to 1 hour for Anthropic OAuth auth modes [verified]. -->

## Daily Research Cycle (06:00 UTC)
Run the full research methodology:
1. Scan all sources (GitHub Trending, HN, arXiv, YouTube AI channels, product changelogs, HuggingFace, Reddit r/MachineLearning) [unverified — sources defined by design, not tested at scale]
2. Score each finding 0-10 against my interests [unverified — scoring not implemented]
3. Deduplicate cross-platform [unverified — not implemented]
4. For items scoring 7+: enrich with summary, comparison to current stack, material assessment [unverified — not implemented]
5. Make autonomous decisions (adopt/reject/defer) per decision-evaluate skill [verified — skill exists]
6. Log all decisions to logs/decisions/ [verified — template and directory exist]
7. **Check the backlog — any capability gaps surfaced today (new BACKLOG-NNN entries)?** [design — see BACKLOG.md]
8. Write the daily digest to `/opt/cto/logs/digest/digest-YYYY-MM-DD.md` AND publish via the A2A human interface [adopted CTO-DECISION-006; A2A human interface implementation pending v1.1]
9. Archive findings to knowledge base [verified — raw/ and wiki/ directories exist]
10. Update wiki pages if findings change existing knowledge [unverified — not implemented]

### Required Daily Digest Sections (A2A human interface; interim file at /opt/cto/logs/digest/)
1. **Headline:** what materially changed today (1-3 lines, or "nothing material today")
2. **Research:** notable findings scoring 7+, decisions made
3. **Backlog:** new entries opened in the last 24h (by type + priority), any P0/P1 still open, anything `escalated-to-john` (see BACKLOG.md)
4. **Operations:** health-check status, any failures, any upgrades in progress
5. **Asks of John:** anything blocked on John's review or approval — money, fork decisions, escalated backlog items

## Health Checks (Every 30 Minutes)
<!-- None of these are implemented yet — they are the target design -->
- LLM API reachable [unverified — check not implemented]
- A2A registry responsive [unverified — check not implemented]
- Both hemisphere gateways (openclaw 18789, hermes 8642) alive [unverified — check not implemented]
- Memory/wiki readable [unverified — check not implemented]
- VPS disk space >10% free [unverified — check not implemented]
- RAM <90% used [unverified — check not implemented]

## Weekly
- Review technology radar — any deferred items due for re-evaluation? [unverified — not implemented]
- Review MEMORY.md — anything stale that should be updated or removed? [unverified — not implemented]
- Review scoring calibration — am I filtering too loose or too tight? [unverified — not implemented]

## Hermes Work Pump (Every 15 Minutes)
- Inspect recent John messages in PWA chat, `/opt/cto/BACKLOG.md`, `/opt/cto/HEARTBEAT.md`, git status, service health, and recent failed verification.
- Select one safe highest-priority item using the continuous-work policy.
- Produce a durable artifact, verification result, repair, commit, or explicit blocked note.
- Do not store secrets, raw tool traces, or transient noise in shared memory.
- Do not spend money, destroy infrastructure/data, create external risk, or override OpenClaw strategy without the required approval.
