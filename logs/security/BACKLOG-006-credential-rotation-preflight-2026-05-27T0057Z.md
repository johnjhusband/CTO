# BACKLOG-006 credential rotation preflight

- Timestamp: 2026-05-27T00:57Z
- Selected item: BACKLOG-006 P0 credential hygiene.
- Status: advanced_not_closed.
- Work completed: added `scripts/security/rotation-preflight.sh`, a non-destructive preflight for the eventual coordinated live credential rotation window.
- What it checks: required credential names are present in `/opt/cto/.env`, optional/retired credential names that need reconciliation are identified by name only, `.env` owner/mode is reported, and dependent user service activity is listed.
- Safety: the script prints names/status/order only; it does not print values, rotate credentials, rewrite history, restart services, contact providers, or mutate runtime state.
- Current preflight result: required names present; `.env` mode is 600; dependent services active; optional/retired names are present and should be reconciled during the coordinated window.
- Verification: `bash -n scripts/security/rotation-preflight.sh` passed; live preflight output was checked against current `.env` values and printed no values; `scripts/security/redact-operational-secrets.py --check` passed.
- Remaining blocker: full BACKLOG-006 closure still requires coordinated live credential replacement/revocation and any broader history/log cleanup John approves.
