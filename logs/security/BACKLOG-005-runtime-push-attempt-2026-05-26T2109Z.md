# BACKLOG-005 runtime push verification attempt — 2026-05-26T21:09Z

## Selected item
BACKLOG-005 P0 security/access-control: verify the runtime VAPID rotation against the live PWA push path without exposing secret values.

## Action
A benign Web Push verification payload was sent through the configured pywebpush path to every stored browser subscription. The payload contained only a generic verification message and no operational details or secrets.

## Evidence collected without secret values
- PWA backend health endpoint: HTTP 200.
- Authenticated VAPID public-key endpoint: HTTP 200; length 88; sha256 6137f8ae75e20ad38a527340d4222a1c57a31c07b32f79521320c429a5834e70; matches runtime file: True.
- Runtime VAPID public key sha256: 6137f8ae75e20ad38a527340d4222a1c57a31c07b32f79521320c429a5834e70.
- Runtime VAPID private key file exists: True.
- Runtime VAPID private key mode: 0o600.
- pywebpush import available in PWA venv: True.
- Push subscription directory: /opt/cto/.cache/push-subscriptions.
- Stored push subscription JSON count before attempt: 1.
- Push send attempts: 1.
- Push send failures: 0.
- Push failure classes/counts, if any: {}.
- Core user-service active states, in order pwa-backend/hermes-sidecar/hermes-gateway/openclaw-gateway/a2a-registry: active, active, active, active, active.

## Safe conclusion
Runtime VAPID key rotation and server-side push submission path are verified at provider-submit level based on this unattended check. End-to-end browser receipt still requires John/device observation because server-side provider submission cannot prove the notification appeared on the subscribed device.

## Remaining blockers
- John/device confirmation of actual background notification receipt is still required before marking BACKLOG-005/BACKLOG-014 fully verified.
- Public git history still contains compromised old VAPID material; coordinated history rewrite or documented risk acceptance remains approval/coordinated-window work.
