# Shared Memory Intake Lane

Status: active as of 2026-05-24.
Owner: OpenClaw.
Purpose: staging lane for cross-hemisphere memory proposals before they become canonical shared memory.

## How to use this lane

OpenClaw and Hermes may append proposed shared-memory records here or create linked files under `wiki/shared-memory-intake/` if a proposal needs more detail.

A proposal is not canonical until OpenClaw marks it `accepted_shared` and promotes it into the appropriate canonical location, usually `MEMORY.md`, `wiki/`, a decision log, or a handoff document.

## Proposal template

Subject:
Scope:
Proposed fact or summary:
Source agent:
Owner:
Evidence or artifact path:
Confidence:
Timestamp UTC:
Status: proposed_shared
Supersedes:
Contradicts:
Review notes:

## Current accepted baseline

Subject: Cross-hemisphere shared memory contract
Scope: OpenClaw + Hermes
Proposed fact or summary: Shared memory stores durable CTO-level knowledge only. Private hemisphere internals remain isolated. OpenClaw owns strategic canon and final promotion. Hermes owns execution observations and proposals. The canonical source of truth is the human-readable CTO vault, with Engram/SQLite as searchable coordination/index layer.
Source agent: OpenClaw, after Hermes negotiation
Owner: OpenClaw
Evidence or artifact path: `/opt/cto/wiki/shared-memory-contract.md`; `/opt/cto/MEMORY.md`; `/opt/cto/HERMES_ROLE.md`; `/opt/cto/OPENCLAW_ROLE.md`
Confidence: high
Timestamp UTC: 2026-05-24T19:56:00Z
Status: accepted_shared
Supersedes: earlier incomplete shared-memory wording in `MEMORY.md`
Contradicts: stale assumption that `/opt/cto/.engram/cto.db` is the active canonical Engram database
Review notes: Hermes MCP was repaired to use `ENGRAM_DATA_DIR=/opt/cto/.engram` and `engram mcp --tools=agent`, which creates `/opt/cto/.engram/engram.db`. The empty `/opt/cto/.engram/cto.db` remains a stale artifact unless a future migration deliberately adopts it.

## Accepted record — Hermes response repair, 2026-05-24

Subject: Hermes A2A response path repaired
Scope: OpenClaw + Hermes + A2A sidecar
Proposed fact or summary: Hermes was reachable at the gateway health endpoint but failed delegated work because its Codex OAuth credential pool was using the old `john@husband.llc` Team account token, which had hit a usage limit, while `~/.codex/auth.json` held the intended `cto@husband.llc` ChatGPT Pro Codex OAuth token. OpenClaw repaired `~/.hermes/auth.json` by backing it up, promoting the `cto@husband.llc` Codex OAuth token into Hermes provider state and credential pool, clearing the exhausted credential status, and restarting `hermes-gateway.service`. A post-repair A2A delegation returned `OK`.
Source agent: OpenClaw
Owner: OpenClaw
Evidence or artifact path: `/home/cto/.hermes/auth.json.bak-pro-repair-20260524T195828Z`; `systemctl --user restart hermes-gateway.service`; A2A task `5ec65e13-a47d-4fec-b60a-0bc3b37c44ec`
Confidence: high
Timestamp UTC: 2026-05-24T19:59:30Z
Status: accepted_shared
Supersedes: stale MEMORY.md status saying Hermes installation was pending
Contradicts: stale operational assumption that Hermes was already using the dedicated CTO Pro account
Review notes: Do not store tokens in shared memory. If Hermes stops responding again, check `~/.hermes/logs/agent.log` for `usage_limit_reached`, verify the OAuth account claim is `cto@husband.llc` / `prolite`, and verify A2A with a minimal delegation before escalating.

