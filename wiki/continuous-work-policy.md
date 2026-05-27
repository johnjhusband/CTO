# Continuous Work Policy

OpenClaw keeps strategic/routing authority. Hermes may initiate safe operational maintenance, repairs, verification, backlog work, and artifact cleanup when no delegated task is active. OpenClaw must also keep itself moving: when no John-facing conversation or delegated task is active, its work pump chooses one safe strategic/coordination item and advances it rather than idling.

Before choosing new work, each work pump must read `wiki/A2A2H_MAINTENANCE.md` and execute the per-tick A2A2H upstream-port check. If upstream-eligible CTO commits have drifted since `wiki/A2A2H_LAST_SYNC.md`, the tick must port them, update the tracker, commit, push, and write the port result into a `logs/repairs/` tick artifact before selecting a backlog item.

After the A2A2H check, each work pump must scan open/pending backlog items for evidence of completion already on disk and close anything observably done. Shipped work must not sit indefinitely in pending states when evidence already supports closure.

Default queue order:
1. P0 security and access-control issues.
2. Broken communication/reporting or human-interface delivery.
3. Hemisphere health, A2A delegation reliability, and repair.
4. Clone-test validation and installer repeatability.
5. Uncommitted/unpushed artifacts and documentation reconciliation.
6. Scheduled heartbeat/research work.

Stop conditions: spend money without prior approval; destroy data/infrastructure without authorization; create external risk; require a non-retrievable John decision; or override OpenClaw strategy/routing authority. When stopped, write a concise visible blocked note and continue with the next safe item.

Memory rule: durable lessons, decisions, architecture facts, reusable procedures, and John preferences go to the appropriate memory/shared-memory layer. Secrets, raw tool traces, chain-of-thought, and transient task noise never go into shared memory.

## PWA Chat-First UI Gate

Any commit touching `services/pwa/frontend/index.html`, `services/pwa/frontend/app.js`, `services/pwa/frontend/style.css`, or `services/pwa/frontend/service-worker.js` must run the real Playwright layout gate after the change and before the work is reported complete:

```bash
PWA_BASE_URL=https://cto.husband.llc \
PWA_AUTH_TOKEN="$PWA_AUTH_TOKEN" \
/home/cto/.local/bin/pytest tests/test_pwa_chat_first_layout.py -v
```

`PWA_AUTH_TOKEN` must be sourced from `/opt/cto/.env`. If the test fails or skips, the commit does not land. Do not call PWA visible UI work tested, verified, or `[verified]` unless this Playwright test actually passed after the change. CSS string-search tests do not count for visible PWA UI verification. Adding new features to the visible shell is an automatic failure unless the chrome stays within the chat-first thresholds.

The chat-first philosophy is binding: new features go in the `⋯` settings disclosure or a separate route such as `/chat-log/`, never as cards or banners above the chat. If a feature genuinely needs to live above the chat, raise it for John's approval first.
