# BACKLOG-012 — OpenClaw upgrade clone gate reconciliation

- Timestamp: 2026-05-27T22:25Z
- Selected item: BACKLOG-012 (clone-test validation and installer repeatability)
- A2A2H per-tick check: `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift; no A2A2H port was required.
- Why this item: P0 credential/history-scrub items remain blocked on coordinated rotation/destructive history rewrite; P0 visible-PWA items remain pending John verification; Hermes semantic delegation is degraded by the provider circuit. The safest actionable item was reconciling uncommitted clone-gate artifacts already present on disk.
- Change reconciled: added `scripts/security/openclaw-upgrade-clone-gate.sh`, a read-only clone-side gate that composes the OpenClaw clone verifier, `validate-no-spend.sh`, and A2A2H drift check into one fail-closed promotion gate for clone-test-replace candidates.
- Tests: `python3 -m pytest tests/test_openclaw_upgrade_clone_gate.py tests/test_openclaw_upgrade_clone_verify.py tests/test_openclaw_upgrade_promotion_check.py -q` passed (11 tests).
- Production impact: no package install, production upgrade, service restart, infrastructure change, cloud spend, or secret output.
- Remaining work: run this gate on a clone-test-replace candidate after installing the target OpenClaw version; production must not be upgraded in place.
