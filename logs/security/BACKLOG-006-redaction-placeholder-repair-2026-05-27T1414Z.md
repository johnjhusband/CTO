# BACKLOG-006 redaction placeholder repair — 2026-05-27T14:14:20Z

## Scope
The recurring safe gate caught two chat.db A2A audit rows containing the documented placeholder `PWA_AUTH_TOKEN=<from /opt/cto/.env>`. This is not a secret value, but the redaction checker treated the first whitespace-delimited token `<from` as an unredacted env assignment.

## Repair
- Updated `scripts/security/redact-operational-secrets.py` to parse angle-bracket placeholders containing spaces as a single safe placeholder value.
- Added a regression test for `PWA_AUTH_TOKEN=<from /opt/cto/.env>` command guidance.
- Did not change credentials, services, frontend runtime files, or infrastructure.

## Verification
```text
== secret artifact guard ==
Secret artifact guard passed: scanned 446 source-visible files.

== operational secret redaction check ==
Operational secret redaction check passed: scanned 299 file(s) plus chat.db; no unredacted markers found.

== install secret-handling guard ==
Install secret-handling guard passed: checked scripts/install.sh metadata only.

== credential rotation preflight syntax ==

== credential rotation smoke syntax ==

== credential rotation preflight (names only) ==
Credential rotation preflight (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Required credential names:
- HETZNER_API_TOKEN: present_nonempty
- GITHUB_TOKEN: present_nonempty
- HERMES_API_SERVER_KEY: present_nonempty
- HERMES_A2A_TOKEN: present_nonempty
- OPENAI_API_KEY: present_nonempty
- PWA_AUTH_TOKEN: present_nonempty

Optional/retired credential names to reconcile during rotation window:
- CTO_EMAIL_SMTP_PASSWORD: present_nonempty
- GOOGLE_ACCOUNT_PASSWORD_PENDING: present_nonempty
- OPENROUTER_API_KEY: present_nonempty

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Recommended coordinated order (names only):
1. Prepare replacement values out of band for all present required names.
2. Update /opt/cto/.env atomically with mode 600 and no shell history echo.
3. Restart dependent user services in a controlled window.
4. Verify PWA auth, Hermes A2A, OpenClaw gateway, embeddings, GitHub, and Hetzner paths.
5. Revoke superseded provider credentials only after verification.
6. Run scripts/security/run-safe-security-gates.sh and record evidence.

Preflight result: ready_for_coordinated_rotation_window

== credential rotation smoke check (no values) ==
Credential rotation smoke check (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Local health endpoints:
- openclaw-gateway: ok (27 bytes)
- hermes-gateway: ok (44 bytes)
- hermes-a2a-sidecar: ok (49 bytes)
- pwa-backend: ok (42 bytes)

Smoke result: local_services_healthy

== redaction unit tests ==

== PWA auth/routing regression tests ==

== PWA voice UI regression tests ==

Safe security gates passed.
```

## Conclusion
Safe credential/access-control gates are green again. BACKLOG-006 remains open pending coordinated live credential rotation/revocation and approved broader cleanup.
