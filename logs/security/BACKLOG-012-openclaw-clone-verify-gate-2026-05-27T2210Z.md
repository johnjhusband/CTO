# BACKLOG-012 — OpenClaw upgrade clone-verify gate

- Timestamp: 2026-05-27T22:10Z
- Selected item: BACKLOG-012 (patch management / dependency hygiene)
- Why this item: P0 BACKLOG-005/006 remain blocked on coordinated John-approved destructive history scrub / live credential rotation, and P1 BACKLOG-007/010 remain blocked on approval because firewall/protection changes can lock out access or affect cost/retention. Hermes semantic delegation is degraded (`agent_incomplete_provider_NoneType`), so OpenClaw advanced the highest safe unblocked item directly.
- A2A2H per-tick check: `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no upstream-eligible drift; no A2A2H port was required.
- Change shipped: added `scripts/security/openclaw-upgrade-clone-verify.py`, a no-spend clone-side verifier for the isolated OpenClaw npm upgrade candidate. It checks installed OpenClaw version, `openclaw help`, candidate summary target version, and emits sanitized JSON with explicit no-production-mutation/no-spend/no-secret flags.
- Tests: `python3 -m pytest tests/test_openclaw_upgrade_clone_verify.py tests/test_openclaw_upgrade_promotion_check.py -q` passed (8 tests).
- Live production dry run: `scripts/security/openclaw-upgrade-clone-verify.py` correctly returned `status=blocked` because production remains OpenClaw `2026.5.7` while the isolated candidate target is `2026.5.26`; this is expected and proves the verifier will distinguish an unpromoted production host from a validated clone.
- Production impact: no package install, production upgrade, service restart, infrastructure change, cloud spend, or secret output.
- Next step: run this verifier on the clone-test-replace candidate after installing the target OpenClaw version, then require install parity, service health, A2A2H drift, safe security gates, and PWA chat-first layout gates before any promotion.
