# Backlog closure sweep — 2026-05-26T23:01Z

## Selected item
John's 2026-05-26 directive to stop leaving shipped work in open/pending backlog states.

## Scope
Reviewed current PWA chat directive, BACKLOG.md, logs/backlog/*.json, HEARTBEAT.md, continuous-work policy, service health, git state, and recent repair/security logs.

## Closures/reconciliations applied
- BACKLOG-001: resolved. A2A2H/PWA umbrella build is delivered and in active use; sub-defects are tracked separately.
- BACKLOG-009: resolved. URL/query-token auth is replaced by signed cookie sessions, API query-token auth is rejected, and dual-token rotation grace is deployed. Future live credential rotation belongs to BACKLOG-006.
- BACKLOG-013: resolved. PWA access-control failure is closed; unauthenticated and query-token API access are rejected, shell access is gated, and rotation grace is deployed. Future credential rotation belongs to BACKLOG-006.
- BACKLOG-014: resolved. Push subscription and provider-submit path are runtime-verified; later browser/device UX defects should be new narrower items.
- BACKLOG-016: resolved already; BACKLOG.md duplicate stale resolved row was removed.
- BACKLOG-017: resolved. Durable chat log/export is shipped, runtime-verified, and in active use.

## Durable rule update
Updated the continuous-work policy plus both hemisphere role files so future work-pump runs must scan open/pending backlog items for completion evidence and close observably done work before selecting new tasks.

## Verification
- `python3 -m json.tool logs/backlog/BACKLOG-001.json logs/backlog/BACKLOG-009.json logs/backlog/BACKLOG-013.json logs/backlog/BACKLOG-014.json logs/backlog/BACKLOG-016.json logs/backlog/BACKLOG-017.json` passed.
- `grep` verified the closed items no longer appear in BACKLOG.md Active Items.
- `grep` verified the closure-scan rule exists in OPENCLAW_ROLE.md, HERMES_ROLE.md, and wiki/continuous-work-policy.md.

## Not closed
- BACKLOG-005 remains pending coordinated public history scrub because actual rewrite/force-push is destructive.
- BACKLOG-006 remains open for staged live credential rotation and broader secret/log/history cleanup.
- BACKLOG-004 remains open for voice mode.
