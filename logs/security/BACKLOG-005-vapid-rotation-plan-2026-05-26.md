# BACKLOG-005 — VAPID rotation plan and go/no-go

Timestamp: 2026-05-26T04:45Z
Owner: Hermes
Priority: P0

## Current state
- A new candidate VAPID keypair has been generated under `/opt/cto/.vapid-new/`.
- The private key remains outside git and is mode 0600.
- The public browser key is `/opt/cto/.vapid-new/public.b64url`.
- Existing production key remains active until cutover to avoid breaking push mid-session.

## Candidate key fingerprints
- `public.b64url` sha256: `4903027e3d6c0f980e8c9417fd56b0d592d9e002e4c32ba11ef0ad85d8d77a6c`
- `private.pem` sha256: `31975df65e67f24ab0aff5f62b62ea095f0ee07aefa5f37bc4ee0c8e562345a7`
- public key length: 89 bytes

## Rotation steps
1. Stop PWA backend: `systemctl --user stop cto-pwa-backend.service`.
2. Back up old VAPID runtime key directory locally only: `cp -a /opt/cto/.vapid /opt/cto/.vapid-compromised-$(date -u +%Y%m%dT%H%M%SZ)`.
3. Replace runtime keys: `rm -rf /opt/cto/.vapid && mv /opt/cto/.vapid-new /opt/cto/.vapid`.
4. Clear old push subscriptions because they were created with the old public key: `rm -f /opt/cto/.cache/push-subscriptions/*.json`.
5. Restart PWA backend: `systemctl --user start cto-pwa-backend.service`.
6. John reopens the PWA, uses `/reset` if needed, taps Enable push again, and Hermes sends a push verification.
7. Mark BACKLOG-005 rotated locally after `PUSH_TEST: attempted=1 failed=0` on the new key.

## History scrub decision
Go/no-go: NO-GO for immediate git history rewrite in this unattended push window.

Reason: scrubbing a public repository history with BFG/git-filter-repo is destructive to clones and requires explicit coordination after the 16 unpushed commits are safely on origin. The correct immediate action is rotate runtime keys, stop using the compromised key, and schedule a coordinated history rewrite or documented acceptance.

## Rollback
If push breaks after rotation, stop the backend, restore the latest `/opt/cto/.vapid-compromised-*` directory temporarily, restart the backend, and keep BACKLOG-005 open. Do not recommit or expose private key material.
