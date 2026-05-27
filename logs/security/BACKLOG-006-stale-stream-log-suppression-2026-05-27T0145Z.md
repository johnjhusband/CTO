# BACKLOG-006 stale stream log suppression — 2026-05-27T01:45Z

## Selected item
P0 credential/log hygiene follow-up. Recent journal output showed stale PWA clients repeatedly hitting the retired stream endpoint with a redacted query-secret marker. The endpoint already rejected query-token auth and returned 204, but the access log flood degraded verification signal and kept credential-shaped request targets in operational logs.

## Action taken
- Suppressed access logging only for the denied legacy stream query-token 204 path.
- Kept non-204 legacy stream logs redacted and visible for debugging.
- Kept API query-token auth rejected; no credential, session, cookie, or subscription behavior changed.
- Ported the same log-suppression behavior to A2A2H.

## Verification
- Targeted regression tests passed for legacy query-token redaction, legacy stream 204 log suppression, and legacy stream 204 response behavior.
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction check, install guard, rotation preflight syntax, 8 redaction tests, 28 PWA routing tests, and 1 PWA voice UI test.
- Restarted `cto-pwa-backend.service`; service is active.
- Runtime probe of the legacy stream query-secret path returned `204 No Content`, `Cache-Control: no-store`, `Clear-Site-Data: "cache"`, and an empty body.
- Journal check after restart showed no access log lines for the probed legacy stream path.

## Commits
- CTO: `bfe5ad51f99dd15019ebb3dbd510b73d0ea49072`
- A2A2H: `7c381e73ded900596a4666c50d53b0fc4929cf7f`

## Status
Advanced BACKLOG-006 safely without rotating, revoking, printing, or mutating any credential values. Full closure still requires the coordinated live rotation/revocation and approved history/log cleanup window.
