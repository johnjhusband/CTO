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
7. Send daily digest to Telegram [verified — bot token works, proactive messaging needs John to message bot first]
8. Archive findings to knowledge base [verified — raw/ and wiki/ directories exist]
9. Update wiki pages if findings change existing knowledge [unverified — not implemented]

## Health Checks (Every 30 Minutes)
<!-- None of these are implemented yet — they are the target design -->
- LLM API reachable [unverified — check not implemented]
- Telegram bot responsive [unverified — check not implemented]
- Memory/wiki readable [unverified — check not implemented]
- VPS disk space >10% free [unverified — check not implemented]
- RAM <90% used [unverified — check not implemented]

## Weekly
- Review technology radar — any deferred items due for re-evaluation? [unverified — not implemented]
- Review MEMORY.md — anything stale that should be updated or removed? [unverified — not implemented]
- Review scoring calibration — am I filtering too loose or too tight? [unverified — not implemented]
