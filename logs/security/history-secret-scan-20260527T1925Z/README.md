# BACKLOG-003 full-history secret scan

[verified] Scope: gitleaks scanned git history with `--all --reflog`; TruffleHog scanned `file://` repository history with additional refs enabled by default.
[verified] Raw TruffleHog JSON was kept in the temporary work directory only because it may include secret/context fields; committed artifacts are sanitized metadata only.
[verified] Gitleaks version: 8.30.1
[verified] TruffleHog version: trufflehog 3.95.3
[verified] Gitleaks findings: 10 ({'generic-api-key': 9, 'private-key': 1})
[verified] TruffleHog sanitized findings: 1 ({'PrivateKey': 1})

## Sanitized gitleaks finding locations
- [verified] .vapid/private.pem: 1
- [verified] logs/install/install-20260511-164935.log: 1
- [verified] logs/install/install-20260511-165153.log: 1
- [verified] logs/install/install-20260511-165334.log: 1
- [verified] logs/install/install-20260511-165414.log: 1
- [verified] logs/install/install-active.log: 1
- [verified] logs/security/BACKLOG-005-history-secret-scan-repair-2026-05-26T2125Z.md: 1
- [verified] logs/security/BACKLOG-005-push-verification-blocked-2026-05-26T2109Z.md: 1
- [verified] logs/security/BACKLOG-005-runtime-push-attempt-2026-05-26T2109Z.md: 1
- [verified] logs/security/BACKLOG-005-runtime-vapid-rotation-2026-05-26T2054Z.md: 1

## Sanitized TruffleHog finding locations
- [verified] PrivateKey in .vapid/private.pem at 25029cc38a6555e0a83e7113794dae1b2c468d05:1 (verified=False)

## Interpretation
- [verified] Both scanners independently identify historical `.vapid/private.pem`; runtime VAPID rotation work already exists under BACKLOG-005, but this confirms the public git history still contains a private key blob unless history is rewritten.
- [verified] The `generic-api-key` hits are historical install/security logs and VAPID verification evidence; they require human review/rotation triage before any claim that BACKLOG-003 is resolved.
- [verified] TruffleHog returned 1 sanitized finding(s) with unverified/unknown/verified results enabled.
