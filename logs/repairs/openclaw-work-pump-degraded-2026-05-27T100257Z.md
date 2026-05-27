# OpenClaw work pump degraded output

- Timestamp: 2026-05-27T10:02:57Z
- Process status: 0
- Stop reason: unknown
- Sanitized status: no visible final text
- Finding: The scheduled work pump returned without visible final text, so journald alone would not prove a durable tick result.
- Handling: Raw JSON stayed only in the temporary file and was deleted by the cleanup trap.
- Next safe action: if repeated, inspect OpenClaw Gateway/session transport errors and the persistent `openclaw-work-pump` session.
