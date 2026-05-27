# BACKLOG-012 — OpenClaw clone-side upgrade gate

- Timestamp: 2026-05-27T22:25Z
- Required A2A2H check: no upstream-eligible CTO commits since `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no port required.
- Backlog completion scan: no open/pending item had sufficient on-disk evidence for closure. BACKLOG-012 remains open until an approved clone-test-replace candidate passes the gate.
- Hermes state: provider circuit degraded/open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Selected item: BACKLOG-012 (patch OpenClaw + dependency/security gates), because the dependency gate and isolated candidate checks existed but the clone host still lacked one single promotion gate tying clone verification, no-spend validation, and A2A2H drift together.
- Work shipped: added `scripts/security/openclaw-upgrade-clone-gate.sh`, a read-only clone-side gate for OpenClaw upgrade candidates. It fails closed unless installed OpenClaw matches the candidate target, `openclaw help` passes, `scripts/validate-no-spend.sh` passes, and A2A2H has no upstream-eligible drift.
- Regression coverage: added `tests/test_openclaw_upgrade_clone_gate.py`.
- Verification: `python3 -m pytest -q tests/test_openclaw_upgrade_clone_gate.py tests/test_openclaw_upgrade_clone_verify.py tests/test_openclaw_upgrade_promotion_check.py` passed (`11 passed`).
- Live dry run: `scripts/security/openclaw-upgrade-clone-gate.sh --output logs/security/BACKLOG-012-openclaw-clone-gate-2026-05-27T2225Z.json` failed closed as expected on production because installed OpenClaw is `2026.5.7` and the isolated candidate target is `2026.5.26`; the embedded `validate-no-spend.sh` run passed.
- Safety: no production upgrade, service restart, npm install, cloud provisioning, spend, infrastructure destruction, or secret output. The JSON summary explicitly records `production_mutated_by_this_check=false`, `spend_or_infrastructure_change=false`, and `secret_values_printed=false`.
