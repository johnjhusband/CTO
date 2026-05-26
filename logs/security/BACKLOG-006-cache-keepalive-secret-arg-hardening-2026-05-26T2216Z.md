# BACKLOG-006 — cache keepalive secret argument hardening

Timestamp: 2026-05-26T22:16Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
Full live credential rotation remains unsafe in an unattended pump tick, but inspection found a safe credential-hygiene issue: `scripts/cache-keepalive.sh` sent the Hermes A2A bearer token through a `curl -H "Authorization: Bearer ..."` command argument. That can expose the token through process listings while the command runs.

## Repair
- Removed the unused PWA token read from `scripts/cache-keepalive.sh`.
- Replaced the Hermes keepalive `curl` invocation with a Python `urllib.request` helper.
- The helper reads the Hermes A2A token in-process from `/opt/cto/.env` and sets the Authorization header without putting the bearer value in shell variables or command arguments.
- Increased the Hermes keepalive HTTP timeout to 90s after an initial 30s probe was too tight under current runtime latency.

## Verification
```text
bash -n scripts/cache-keepalive.sh
# passed

scripts/cache-keepalive.sh
# exit 0; no token value printed

scripts/security/run-safe-security-gates.sh
Secret artifact guard passed.
Operational secret redaction check passed.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 26/26 passed.
Safe security gates passed.
```

## Remaining
BACKLOG-006 remains open for staged live credential rotation and history cleanup. This repair only removes one process-argument secret exposure path from the keepalive timer.
