# OpenClaw work pump — BACKLOG-002 governed self-repair — 2026-05-27T20:00Z

## Required prechecks
- A2A2H upstream-port check: `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits, so no A2A2H port was required.
- Hermes provider circuit: degraded/open (`agent_incomplete_provider_NoneType`), so no semantic work was delegated to Hermes this tick.
- Hetzner inventory check for BACKLOG-008 evidence: only `cto-v1` and unrelated `recrm` are present; no failed clone candidate remains live. BACKLOG-008 already has a guarded watchdog but remains open until the next clone-test flow uses it after an install-parity failure.

## Item picked
BACKLOG-002 — governed OpenClaw self-repair/edit mechanism to replace the temporary direct-edit exception.

## What changed
- Added `scripts/repair/governed-self-repair.py`.
- Added lower-level session helper `scripts/openclaw-governed-repair.py`.
- Added `tests/test_governed_self_repair.py` and `tests/test_openclaw_governed_repair.py`.
- Added `wiki/governed-openclaw-self-repair.md`.
- Updated `AGENTS.md` so future direct OpenClaw install/state edits require a manifest-backed repair record, rollback backups, verification, and closeout.
- Closed BACKLOG-002 in `BACKLOG.md` and `logs/backlog/BACKLOG-002.json`.
- Used the new mechanism for this closeout record: `logs/repairs/self-repair/20260527T195748Z-govern-openclaw-self-repair-mechanism.json`.

## Verification
- `python3 -m pytest -q tests/test_governed_self_repair.py` → 3 passed.
- `python3 -m pytest -q tests/test_openclaw_governed_repair.py` → 4 passed.
- `python3 -m compileall -q scripts/repair/governed-self-repair.py tests/test_governed_self_repair.py` → passed.
- `bash scripts/validate-no-spend.sh` → PASS: no-spend validation complete.

## Result
BACKLOG-002 is resolved with a durable governance artifact. The temporary exception remains documented only as a repair-mode bridge; future direct OpenClaw self-edits must use the governed record workflow.
