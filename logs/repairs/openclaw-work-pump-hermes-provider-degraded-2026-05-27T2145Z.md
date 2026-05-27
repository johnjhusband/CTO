# OpenClaw work pump — Hermes provider degraded — 2026-05-27T2145Z

## Required pre-checks
- A2A2H per-tick upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md`: last synced CTO SHA `6cf1da1e8b1e7de05cc94e9f2af38458fb204ee3`; no upstream-eligible drift was found, so no A2A2H port was required.
- Recent PWA chat was inspected: latest entries are Hermes work-pump degraded system events; no newer John instruction was present in today's durable chat log.
- Open/pending backlog scan found no safe closure from disk evidence:
  - BACKLOG-004/014/016/017 still carry explicit John phone/visible-verification commitments.
  - BACKLOG-005/006 require coordinated credential/history rotation windows.
  - BACKLOG-007/010 require approval before firewall/backup infrastructure changes.
  - BACKLOG-015 remains pending provider/API credentials.
- Hermes provider circuit file is present and open for `agent_incomplete_provider_NoneType`, so this tick did not delegate semantic work to Hermes.

## Selected safe item
Hemisphere health / Hermes continuous-work reliability.

Higher-priority P0/P1 items were blocked by approval, credential, or John-device-verification requirements. The safe OpenClaw-owned advancement this tick is to preserve the degraded Hermes state as a committed operational artifact and keep the provider-circuit evidence visible for follow-up repair.

## Evidence
- Circuit file: `/opt/cto/.cache/hermes-work-pump-provider-failure.json` reports consecutive failures and last recovery restart of `hermes-gateway` plus `cto-hermes-a2a-sidecar`.
- Hermes failure artifact: `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T214026Z.md` records the sanitized HTTP 502 / provider `NoneType` failure and recovery attempt.
- Service health check after the restart showed both `cto-hermes-a2a-sidecar` and `hermes-gateway` active, but Hermes provider calls still fail with `agent_incomplete`.

## Action taken
- Recorded this OpenClaw-side tick artifact.
- Committing the sanitized Hermes failure artifact and this OpenClaw artifact so the degraded state is not left as an untracked transient file.

## Result
No production services, credentials, infrastructure, PWA frontend files, or A2A2H files were modified. Next safe repair step is to diagnose Hermes' OpenAI Codex provider path or fallback configuration directly, without routing semantic work through Hermes while the circuit remains open.
