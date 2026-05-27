# OpenClaw work-pump JSON fallback repair — 2026-05-27T10:45Z

## Context
- Required A2A2H per-tick check was run first: no upstream-eligible CTO commits since `27abb1203d2a13253e8c1b7e9658518d77794236`; no A2A2H port needed.
- Hermes provider circuit is open (`agent_incomplete_provider_NoneType`), so no semantic Hermes delegation was attempted.
- Service health showed `cto-openclaw-work-pump.service` failed at 10:40Z after the scheduled agent actually completed and committed `1f27e3f`, because the `openclaw agent --json` envelope omitted `finalAssistantVisibleText` even though the session transcript contained a normal assistant summary.

## Repair
- Updated `scripts/openclaw-work-pump.sh` so `summarize_json()` falls back to the latest assistant text in the bounded per-tick session JSONL (`~/.openclaw/agents/main/sessions/${pump_session_id}.jsonl`) when the JSON envelope omits `finalAssistantVisibleText` / `finalAssistantRawText`.
- Relaxed the non-zero complete-response guard to treat any visible fallback text as a completed response rather than requiring `stopReason == "stop"`, since the observed JSON envelope used `stopReason=unknown` while the transcript had a valid visible completion.

## Verification
- `bash -n scripts/openclaw-work-pump.sh` passed.
- Fallback inspection of `openclaw-work-pump-20260527T1033.jsonl` recovered the visible completion text that the service failed to see.
- No raw JSON/tool envelope or secret values were persisted in this artifact.
