# BACKLOG-008 clone candidate retirement watchdog — 2026-05-27T19:35Z

## Scope
Advance BACKLOG-008 after John specifically called out residual candidate `132825157` and asked for a watchdog that retires failed install-parity candidates.

## A2A2H precheck
`git log $(sed -n 's/^\*\*Last synced CTO SHA:\*\* //p' wiki/A2A2H_LAST_SYNC.md)..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift, so no A2A2H port was required before this work.

## What changed
- Added `scripts/security/clone-candidate-watchdog.py`.
- Added `tests/test_clone_candidate_watchdog.py`.
- Wired the watchdog regression into `scripts/validate-no-spend.sh`.

The watchdog defaults to dry-run and only allows destructive deletion with `--destroy` for servers with the exact safe label set `purpose=cto`, `role=clone-candidate`, `test_mode=true`. Production `cto-v1` lacks those labels and is blocked even if a stale/bad summary references it.

## Current inventory result
The prior failed parity candidate `132825157` is no longer present in Hetzner inventory. The local preserved summary still records it as `failed_destroying`, so the watchdog reports it as already absent and destroys nothing.

```json
{
  "actions": [
    {
      "action": "already_absent",
      "name": "cto-candidate-202605250519",
      "reason": "failed parity summary exists but server is not present in Hetzner inventory",
      "server_id": 132825157,
      "summary": "logs/clone/candidates/cto-v2-132825157-summary.json"
    }
  ],
  "destroyed_server_ids": [],
  "mode": "dry_run",
  "safe_label_selector": {
    "purpose": "cto",
    "role": "clone-candidate",
    "test_mode": "true"
  }
}
```

## Verification
- `python3 -m pytest -q tests/test_clone_candidate_watchdog.py` → 4 passed.
- `python3 -m compileall -q scripts/security/clone-candidate-watchdog.py tests/test_clone_candidate_watchdog.py` → passed.
- `bash scripts/validate-no-spend.sh` → PASS: no-spend validation complete.
- Live dry run with Hetzner token sourced from `/opt/cto/.env` printed no secret values and returned `already_absent` for server `132825157`.

## Remaining BACKLOG-008 status
Open. The residual failed candidate is gone, and future failed candidates now have a guarded retirement script. Full closure still needs the next clone-test run to use the watchdog in the operational flow after install-parity failure.
