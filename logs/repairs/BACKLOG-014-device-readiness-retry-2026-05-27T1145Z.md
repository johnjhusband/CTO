# BACKLOG-014 device readiness retry — 2026-05-27T11:45Z

## Required pre-checks
- A2A2H upstream-port check ran first from : no upstream-eligible CTO commits existed since the previous tracker SHA, so no pre-existing port was required before selecting work.
- Recent PWA chat inspected: latest John-facing message still reported PWA features implemented and pending phone-side confirmation.
- Backlog completion scan found no safe closure from disk evidence: BACKLOG-004/BACKLOG-014 still need John/device behavior evidence; BACKLOG-005/BACKLOG-006 remain coordinated-window blocked; BACKLOG-015 remains credential-blocked.
- Hermes provider circuit is open (), so no semantic Hermes delegation was attempted.

## Selected item
BACKLOG-014 — make PWA background delivery observable/reliable enough for John to confirm phone behavior.

## Change
- Changed  so the once-per-day local marker is written only after at least one device-status POST succeeds.
- This prevents a transient offline/auth/server failure from suppressing push/voice readiness retries for the rest of the day.
- Bumped CTO shell cache to  and visible app marker to .
- Ported the genericized change to A2A2H as .

## Verification
- CTO:  passed (42/42).
- CTO:  passed.
- CTO: backend Python AST parse passed.
- CTO: == secret artifact guard ==
Secret artifact guard passed: scanned 406 source-visible files.

== operational secret redaction check ==
Operational secret redaction check passed: scanned 261 file(s) plus chat.db; no unredacted markers found.

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

Safe security gates passed. passed end-to-end.
- A2A2H: backend Python AST parse passed.
- A2A2H:  passed.
- A2A2H: no tests directory present.
- A2A2H:  returned no hits.

## Port / commits
- CTO upstream-eligible commit: 
- A2A2H port commit: 

## Result
The PWA now retries daily phone readiness reporting until the report actually reaches the server. BACKLOG-014 remains open because final closure still requires John/device evidence that a background notification is displayed on the phone.
