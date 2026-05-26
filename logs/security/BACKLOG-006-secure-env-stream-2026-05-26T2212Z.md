# BACKLOG-006 — clone installer secret propagation hardening

Timestamp: 2026-05-26T22:12Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
BACKLOG-006 is the highest-priority open security item. Full live credential rotation is unsafe inside an unattended pump tick because it can interrupt provisioning, embeddings, PWA auth, Hermes A2A, and GitHub/Hcloud automation. The safe substep was to reduce future clone/install leakage risk without touching live credentials.

## Repair
- Updated `scripts/install.sh` Section 7 so candidate `.env` content is streamed to the new VPS by a Python subprocess reading environment variables, instead of a shell block that directly echoed secret-bearing assignments.
- Kept candidate defaults isolated: `CTO_TEST_MODE=1`, candidate chat DB path, and candidate OpenClaw/Hermes session IDs are still emitted for fresh clone-test-replace hosts.
- Remote write now uses `umask 077` before writing `/opt/cto/.env`, preserving restrictive file creation even before the explicit chmod.
- While verifying, the operational redaction gate found an older security artifact containing legacy query-token examples; those values were redacted/rephrased so the guard passes again.

## Verification
```text
bash -n scripts/install.sh => passed
scripts/security/run-safe-security-gates.sh => passed
  Secret artifact guard passed: scanned 251 source-visible files.
  Operational secret redaction check passed: scanned 119 file(s) plus chat.db; no unredacted markers found.
  Redaction unit tests: 6/6 passed.
  PWA auth/routing regression tests: 26/26 passed.
```

## Remaining blockers
- Full BACKLOG-006 credential rotation is still blocked on a staged rotation window and safe delivery/update path for every dependent service.
- Public git history scrub/rotation work remains separate and approval-sensitive because it can disrupt credentials and repository history.
