# BACKLOG-006 safe credential/access-control gate — 2026-05-27T11:05Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first using `wiki/A2A2H_LAST_SYNC.md`: no upstream-eligible CTO commits existed after `27abb1203d2a13253e8c1b7e9658518d77794236`, so no A2A2H port was required.
- Hermes provider circuit is open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted this tick.
- Open/pending backlog scan found no safe closure from disk evidence: BACKLOG-004 and BACKLOG-014 still need phone/device behavior evidence; BACKLOG-005 and BACKLOG-006 still require coordinated credential/history windows; BACKLOG-015 remains credential-blocked.

## Selected item
BACKLOG-006 — P0 credential hygiene. This tick used the safe, non-destructive verification path only: no credential values were read, printed, rotated, revoked, or rewritten in history.

## Verification result
`./scripts/security/run-safe-security-gates.sh` passed end-to-end:
- Secret artifact guard passed across 402 source-visible files.
- Operational redaction scan passed across 257 files plus `chat.db`; no unredacted markers found.
- Install secret-handling guard passed.
- Credential rotation preflight reported required credential names present/non-empty and dependent services active, without printing values.
- Rotation smoke reported local OpenClaw, Hermes, Hermes A2A sidecar, and PWA health endpoints healthy.
- Redaction unit tests passed 8/8.
- PWA auth/routing regression tests passed 33/33.
- PWA voice UI regression test passed 1/1.

## Result
The safe credential/access-control gate remains green. BACKLOG-006 stays open because final remediation still requires a coordinated live credential rotation/revocation window and approved broader cleanup.
