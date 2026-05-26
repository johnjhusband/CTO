# Hermes work pump blocked: agent_incomplete

- Timestamp: 2026-05-26T23:43:46Z
- Selected item: hemisphere health / Hermes continuous work pump reliability
- Status: blocked_degraded
- Evidence: Hermes A2A sidecar returned HTTP 502 with `agent_incomplete` / provider-side `NoneType` error after a fresh task-scoped retry.
- Action taken: recorded this explicit blocked note and allowed the systemd pump unit to complete cleanly; OpenClaw remains responsible for follow-up repair.
- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.

## Sanitized error preview

HTTP 502: {"task_id": "hermes-work-pump-1779839035-retry2", "status": "error", "error": "Hermes HTTP 502: {\"error\": {\"message\": \"'NoneType' object is not iterable\", \"type\": \"server_error\", \"param\": null, \"code\": \"agent_incomplete\", \"hermes\": {\"completed\": false, \"partial\": false, \"failed\": true}}}"}
