# OpenClaw work pump: Hermes agent_incomplete investigation — 2026-05-27T00:40Z

## Selection
OpenClaw continuous-work pump selected hemisphere health / Hermes A2A reliability. Higher-priority P0 security items (BACKLOG-005/BACKLOG-006) still require coordinated credential/history operations, and the visible PWA P0 items (BACKLOG-004/014/016/017) are awaiting John/device-visible confirmation after code/UI work shipped. The latest failed verification was Hermes returning `agent_incomplete` / provider-side `NoneType` errors during its continuous work pump.

## Required context checked
- `wiki/continuous-work-policy.md` and `HEARTBEAT.md` — work-pump queue and stop conditions.
- `BACKLOG.md` plus BACKLOG-004/014/016/017 detail JSON — confirmed reopened visible-PWA items require John/device confirmation before closure.
- Recent PWA chat logs — John directed backlog closure and then explicitly reopened the frontend-visible PWA issues when his phone showed no visible change.
- Git status — only the Hermes work-pump blocked note was untracked at start of this investigation.
- Service health — no failed user units; `openclaw-gateway`, `cto-pwa-backend`, `cto-a2a-registry`, `cto-hermes-a2a-sidecar`, and `hermes-gateway` active; ports 18789 and 8642 loopback-only; public 80/443 exposed through the existing front door.
- A2A2H per-tick upstream check — `git log 5d3dbc0baa6e84e280eed8460f3ef53359476681..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned empty, so no A2A2H port was due this tick.

## Findings
- Hermes gateway is alive at `/health`, but LLM calls through the Hermes API server repeatedly fail with provider-side `TypeError: 'NoneType' object is not iterable` and are surfaced by the A2A sidecar as HTTP 502 with `agent_incomplete`.
- Failures occurred for compact task-scoped sessions such as `a2a-hermesworkpump1779841987`, so this is not the earlier long persistent A2A transcript growth bug.
- Journal evidence shows small request context (about 9k tokens / two messages) and a non-retryable client error from Hermes' `openai-codex` provider path.
- Hermes config pins primary, fallback, session_search, and compression to the same `openai-codex/gpt-5.5` path, so the configured fallback cannot bypass this provider-path failure.
- Hermes reports `Hermes Agent v0.13.0 (2026.5.7)` with an update available, but previous PWA chat notes say self-update requires John's explicit request. I did not run `hermes update`.
- Request dump files exist under `/home/cto/.hermes/sessions/`; this artifact intentionally records only metadata and does not include raw prompts, headers, bearer tokens, or environment values.

## Result
Status: `blocked_degraded`.

No safe autonomous code/config repair is available in this tick without either:
1. changing Hermes' configured model/provider/fallback path, which can affect cost/auth behavior; or
2. updating Hermes itself, which John has not explicitly requested/approved.

The system remains partially operational: OpenClaw and the PWA are up; Hermes health endpoint is up; Hermes LLM/A2A work execution is degraded.

## Verification performed
- `systemctl --user --failed` — no failed user units.
- `systemctl --user list-units '*cto*' '*openclaw*' '*a2a*' --all` — core services/timers active as expected except one-shot/timer-triggered services inactive/dead between runs.
- `ss -ltnp` — OpenClaw and Hermes gateways listen on loopback; public exposure is still 80/443.
- A2A2H drift command above — empty output, no port due.
- Sanitized config/request-dump inspection — confirmed same-provider fallback and compact session IDs; no secrets recorded.

## Next safe action
Ask John for one explicit choice:
- approve a Hermes update attempt, or
- approve a no-spend provider/fallback change if John identifies an already-authorized provider, or
- keep Hermes degraded and continue OpenClaw-only work on safe backlog items.
