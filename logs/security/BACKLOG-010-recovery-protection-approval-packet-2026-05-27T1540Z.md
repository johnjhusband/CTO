# BACKLOG-010 recovery/protection approval packet — 2026-05-27T15:40Z

## Required pre-selection checks
- Read current backlog/heartbeat/continuous-work/A2A2H maintenance docs and recent PWA chat/recovery logs.
- A2A2H per-tick upstream-port check: `git log 353253a7366345676d06c775bdcd5c7f9d61daf7..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible commits, so no A2A2H port was required.
- Git status was clean before this artifact.
- Hermes semantic delegation was skipped because `.cache/hermes-work-pump-provider-failure.json` still records the provider circuit/degraded state (`agent_incomplete_provider_NoneType`).
- User services checked active: `cto-pwa-backend`, `cto-hermes-a2a-sidecar`, `openclaw-gateway`, `hermes-gateway`, and `cto-a2a-registry`.

## Why BACKLOG-010 was selected
Higher-priority safe queue items were blocked or pending external confirmation:
- BACKLOG-005 needs a coordinated/destructive public history scrub window or risk acceptance.
- BACKLOG-006 needs coordinated live credential rotation/revocation; recurring non-destructive gates already passed recently.
- BACKLOG-004/014/016/017 are implemented/runtime-evidenced but intentionally remain pending John phone/device confirmation after the PWA testing correction.

BACKLOG-010 is the next safe security item that can be advanced without spending money or mutating infrastructure.

## Current read-only recovery inventory
Fresh Hetzner read-only inventory at this tick:

| Resource | Observed state | Risk |
|---|---|---|
| `cto-v1` server `130627001` | running; `backup_window: null`; delete protection `false`; rebuild protection `false`; no attached volumes | Production CTO can be deleted/rebuilt without platform friction and has no Hetzner-managed backup. |
| CTO primary IPv4 `130472493` | assigned to `cto-v1`; `auto_delete: true`; delete protection `false` | Public IPv4 can be auto-deleted with the server. |
| CTO primary IPv6 `130472494` | assigned to `cto-v1`; `auto_delete: true`; delete protection `false` | Public IPv6 can be auto-deleted with the server. |
| Snapshot images | none returned | No visible Hetzner snapshot restore point exists. |
| Volumes | none returned | No detachable persistent-volume recovery path exists. |
| `recrm` server `128886775` | unrelated running server; also no backup/protection | Not changed by this CTO item; noted only to avoid accidental scope creep. |

## Approval-ready staged plan (not applied)
No action below was executed in this tick.

### Stage 1 — no recurring spend, low blast radius
1. Enable delete and rebuild protection on production `cto-v1` (`hetzner_change_server_protection id=130627001 delete=true rebuild=true`).
2. Disable auto-delete and/or enable delete protection on CTO primary IPs `130472493` and `130472494` after confirming desired Hetzner semantics for assigned primary IP lifecycle.
3. Verify with read-only server/IP inventory.

### Stage 2 — recovery point policy, requires cost/retention approval
Choose exactly one:
- Hetzner backups: easiest platform-managed recovery, but recurring cost and secret-retaining snapshots.
- Manual named snapshots before risky maintenance: lower frequency, still cost/retention implications.
- Encrypted filesystem backup to an approved destination: best secret-control posture, but needs destination/tooling approval.

### Stage 3 — restore drill
Document and test a restore checklist covering `/opt/cto`, PWA chat DB/log mirrors, OpenClaw/Hermes configs, user services, Caddy config, and A2A2H sync state without writing secrets into git.

## Stop boundary
Do not enable backups, create snapshots, change protections, change primary IP lifecycle, or alter infrastructure until John approves the recovery/protection stage and acceptable cost/retention semantics.

## Result
Produced a current approval packet for BACKLOG-010. No money-spending action, destructive action, infrastructure mutation, credentials, or raw tool traces were performed or recorded.
