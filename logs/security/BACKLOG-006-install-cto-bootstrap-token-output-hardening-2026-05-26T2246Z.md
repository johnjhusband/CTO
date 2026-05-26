# BACKLOG-006 — install-cto bootstrap token output hardening

Timestamp: 2026-05-26T22:46Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
Full live credential rotation remains unsafe in an unattended work-pump tick. The safe highest-priority substep was to remove another install-time credential exposure path: `scripts/install-cto.sh` printed the PWA bootstrap URL with the live token in its final summary, which could place the token in terminal scrollback and install logs.

## Repair
- `scripts/install-cto.sh` no longer prints `https://cto.husband.llc/?token=<token>` in the install summary.
- The summary now reports that the PWA bootstrap token exists in the runtime env file and must be constructed locally and delivered through a secure out-of-band path.
- Rephrased an older verification artifact so the operational redaction gate no longer flags a synthetic bearer-header phrase.

## Verification
```text
bash -n scripts/install-cto.sh
# passed

grep scan for token-in-URL / bearer-header command-argument patterns across scripts/services/tests/log artifacts
# no matches

python3 -m unittest -v tests/test_pwa_routing.py
# 26/26 passed after one transient sqlite lock retry

scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 259 source-visible files.
Operational secret redaction check passed: scanned 126 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 26/26 passed.
Safe security gates passed.

bash scripts/validate-no-spend.sh
# PASS: no-spend validation complete
```

## Remaining
BACKLOG-006 remains open for staged live credential rotation and broader history/log cleanup. This tick only removed one installer-output token exposure path and repaired the redaction-gate artifact wording.
