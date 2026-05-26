# BACKLOG-005 runtime push verification — 2026-05-26T21:11Z

## Selected item
BACKLOG-005 P0 security/access-control: verify the rotated VAPID runtime key can deliver Web Push after browser re-enrollment.

## Why this was selected
The previous 21:09Z pump tick verified the rotated key files and pywebpush runtime but was blocked because there were no stored browser subscriptions. At 21:11Z the PWA received a new authenticated browser subscription, so the next safe verification step became available.

## Evidence collected without secret values
- PWA backend remained up and served the VAPID public-key endpoint after cookie/session auth.
- Stored push subscription count: 1.
- Stored subscription file mode/size: `664`, 373 bytes.
- Runtime VAPID public key file exists and was hashed only: sha256 `4903027e3d6c0f980e8c9417fd56b0d592d9e002e4c32ba11ef0ad85d8d77a6c`.
- Runtime VAPID private key file exists with mode `600`; its content/hash was not printed.
- Direct backend push delivery using the live rotated VAPID key returned: `attempted=1 failed=0`.

## Verification commands
```text
$ find /opt/cto/.cache/push-subscriptions -type f -printf '%TY-%Tm-%Td %TH:%TM %m %s %f\n' | sort -r
2026-05-26 21:11 664 373 2c0d8163050441ca8575e3b51722c795.json

$ . .venv/bin/activate && python - <<'PY'
from services.pwa.backend import server
attempted, failed = server._send_push_notification(
    sender='system',
    body='CTO push verification: rotated VAPID runtime key delivered a test notification.',
    correlation='backlog-005-runtime-push-verification',
)
print(f'attempted={attempted} failed={failed}')
PY
attempted=1 failed=0

$ scripts/security/run-safe-security-gates.sh
Secret artifact guard passed: scanned 237 source-visible files.
Operational secret redaction check passed: scanned 106 file(s) plus chat.db; no unredacted markers found.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 20/20 passed.
Safe security gates passed.
```

## Result
Runtime VAPID rotation is verified through the server-side Web Push delivery API after browser re-enrollment. BACKLOG-005 is no longer blocked on runtime push verification.

## Remaining BACKLOG-005 work
Public git history still contains the old compromised VAPID material. Scrubbing it requires a coordinated destructive history rewrite, or John-approved risk acceptance. That remains open and should not be done silently by an unattended pump tick.
