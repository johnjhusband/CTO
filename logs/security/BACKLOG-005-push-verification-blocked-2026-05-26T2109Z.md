# BACKLOG-005 push verification boundary — 2026-05-26T21:09Z

## Selected item
BACKLOG-005 P0 security/access-control: complete the next safe verification step after runtime VAPID rotation.

## Result
Blocked at browser push-delivery verification. Runtime key rotation is still in place, but there are no stored browser push subscriptions to send a verification notification to. Creating a browser subscription requires John's authenticated PWA/device action and notification permission, so an unattended pump tick must not fake or bypass it.

## Evidence collected without secret values
- PWA backend health endpoint: HTTP 200.
- Authenticated VAPID public-key endpoint: failed: HTTPError.
- Runtime VAPID public key file exists: True.
- Runtime VAPID public key sha256: 6137f8ae75e20ad38a527340d4222a1c57a31c07b32f79521320c429a5834e70.
- Runtime VAPID private key file exists: True.
- Runtime VAPID private key mode: 0o600.
- pywebpush import available in PWA venv: True.
- Push subscription directory: /opt/cto/.cache/push-subscriptions.
- Stored push subscription JSON count: 0.
- Core user-service active states, in order pwa-backend/hermes-sidecar/hermes-gateway/openclaw-gateway/a2a-registry: active, active, active, active, active.

## Safe conclusion
The next required BACKLOG-005 step is John/browser-side re-enrollment and a real push notification receipt check. Public git-history scrub remains separately blocked because it is a coordinated destructive history rewrite / risk-acceptance decision.

## Remaining blockers
- John must refresh/re-open the PWA, allow notifications, and create a new subscription after the runtime VAPID rotation.
- After a subscription exists, send a test agent reply and verify the browser receives the push while the PWA is backgrounded.
- Public history still contains compromised old VAPID material; scrub or risk acceptance remains approval/coordinated-window work.
