# BACKLOG-006 Redaction Gate Env Coverage — 2026-05-26T19:35Z

## Selected item
BACKLOG-006 (P0 security): rotate live service credentials and remove secret values from operational logs/history.

## Safe step completed
Expanded the non-rotating operational secret redaction gate so it covers additional live/runtime credential names used by CTO services and support scripts. This does not rotate credentials, rewrite public git history, or touch live service configuration.

## Code changes
- `scripts/security/redact-operational-secrets.py` now recognizes additional secret-bearing env names: `GITHUB_PERSONAL_ACCESS_TOKEN`, `API_SERVER_KEY`, `HERMES_A2A_TOKEN`, `CTO_EMAIL_SMTP_PASSWORD`, `NAMECHEAP_PASS`, `NAMECHEAP_API_KEY`, and `GOOGLE_ACCOUNT_PASSWORD_PENDING`.
- Added `tests/test_redact_operational_secrets.py` to prove those values redact without leaking values in count/report metadata and that existing placeholders remain safe.

## Local remediation
- Ran the redaction gate with `--apply` after the expanded coverage found two `API_SERVER_KEY` assignment markers in local `chat.db` rows.
- The gate output reported only row ids and marker counts, not secret values.

## Verification
```text
$ scripts/security/redact-operational-secrets.py --apply
REDACTED chat_db_row=475 markers=env:API_SERVER_KEY:1
REDACTED chat_db_row=476 markers=env:API_SERVER_KEY:1
Operational secret redaction redacted 2 marker(s) across 83 file(s) plus chat.db.

$ scripts/security/redact-operational-secrets.py --check
Operational secret redaction check passed: scanned 83 file(s) plus chat.db; no unredacted markers found.

$ python3 -m unittest -v tests/test_redact_operational_secrets.py tests/test_pwa_routing.py
Ran 18 tests in 0.087s
OK

$ scripts/security/check-secret-artifacts.sh
Secret artifact guard passed: scanned 218 source-visible files.
```

## Remaining BACKLOG-006 work
Live credential rotation/revocation, public history scrub coordination, and replacement of shell-echo/shell-interpolated secret propagation in clone/install flows remain open.
