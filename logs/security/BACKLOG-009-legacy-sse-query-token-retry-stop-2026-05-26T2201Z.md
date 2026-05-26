# BACKLOG-009/BACKLOG-013 — legacy SSE query-token retry stop

Timestamp: 2026-05-26T22:01Z

## Selected item
P0 PWA access-control / human-interface reliability.

## Why selected
After the safe token-rotation grace repair, the live PWA backend was active and access control was holding, but runtime logs showed old cached PWA clients repeatedly opening `/api/stream?token=[REDACTED]` and receiving 401. API query tokens must stay rejected, but for Server-Sent Events a 401 causes EventSource to reconnect forever, creating log noise and keeping stale clients in a broken loop.

## Repair
- `/api/stream?token=...` now returns HTTP 204 with `Cache-Control: no-store`.
- 204 preserves the security property that API query-token auth is not accepted, while telling EventSource-capable stale clients to stop retrying.
- Normal unauthenticated `/api/stream` still returns 401.
- Current-cookie `/api/stream` remains the supported live message path.

## Verification
```text
python3 -m unittest -v tests/test_pwa_routing.py
Ran 26 tests in 0.141s — OK

scripts/security/run-safe-security-gates.sh
Secret artifact guard passed.
Operational secret redaction check passed.
Redaction unit tests: 6/6 passed.
PWA auth/routing regression tests: 26/26 passed.
Safe security gates passed.

systemctl --user restart cto-pwa-backend.service
systemctl --user is-active cto-pwa-backend.service => active
GET /api/stream?token=<synthetic-invalid-token> => 204
GET /api/stream without cookie/token => 401
GET /api/health => {"status":"ok","service":"pwa-backend"}
```

## Remaining
Live token rotation is still blocked on safe delivery and John/device confirmation. This repair only stops the stale query-token EventSource retry loop without changing or exposing any token value.
