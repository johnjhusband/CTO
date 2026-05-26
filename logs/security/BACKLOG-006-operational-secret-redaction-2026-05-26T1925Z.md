# BACKLOG-006 Operational Secret Redaction Gate — 2026-05-26T19:25Z

## Selected item
BACKLOG-006 (P0 security): rotate live service credentials and remove secret values from operational logs/history.

## Safe step completed
Added a non-rotating local redaction/check gate for CTO operational artifacts. This does **not** rotate live credentials or rewrite public git history; those remain coordinated security work.

## Repair artifact
Added `scripts/security/redact-operational-secrets.py`:

- Scans `/opt/cto/logs` text artifacts and `/opt/cto/chat.db` message content.
- Redacts values for known secret env names while preserving variable names for auditability.
- Treats explicit placeholders such as `<set>` and `REDACTED` as already safe.
- Redacts common token/private-key markers.
- Reports only path/marker/count metadata, never secret values.
- Supports `--check` for CI/scheduled verification and `--apply` for in-place remediation.

## Redaction result
A first broad pass flagged env-assignment markers in operational logs and two chat DB rows. After refinement, placeholder-only tracked clone logs were restored unchanged, while the final gate now checks for non-placeholder secret assignment values and token/private-key markers.

Applied redaction to the local chat DB rows encountered during the broad pass. No secret values are recorded in this artifact.

## Verification

```text
$ scripts/security/redact-operational-secrets.py --check
Operational secret redaction check passed: scanned 83 file(s) plus chat.db; no unredacted markers found.

$ scripts/security/check-secret-artifacts.sh
Secret artifact guard passed: scanned 216 source-visible files.

$ python3 -m py_compile scripts/security/redact-operational-secrets.py && python3 -m unittest -v tests/test_pwa_routing.py
Ran 15 tests in 0.092s
OK
```

## Remaining BACKLOG-006 work
Live credential rotation/revocation, public history scrub coordination, and replacement of shell-echo secret propagation in clone/install flows remain open. This tick adds a repeatable operational-log/chat redaction gate and removes the local chat assignment markers found during the pass without touching live credentials.
