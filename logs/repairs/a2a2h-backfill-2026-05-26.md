# A2A2H backfill — 2026-05-26

Started: 2026-05-26T23:59:37Z
Policy role-doc commit: 3f757e720def003cdf37ce80728d844b091f176e
Hermes delegation attempt failed with HTTP 502 agent_incomplete; OpenClaw executed directly to avoid drift.

## Eligible CTO commits

## Backfill execution
- Ported CTO e0cfe740be6401ab97a1292ca7a5cb51b3216d28 to A2A2H as 256000474f5ff456cb14482f3e9080e2cfd7718a: Capture Hermes PWA routing and clone fixes

## Backfill execution
- Ported CTO 42fda25285a74774b9de2592f12c74f36cc9dc2f to A2A2H as 4807d59216dcbc82ddb2792b163d495355351728: Add mutual health memory and coordinated PWA jobs
- Ported CTO b0202add87c031debb670bdc3c14eaf38d0a2aca to A2A2H as dba3c3f80311dcb092b9ee53fb42f640a895e8e1: Harden clone PWA isolation and no-spend validation
- Ported CTO 823308d7951d091b1238a0aad0fe9c5e6c4d47f9 to A2A2H as e4b397b9770ead6ab48c52e20e8084150898a57f: pwa: bump SHELL_CACHE to v4 to force cookie-auth app.js refresh
- Ported CTO 1b4512d6d8d4106a31cb380cfa9ebe7569a173b8 to A2A2H as 7e5322099347f72fb99a880d6dc2a271996333de: pwa: replace URL token auth with session cookie gate
- Ported CTO 1a2263edda9ff731d560653efa66990d26af1706 to A2A2H as 9440a50101936fba8fab0bd7742593c398640baf: Harden PWA chat access control
- Ported CTO 2cb489d0bf5b5e04bdedb1faaa14f1ce68baa81b to A2A2H as 9aaeeece9c1b7688aef4c9ea41cc6eec4376dff2: Send PWA push notifications for agent replies
- Ported CTO 2cc000ac5aa26382ce74a99e2bb1cbd6718b5c37 to A2A2H as 0a86267f95146bba85d7dfe4476be48083de164b: pwa: pass VAPID key path to pywebpush
- Ported CTO dd40663942b401e3d4308e88211d1cc2d2462493 to A2A2H as d3c3b18c65f8a2ba3aa1d4b5e3f4a93d68d3ccb0: pwa: add reset route for cached clients
- Ported CTO c7a1d32caf5da9570091798ea4211c2622ed0c5e to A2A2H as 08742298d92734b6ba435905aa9cba9ca4f1c478: fix: require auth for PWA shell
- Ported CTO db02d6447e5e217f84786407a9b94f455d7cecbe to A2A2H as 65a3802ccdd9e1f6c7bf75e19b5e0e5f5b0f4a5f: pwa: add durable chat log export
- Ported CTO fea0599b582353f6440b81c7cca65def54c7b125 to A2A2H as f4376494acb3bd71e11dd6f04554531a0d38ce5b: Add PWA A2A audit transcript logging
- Ported CTO 32937689a24f2eecca085ee4404bf087f748f0c1 to A2A2H as 9d7fcab13c3568f6524bc861469e75853822a62e: pwa: fail closed without production auth token
- Ported CTO 82118868eb7c18762462384e5de5533b3eba8d79 to A2A2H as 2e6f7024e572494e79215207b75ab529c54c6789: pwa: add safe token rotation grace
- Ported CTO 71fd41c809e8b6627085db3a33ddca1cfdf5590a to A2A2H as df4b7edb27b9e5647ad4a4367c5c6f8111039460: pwa: stop legacy query-token SSE retry loop
- Ported CTO b39ed005435b8dd4a05ce89bb4557b682e1da769 to A2A2H as f5a197cb7eb967a88d50a27a62888ea11b9d6e23: security: hide keepalive bearer from process args
- Ported CTO aafebf94f7210a56d44eda607fa64cd5ee775fe3 to A2A2H as b9484355292f2f1f5a13f211e8ae5d67c5cf2aad: repair: stabilize OpenClaw Hermes work pumps
- Ported CTO 476e36676581ae062d76f01448b83687e83edb13 to A2A2H as 79cb8fd5fb8c7547b82ada9962982c862a9cb819: Add visible agent coordination toggle
- Ported CTO d8ecbd554649b2b9fb56741383efe2afed2993f3 to A2A2H as f5f39c69198218b535e917c8c4d20ee95bec2895: Add visible chat history link
- Ported CTO 389a01e7801ec907fb75f821ec3da7e8334a90bb to A2A2H as 3750aa481f3b78ef708ad6d82efe73a82b5e4807: Add visible push self-test button

## Verification
- Syntax sanity passed: services/pwa/backend/server.py parsed with ast.
- Tests: no tests directory exists in /opt/a2a2h yet.
- Leak grep passed after genericizing the residual lowercase `cto` substring in `refactor`.
- Final A2A2H HEAD before push: 659a63c31c55e8e817916eb200ded610376c3ff6
- Last synced CTO SHA recorded: 3f757e720def003cdf37ce80728d844b091f176e
- Completed: 2026-05-27T00:02:42Z
