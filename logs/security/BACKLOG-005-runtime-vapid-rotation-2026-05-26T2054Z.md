# BACKLOG-005 runtime VAPID rotation — 2026-05-26T20:54Z

## Selected item
BACKLOG-005 P0 security/access-control: rotate the live PWA Web Push VAPID runtime key away from the key material already treated as compromised.

## Why this was safe in this pump tick
The full public-history scrub remains destructive/coordination-gated, but runtime key cutover was safe because:
- A candidate keypair already existed under an ignored runtime path.
- The candidate private key was mode 0600 and outside git.
- The current push-subscription directory existed but had zero subscription JSON files, so no active browser push subscriptions needed deletion.
- The old runtime key directory was renamed to an ignored local backup path rather than deleted.

## Action taken
- Renamed `/opt/cto/.vapid` to an ignored `.vapid-compromised-...` backup directory.
- Renamed `/opt/cto/.vapid-new` to `/opt/cto/.vapid`.
- Re-applied mode 0600 to `/opt/cto/.vapid/private.pem`.
- Restarted `cto-pwa-backend.service`.

## Verification
- `cto-pwa-backend.service`: active after restart.
- `GET /api/health`: returned `{"status":"ok","service":"pwa-backend"}`.
- Authenticated `GET /api/push/vapid_public_key`: HTTP 200.
- Returned public key length: 88 characters.
- Returned public key sha256: `6137f8ae75e20ad38a527340d4222a1c57a31c07b32f79521320c429a5834e70`.
- Returned public key matches `/opt/cto/.vapid/public.b64url`: yes.
- Returned public key matches any compromised backup public key: no.
- Current private key mode: `0600`.
- Push subscription JSON files present during cutover: `0`.
- Git ignore coverage still includes `.vapid/`, `.vapid-new/`, `.vapid-compromised-*/`, and `.cache/`.
- 2026-05-26T21:02Z re-check: `scripts/security/run-safe-security-gates.sh` passed after the runtime rotation artifact/status updates.

## Remaining BACKLOG-005 work
- John still needs to re-open/refresh the PWA, enable push, and receive a runtime push verification before marking background push fully verified.
- Public git history still contains old key material; coordinated history rewrite or documented risk acceptance remains open and must not be done in an unattended pump tick.
