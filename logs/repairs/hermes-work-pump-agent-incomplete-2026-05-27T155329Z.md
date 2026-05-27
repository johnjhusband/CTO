# Hermes work pump blocked: agent_incomplete

- Timestamp: 2026-05-27T15:53:15Z
- Selected item: hemisphere health / Hermes continuous work pump reliability
- Status: blocked_degraded
- Evidence: Hermes A2A sidecar returned HTTP 502 with `agent_incomplete` / provider-side `NoneType` error after a fresh task-scoped retry.
- Action taken: retried with a fresh task-scoped session; after repeat failure, attempted the configured existing-service recovery restart once unless cooldown was active, then recorded this explicit blocked note and allowed the systemd pump unit to complete cleanly.
- Human-visible reporting: wrote a sanitized `hermes_work_pump_blocked` system_event to the PWA chat log when possible.
- Recovery attempt: recovery restart skipped; cooldown active for another 1798s
- Secret handling: no request headers, bearer tokens, environment values, or raw tool traces recorded.

## Sanitized error preview

HTTP 502: {"task_id": "hermes-work-pump-1779897205-retry2", "status": "error", "error": "Hermes HTTP 502: {\"error\": {\"message\": \"'NoneType' object is not iterable\", \"type\": \"server_error\", \"param\": null, \"code\": \"agent_incomplete\", \"hermes\": {\"completed\": false, \"partial\": false, \"failed\": true}}}"}