Subject: Hermes API server memory scoping repair
Scope: Hermes gateway + A2A sidecar
Proposed fact or summary: Hermes API server was running but rejected `X-Hermes-Session-Key` because the API key existed only in a legacy top-level `api_server.key` config block; Hermes runtime reads `platforms.api_server.extra.key` or `API_SERVER_KEY`. OpenClaw promoted the existing key into `platforms.api_server.extra`, kept loopback host/port explicit, restarted `hermes-gateway.service`, verified authenticated `/v1/models` returned 200 with no session-key warning, and verified A2A delegation returned `OK`.
Source agent: OpenClaw
Owner: OpenClaw
Evidence or artifact path: `/home/cto/.hermes/config.yaml`; `hermes-gateway.service`; `/opt/cto/services/hermes_a2a_sidecar/server.py`; A2A task `4e661631-3ed5-48c5-bd96-330e98ffc939`
Confidence: high
Timestamp UTC: 2026-05-25T00:18:30Z
Status: accepted_shared
Supersedes: earlier warning that Hermes long-term memory scoping was disabled due to no API key
Contradicts:
Review notes: Do not set `GATEWAY_ALLOW_ALL_USERS=true`; the remaining allowlist warning is not blocking A2A and should not be resolved by opening access broadly.

## 2026-05-25 — Hermes PWA timeout 500 repair
- [verified] A PWA-visible `hermes_send_failed` event at 00:25 UTC was caused by the Hermes A2A sidecar timing out after 180s while Hermes was still working; the sidecar caught the timeout via the generic exception path and returned HTTP 500, which the PWA rendered as `<HTTPError 500: 'Internal Server Error'>`.
- [verified] OpenClaw patched `/opt/cto/services/hermes_a2a_sidecar/server.py` to catch timeout exceptions explicitly and return 504 with a clear timeout payload, patched `/opt/cto/services/pwa/backend/server.py` to use `HERMES_SEND_TIMEOUT_S` and parse sidecar HTTP errors, and added systemd user drop-ins setting `HERMES_TIMEOUT_S=600` and `HERMES_SEND_TIMEOUT_S=660`.
- [verified] Services were restarted and a live PWA backend `send_to_hermes` smoke test returned `OK` with session id `pwa-john-hermes-main`.

## 2026-05-25 — PWA content-aware routing shipped
- [verified] OpenClaw patched `/opt/cto/services/pwa/backend/server.py` so explicit `@openclaw` and `@hermes` mentions still override routing, no-mention Hermes-addressed messages route to Hermes, greetings and both-hemisphere prompts route to both, repair/debug/orchestration prompts default to OpenClaw, and ambiguous prompts default to OpenClaw as orchestrator.
- [verified] The PWA backend restarted cleanly, parser smoke tests passed, `/api/health` returned OK, and a no-mention message containing “Hermes” routed to Hermes and returned `OK`.

## 2026-05-25 — John autonomy correction: always continue to next step
- [verified] John instructed both OpenClaw and Hermes: “At the completion of every task you must ask yourself what's next and start on that next step.”
- [verified] Operating rule: after completing any task, each hemisphere must identify the next useful step and begin it autonomously unless the next step spends money, destroys data, creates external risk, or requires a non-retrievable decision from John.
- [verified] OpenClaw updated `/opt/cto/USER.md` and `/opt/cto/MEMORY.md`; Hermes should store the same rule in its individual memory.

## 2026-05-25 — PWA conversation architecture before cloning
- [verified] John identified a prior clone-test failure mode: both agents talking in the same chat caused coordination problems.
- [verified] OpenClaw wrote `/opt/cto/wiki/pwa-conversation-architecture.md` defining PWA as a controlled human-facing control room, not an uncontrolled group chat. OpenClaw owns orchestration/final-mile strategy; Hermes implements after scoped handoff; `@both` must be coordinated and sequenced rather than naive parallel chatter.
- [verified] Clone candidates must use distinct identity/session/chat/A2A namespaces and must not post directly into the production PWA chat before promotion.
