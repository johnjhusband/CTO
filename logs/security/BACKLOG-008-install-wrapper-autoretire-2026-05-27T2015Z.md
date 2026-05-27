# BACKLOG-008 install-wrapper auto-retirement — 2026-05-27T20:15Z

## Scope
Close the remaining operational gap for BACKLOG-008: failed clone candidates should not linger after install/parity failure.

## A2A2H precheck
`git log <last-synced>..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift. No A2A2H port was required before this work.

## What changed
- `scripts/install.sh` now arms a failed-candidate retirement path immediately after Hetzner provisioning.
- On wrapper failure, it writes a preserved candidate summary under `logs/clone/candidates/` with the server id, IP, failure phase, reason, exit status, and wrapper log path.
- It then requests Hetzner deletion for the failed clone candidate; if the delete request fails, the existing `scripts/security/clone-candidate-watchdog.py` can retry from the preserved summary.
- Added `tests/test_install_wrapper_candidate_retirement.py` to pin the summary/deletion contract and ensure retirement is only armed after provisioning and disarmed on success.

## Verification
- `bash -n scripts/install.sh` → passed.
- `python3 -m pytest -q tests/test_clone_candidate_watchdog.py tests/test_install_wrapper_candidate_retirement.py` → 6 passed.
- `bash scripts/validate-no-spend.sh` → PASS: no-spend validation complete.
- Live watchdog dry run still reports prior server `132825157` as `already_absent` and destroys nothing.

## Resolution
BACKLOG-008 is now resolved: the residual candidate is absent, future failed candidates have a guarded watchdog, and the fresh-install wrapper now preserves evidence and requests deletion automatically on candidate failure.
