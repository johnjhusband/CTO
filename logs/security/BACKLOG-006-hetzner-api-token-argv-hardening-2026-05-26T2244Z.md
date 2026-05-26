# BACKLOG-006 — Hetzner API token argv hardening

Timestamp: 2026-05-26T22:44Z

## Selected item
P0 credential hygiene / BACKLOG-006.

## Why selected
Full live credential rotation is still unsafe in an unattended work-pump tick, but inspection found another safe credential-handling substep in `scripts/install.sh`: Hetzner API calls used curl header arguments that could expose the cloud token through process listings while provisioning commands run.

## Repair
- Added a local `hcloud_api` helper in `scripts/install.sh` implemented with Python `urllib.request`.
- The helper reads the Hetzner token from the process environment and builds the auth header inside Python instead of placing the token-bearing header in curl argv.
- Replaced the Hetzner SSH-key lookup, server-list lookup, and server-provision POST calls with the helper.
- Did not run provisioning, create servers, rotate credentials, or print/store secret values.

## Verification
- `bash -n scripts/install.sh`: passed.
- `scripts/security/run-safe-security-gates.sh`: passed.
  - Secret artifact guard passed.
  - Operational secret redaction check passed.
  - Redaction unit tests passed: 6/6.
  - PWA auth/routing regression tests passed: 26/26.
- Follow-up search found no remaining curl command line containing the Hetzner token-bearing auth header in `scripts/install.sh`.

## Remaining
BACKLOG-006 remains open for staged live credential rotation and broader history/log cleanup. This tick only removed one cloud-token process-argument exposure path from the clone installer.
