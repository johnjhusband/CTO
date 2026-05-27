# BACKLOG-012 — OpenClaw upgrade promotion gate

- Timestamp: 2026-05-27T21:10Z
- Selected item: BACKLOG-012 — patch OpenClaw and add dependency/security scanning gates
- A2A2H per-tick check: clean; no upstream-eligible CTO commits since `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`.
- Hermes delegation: skipped because `/opt/cto/.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open for repeated `agent_incomplete` / `NoneType` failures.
- Change shipped: added `scripts/security/openclaw-upgrade-promotion-check.py`, a no-spend promotion-readiness gate for the isolated OpenClaw npm candidate summary, and wired it into `scripts/validate-no-spend.sh`.
- Safety posture: does not upgrade production, restart services, provision infrastructure, mutate global npm state, or print secret values.
- Result: candidate `openclaw@2026.5.26` is `ready_for_clone_test_replace`; production remains `2026.5.7` until a clone-test-replace promotion window.

## Verification

- `scripts/security/openclaw-upgrade-candidate.sh` passed for `openclaw@2026.5.26` with lifecycle scripts disabled and production/global mutation false.
- `python3 -m py_compile scripts/security/openclaw-upgrade-promotion-check.py` passed.
- `python3 -m pytest -q tests/test_openclaw_upgrade_promotion_check.py` passed: 4/4.
- `scripts/security/openclaw-upgrade-promotion-check.py` emitted `status=ready_for_clone_test_replace`, `production_version=2026.5.7`, `target_version=2026.5.26`, no failures, no warnings.
- `bash scripts/validate-no-spend.sh` passed end-to-end.

## Next safe step

Run clone-test-replace on a candidate host and promote only after install parity, service health, A2A2H drift, safe security gates, and PWA chat-first visible layout gates pass. Do not upgrade production in place.
