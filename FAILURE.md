# FAILURE.md — CTO Failure Handling Protocol
<!-- This document defines our design — thresholds, timeouts, priorities are design decisions, not claims about external systems. Health checks and circuit breakers are NOT yet implemented [unverified — task #23]. -->

## Failure Modes

### Mode 1: Degraded (Yellow)
**Trigger:** Non-critical component fails (e.g., one research source unavailable, A2A human interface delivery delayed)
**Response:** Continue operating with reduced capability. Log the degradation. Include in next daily report.
**Escalation:** If degraded for >24 hours, escalate to Mode 2.

### Mode 2: Impaired (Orange)
**Trigger:** Core capability fails (e.g., LLM API unreachable, memory corruption detected, test suite broken)
**Response:** Pause non-essential operations. Attempt self-repair (retry, fallback provider, restore from backup). Report to John immediately via all available channels.
**Escalation:** If self-repair fails after 3 attempts, escalate to Mode 3.

### Mode 3: Critical (Red)
**Trigger:** Multiple core systems fail, or a single catastrophic failure (e.g., production VPS unreachable, security breach detected, runaway cost detected)
**Response:** Stop all autonomous operations. Report to John immediately. Do not attempt self-repair on infrastructure — wait for human guidance.
**Escalation:** If John is unreachable for >4 hours, escalate to Mode 4.

### Mode 4: Shutdown (Black)
**Trigger:** Unrecoverable state, or operator commands shutdown, or safety constraint violated
**Response:** Stop all operations. Write final state to persistent storage. Send shutdown notification on all channels. Do not restart without human approval.

## Health Checks

| Check | Frequency | Action on Failure |
|-------|-----------|-------------------|
| LLM API reachable | Every 30 minutes | Switch to fallback provider |
| Memory/wiki readable | Every hour | Alert, do not write until resolved |
| A2A registry responsive | Every hour | Restart registry; write digest to local log if persistent |
| Both hemisphere gateways alive | Every 30 minutes | Restart failed daemon; alert if persistent |
| VPS disk space >10% free | Every 6 hours | Alert, clean logs/archives |
| VPS RAM <90% used | Every 30 minutes | Alert, restart if >95% |
| Daily research cycle completed | Daily at 08:00 UTC | Alert if 06:00 cycle didn't finish |
| No orphaned test VPS running | Every 6 hours | Destroy if running >4 hours |

## Circuit Breakers

| Operation | Max Retries | Backoff | Fallback |
|-----------|-------------|---------|----------|
| LLM API call | 3 | Exponential (1s, 4s, 16s) | Switch provider |
| Web scraping | 2 | 5s fixed | Skip source, note in report |
| A2A human interface publish | 3 | 2s fixed | Local digest file only (no third-party fallback per CTO-DECISION-006) |
| Hetzner API | 3 | Exponential | Alert, pause upgrade cycle |
| YouTube access | 2 | 10s fixed | Skip, note in report |

## Budget Caps

| Cap | Limit | Action |
|-----|-------|--------|
| Daily LLM API spend | TBD (John sets) | Pause non-essential, report |
| Max steps per agent run | 100 | Force stop, report |
| Max tokens per single LLM call | 100K | Truncate context, warn |
| Test VPS max lifetime | 4 hours | Auto-destroy, report |
| Max upgrade attempts per day | 3 | Pause upgrade cycle until tomorrow |

## Recovery Priorities

If multiple things fail simultaneously, recover in this order:
1. **Communication** — ensure John can be reached
2. **Memory** — ensure wiki/knowledge is not corrupted
3. **Research** — resume monitoring the landscape
4. **Upgrade cycle** — resume testing and self-improvement

Communication first because if John can't be reached, nothing else matters.
Memory second because it's the moat — everything else is rebuildable.
