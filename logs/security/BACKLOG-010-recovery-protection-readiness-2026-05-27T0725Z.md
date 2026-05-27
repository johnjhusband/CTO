# BACKLOG-010 recovery/protection readiness audit — 2026-05-27T07:25Z

## Selection
OpenClaw continuous work pump selected BACKLOG-010 after required inspection. Higher-priority P0 items remain blocked or waiting on external confirmation:

- BACKLOG-005: final public history scrub/force-push remains destructive and needs a coordinated John-approved window or explicit risk acceptance.
- BACKLOG-006: live credential rotation/revocation remains blocked on a coordinated rotation window.
- BACKLOG-004/BACKLOG-014/BACKLOG-016: visible PWA features are implemented/runtime-verified but still need John/device evidence for phone voice, notification display, and coordination UI visibility.

Hermes semantic delegation was not used because `.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open after repeated `agent_incomplete` failures.

## Required checks
- Read/inspected: `BACKLOG.md`, `HEARTBEAT.md`, `wiki/continuous-work-policy.md`, `wiki/A2A2H_MAINTENANCE.md`, `wiki/A2A2H_LAST_SYNC.md`, recent PWA chat logs, git status, service health, and recent verification/repair logs.
- A2A2H per-tick check used tracker SHA `2208320fa5761e5e8318133860fc64e840d79d89` over `services/pwa`, `services/hermes_a2a_sidecar`, `services/a2a_delegate`, `scripts/cache-keepalive.sh`, and `services/chat/db.py`.
- Result: no upstream-eligible CTO commits since the tracker SHA; no A2A2H port required this tick.
- Git state before selection: `/opt/cto` and `/opt/a2a2h` clean and tracking origin.
- User services: no failed user units; `cto-a2a-registry`, `cto-pwa-backend`, `cto-hermes-a2a-sidecar`, `hermes-gateway`, and `openclaw-gateway` active.

## Read-only recovery/protection inventory
Hetzner API read-only inventory showed:

| Resource | Current state | BACKLOG-010 implication |
|---|---|---|
| Server `cto-v1` (`130627001`) | running, `backup_window: null`, `protection.delete: false`, `protection.rebuild: false`, no volumes | Production CTO has no platform backup and no delete/rebuild friction. |
| Server `recrm` (`128886775`) | running, `backup_window: null`, `protection.delete: false`, `protection.rebuild: false`, no volumes | Unrelated public server also lacks protection; not changed by this CTO tick. |
| Snapshot images | `0` snapshots returned | No visible Hetzner recovery snapshot exists for CTO. |
| Volumes | `0` volumes returned | No detachable persistent volume protection path exists. |
| CTO primary IPv4/IPv6 (`130472493`, `130472494`) | assigned to `cto-v1`, `auto_delete: true`, `protection.delete: false` | Public IPs would be auto-deleted with the server and are not delete-protected. |

## Safe candidate baseline (not applied)
A BACKLOG-010 implementation should be staged as an explicit John-approved change because backups/snapshots can cost money and retain secrets:

1. Enable delete and rebuild protection on production `cto-v1`.
2. Disable `auto_delete` or enable delete protection for production primary IPs, after confirming expected Hetzner semantics for assigned primary IPs.
3. Choose one recovery strategy:
   - Hetzner backups for continuous platform-managed restore points, accepting recurring cost and secret retention; or
   - manual named snapshot before risky maintenance windows, with a retention/deletion calendar; or
   - filesystem-level encrypted backup to an approved destination if/when a destination exists.
4. Document a restore drill that verifies `/opt/cto`, PWA chat DB/logs, OpenClaw/Hermes config, service units, and Caddy config can be restored without exposing secrets into git.
5. Add a candidate-server exception rule: clone/test servers should be disposable and normally not backup-protected unless a validation window explicitly needs preservation.

## Result
BACKLOG-010 advanced from a generic security finding to a current, read-only recovery/protection inventory plus a concrete approval-ready baseline. No backups, snapshots, protections, IP settings, credentials, or infrastructure were changed this tick, because applying the baseline can spend money and alter recovery/destruction semantics.
