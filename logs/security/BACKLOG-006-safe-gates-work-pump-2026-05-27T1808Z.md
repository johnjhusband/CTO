# BACKLOG-006 safe credential/access-control gate — OpenClaw work pump

- Timestamp: 2026-05-27T18:08:44Z
- Selected item: BACKLOG-006 — rotate live service credentials and remove secret values from operational logs/history
- Status: non_destructive_verification_passed
- A2A2H upstream-port check: clean; `git log 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits, so no port was required.
- Open/pending backlog completion scan: no P0/P1 item had enough on-disk evidence for safe closure; BACKLOG-004/014/016/017 still require John-visible/device confirmation, BACKLOG-005 still requires coordinated history scrub or risk acceptance, and BACKLOG-006 still requires coordinated live credential rotation/revocation.
- Hermes delegation: skipped because `.cache/hermes-work-pump-provider-failure.json` reports the provider circuit open for repeated `agent_incomplete_provider_NoneType` failures.
- Service health snapshot: OpenClaw gateway, Hermes gateway, Hermes A2A sidecar, PWA backend, and A2A registry were active during the gate.

Verification run:

```bash
cd /opt/cto
scripts/security/run-safe-security-gates.sh
```

Results:

- Secret artifact guard passed across source-visible files.
- Operational secret redaction check passed across logs plus chat.db.
- Install secret-handling guard passed.
- Credential rotation preflight remained names/status-only and ready for a coordinated rotation window.
- Credential rotation smoke check reported local services healthy without printing response bodies or credential values.
- Redaction unit tests passed: 9/9.
- PWA auth/routing regression tests passed: 38/38.
- PWA voice UI regression test passed: 1/1.

No credentials were rotated or revoked, no public history was rewritten, no infrastructure was changed, and no secret values were recorded.
