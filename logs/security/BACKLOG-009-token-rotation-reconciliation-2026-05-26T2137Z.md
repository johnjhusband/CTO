# BACKLOG-009 token-rotation reconciliation — 2026-05-26T21:37Z

## Selected item
P0 security/access-control: BACKLOG-009/BACKLOG-013 PWA token rotation state after John's `Rotate` directive.

## Why this was selected
Recent PWA chat showed John requested rotation. The backlog had conflicting state: BACKLOG-009 said the PWA token was rotated pending device confirmation, while BACKLOG-013 recorded an emergency rollback and said rotation was not complete. A false "rotated" state on a live access-control item is unsafe.

## Work performed
Reconciled BACKLOG-009 with the later BACKLOG-013 rollback evidence:

- BACKLOG-009 status changed to `auth_restored_pending_safe_token_rotation`.
- BACKLOG.md active row for BACKLOG-009 updated to the same status.
- BACKLOG-009 resolution notes now clarify that the code/query-token repair remains complete, but live token rotation remains pending a safe delivery path and John/device confirmation.

No credential value, bootstrap URL, session cookie, or raw secret trace was recorded.

## Metadata-only verification

```text
PWA_AUTH_TOKEN_present=True
PWA_AUTH_TOKEN_non_empty=True
PWA_AUTH_TOKEN_length=64
GET / => 401
GET /api/messages => 401
GET /api/messages with legacy query-token shape => 401
```

## Result
The backlog no longer overstates the live rotation state. Current safe state: PWA auth is restored and rejecting unauthenticated/query-token access; rotating the live PWA token still requires a safe delivery path and John/device confirmation.
