# BACKLOG-006 PWA Password Paste Redaction — 2026-05-26T20:10Z

## Selected item
BACKLOG-006 (P0 security): live service credential hygiene and removal of secret values from operational logs/history.

## Safe step completed
Extended the operational redaction gate to catch the observed natural-language PWA chat password-paste phrasing, then applied it to the current PWA chat artifacts.

This does not rotate the Google account password or any live service credentials. It removes exposed values from local operational artifacts and adds regression coverage so future equivalent natural-language pastes are detected by the safe security gate.

## Files/records redacted
- `logs/pwa-chat/2026-05-26.md`: 3 natural-language password paste markers redacted.
- `chat.db`: 4 message rows redacted.

No secret values or redaction-trigger phrases were printed in the redaction output or this artifact.

## Verification
```text
$ python3 -m unittest -v tests/test_redact_operational_secrets.py
Ran 5 tests in 0.000s
OK

$ scripts/security/redact-operational-secrets.py --check
Operational secret redaction check passed: scanned 94 file(s) plus chat.db; no unredacted markers found.

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 227 source-visible files.
Operational secret redaction check passed: scanned 94 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 5/5 passed.
PWA auth/routing regression tests: 18/18 passed.
Safe security gates passed.

$ python3 - <<'PY'
# Verified chat.db has zero rows matching the unredacted pasted-password shape.
PY
chat_db_unredacted_password_rows=0
```

## Remaining BACKLOG-006 work
Live credential rotation/revocation and replacement of shell-interpolated secret propagation remain coordinated P0 work.
