# BACKLOG-003 PWA scanner-burst verification — 2026-05-27T08:05Z

## Scope
Non-destructive live security verification after the public PWA logged a scanner burst against common secret/config paths. This tick did not mutate credentials, rewrite history, change firewall rules, create/destroy infrastructure, spend money, or delegate semantic work to Hermes.

## Required pre-checks
- A2A2H per-tick drift check: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no port required.
- Git state: `/opt/cto` and `/opt/a2a2h` were clean and synced before selection.
- Services: no failed user units; OpenClaw Gateway, PWA backend, Hermes gateway, Hermes A2A sidecar, and work-pump timers were active.
- Hermes provider circuit: open after repeated provider-side `agent_incomplete` failures, so no Hermes semantic delegation was attempted.
- Backlog completion scan: P0 credential/history work remains coordinated-window blocked; P0 PWA voice/background/audit items remain pending John/device evidence; no item was safely closable from disk evidence.

## Observation
The PWA backend journal since 07:45Z showed scanner-style unauthenticated requests for common exposed-secret/config paths including `.env` variants, `.git/config`, WordPress/PHP config files, AWS config filenames, and `phpinfo.php`.

## Verification
- Every observed scanner-style request in the recent PWA journal returned HTTP 401.
- Recent PWA journal scan found no sensitive credential markers such as token query parameters, bearer-looking authorization values, or CTO credential environment names.
- Live loopback checks for representative scanner paths returned HTTP 401 with `Cache-Control: no-store`:
  - `/.env`
  - `/admin/.env`
  - `/.git/config`
  - `/wp-config.php`
  - `/phpinfo.php`

## Result
The live PWA remained fail-closed during the scanner burst and denied representative secret/config probes with non-cacheable 401 responses. BACKLOG-003 remains open for the broader public-repo/deployment security audit, but this active probe did not expose data through the PWA path.
