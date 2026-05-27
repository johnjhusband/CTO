# OpenClaw work pump: Hermes provider circuit blocked

- Timestamp: 2026-05-27T18:25:00Z
- Selected item: hemisphere health / A2A delegation reliability
- A2A2H per-tick upstream-port check: no drift. Last synced CTO SHA: 6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3
- Hermes provider circuit: open (consecutive_failures=4 reason=agent_incomplete_provider_NoneType last_failure_utc=2026-05-27T18:24:13Z recovery=recovery restart skipped; provider outage circuit was already established with 3 consecutive failures, and previous restarts did not change outcome)
- Service health: cto-hermes-a2a-sidecar=active; hermes-gateway=active; cto-pwa-backend=active
- Action taken: did not delegate semantic work to Hermes this tick because the provider circuit is open. Recorded the degraded state and preserved the Hermes blocked artifact from the immediately preceding Hermes work-pump run.
- Blocker: Hermes A2A requests are reaching the sidecar, but the provider path returns agent_incomplete / NoneType after retries. Previous recovery restarts did not change the outcome, so another restart was intentionally skipped to avoid churn.
- Next safe action: keep OpenClaw-owned P0 safe gates and communication checks moving until the provider circuit closes, or inspect Hermes provider configuration/runtime logs when a non-churning repair path is available.
- Secret handling: no headers, bearer tokens, environment values, or raw request/response bodies recorded.
