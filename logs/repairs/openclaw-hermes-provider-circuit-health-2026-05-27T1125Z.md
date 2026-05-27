# OpenClaw tick: Hermes provider-circuit health verification — 2026-05-27T11:25Z

## Required pre-checks
- A2A2H upstream-port check ran first from `wiki/A2A2H_LAST_SYNC.md`: `git log 27abb1203d2a13253e8c1b7e9658518d77794236..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh services/chat/db.py` returned no commits, so no A2A2H port was required.
- Recent PWA chat was inspected. Latest John-facing message remains the 08:18Z PWA feature-status note; no newer John instruction was present in the durable chat log.
- Open/pending backlog scan found no safe P0 closure from disk evidence: BACKLOG-004/BACKLOG-014 still need phone/device behavior evidence; BACKLOG-005/BACKLOG-006 require coordinated credential/history windows; BACKLOG-015 remains credential-blocked.
- Hermes provider circuit is open via `/opt/cto/.cache/hermes-work-pump-provider-failure.json` (`agent_incomplete_provider_NoneType`), so this tick did not delegate semantic work to Hermes.

## Selected item
Hemisphere health / A2A delegation reliability.

## Verification
- `hermes-gateway.service` is active and local health returns `{"status":"ok","platform":"hermes-agent"}`.
- `cto-hermes-a2a-sidecar.service` is active and local health returns `{"status":"ok","service":"hermes-a2a-sidecar"}`.
- `cto-a2a-registry.service` local health returns `{"status":"ok"}`.
- Recent Hermes gateway logs still show provider-side `TypeError: 'NoneType' object is not iterable` against `openai-codex/gpt-5.5`; this is the same known provider failure, not a sidecar/listener outage.
- `KEEPALIVE_ROOT=/opt/cto scripts/cache-keepalive.sh` correctly skipped Hermes ping with `hermes ping skipped: provider circuit open`, so the adaptive circuit is preventing repeated provider probes during the outage.

## Result
The right hemisphere transport layer is up, but semantic Hermes delegation remains intentionally paused by the provider circuit. No services were restarted, no credentials were read or changed, no infrastructure was modified, and no raw provider dumps or secrets were stored. Next safe action is to let the adaptive cooldown expire before probing Hermes semantically again, while OpenClaw continues P0/P1 work directly.
