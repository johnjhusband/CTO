# BACKLOG-014 PWA install/notification icon repair — 2026-05-27T02:45Z

## Selected item
John reported that PWA feature work was not visible from his side. I selected BACKLOG-014 because the live PWA backend was logging 404s for `/static/icon-192.png`, and the service worker uses that icon for Web Push notifications. Missing install/notification icons are a visible PWA quality issue and can degrade install/background notification behavior.

## Change
- Added generated PNG assets: `services/pwa/frontend/icon-192.png` and `services/pwa/frontend/icon-512.png`.
- Added both icons to the PWA service-worker shell cache and bumped the CTO cache to `cto-shell-v10` so installed clients can pick up the repaired shell.
- Added regression coverage that verifies manifest icon references exist, are non-empty PNG files, and are cached by the service worker.
- Updated existing PWA UI tests for the current visible feature-panel copy/cache version.

## Verification
- `scripts/security/run-safe-security-gates.sh` passed: secret artifact guard, operational redaction, install guard, credential preflight/smoke syntax and runtime checks, 8 redaction tests, 29 PWA auth/routing tests, and 1 PWA voice UI test.
- Live local PWA static checks on configured backend port `8088`:
  - `/static/icon-192.png`: HTTP 200, PNG signature, 1093 bytes.
  - `/static/icon-512.png`: HTTP 200, PNG signature, 3847 bytes.

## Status
This advances BACKLOG-014 but does not close it. John/device confirmation is still needed for actual phone background notification behavior. No secrets or raw tool traces were recorded.

## A2A2H port
- Ported the same icon assets and service-worker cache update to `/opt/a2a2h`.
- A2A2H commit: `35de5ddb56e4d12019630da353c580a443bc042a`.
- Updated `wiki/A2A2H_LAST_SYNC.md` to CTO commit `180e8da5b14943e8ccb6dd55e5b0309ff840aeaf`.
