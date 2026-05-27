# Daily AI Landscape Research — 2026-05-27

## Scope and gatekeeping
- [verified] Continuous-work prerequisites were checked first: `wiki/continuous-work-policy.md`, `HEARTBEAT.md`, `BACKLOG.md`, PWA chat log, git status, service listeners, and recent failed verification artifacts.
- [verified] A2A2H per-tick check found no upstream-eligible CTO drift since tracker SHA `91343b453ea64984a8f68b9bb9b43e5d86b6a3a1`: `git log <tracker>..HEAD -- services/pwa services/hermes_a2a_sidecar services/a2a_delegate scripts/cache-keepalive.sh chat/db.py` returned no commits.
- [verified] P0 security/PWA items remain open but are not safely closable in this tick: BACKLOG-005 requires John-approved public history rewrite or risk acceptance; BACKLOG-006 requires coordinated live credential rotation; BACKLOG-004/014/016 require John/device evidence for phone voice, background notification display, and visible coordination UI.
- [verified] Hermes semantic delegation remains degraded by repeated provider-side `agent_incomplete` / `NoneType` failures; the sidecar and gateway health endpoints are up.

## Sources scanned
- [verified] GitHub / Microsoft Agent Framework repository and releases.
- [verified] OpenAI API changelog.
- [verified] Anthropic platform release notes.
- [verified] Google Developers Blog front page / I/O 2026 summaries.
- [verified] arXiv survey result: `AI Agent Systems: Architectures, Applications, and Evaluation`.
- [verified] HN Algolia recent search for AI agents/MCP/A2A.
- [verified] Hugging Face papers month page was attempted but the extracted page only exposed a minimal shell; treat as partial source coverage.
- [verified] Practitioner/tool signals checked: `mupt-ai/dari-docs`, `Woodman97/lucy-agent`.

## Scored findings

| Finding | Score | Decision | Evidence |
|---|---:|---|---|
| OpenAI workload identity federation for short-lived API access tokens | 8 | Defer until BACKLOG-006 rotation window | [verified] OpenAI changelog says WIF was released May 26, 2026 and lets trusted workloads exchange external identity tokens for short-lived OpenAI access tokens without storing long-lived API keys. |
| Private MCP tunnel convergence: OpenAI Secure MCP Tunnel + Anthropic MCP tunnels | 7 | Defer / monitor | [verified] OpenAI changelog says Secure MCP Tunnel GA is account-led for enterprise customers; Anthropic release notes say MCP tunnels are Research Preview. Both target private/on-prem MCP servers without public exposure. |
| Microsoft Agent Framework 1.6.0 | 7 | Defer / monitor, do not migrate CTO now | [verified] GitHub repo has 10,771 stars, MIT license, Python/.NET support, production-grade positioning, A2A/MCP, workflows, observability, human-in-loop, and May releases with A2A v1.0 migration and default instrumentation. |
| Google I/O 2026 agentic development platform / WebMCP proposal | 6 | Archive / monitor | [verified] Google Developers Blog front page says I/O highlighted Gemini 3.5, Antigravity, Chrome DevTools for agents, and proposed WebMCP; this is strategically relevant but not yet a direct CTO migration path. |
| dari-docs agent-readable documentation testing | 6 | Archive / monitor | [verified] GitHub repo exists, created May 8 2026, 39 stars, Go, hosted/self-managed modes; useful pattern for testing whether docs are agent-usable, but too small/early for CTO adoption. |
| Lucy pay-per-task A2A/MCP/x402 micro-agent | 4 | Reject for CTO | [verified] GitHub README describes Telegram/A2A/MCP/x402 USDC task agent. Interesting payment pattern, but no current CTO problem requires crypto payment rails and it introduces external/payment risk. |

## Enrichment for 7+ findings

### OpenAI workload identity federation
- [verified] What it is: OpenAI API feature for exchanging externally issued workload identity tokens for short-lived OpenAI access tokens.
- [verified] Why it matters to CTO: directly maps to BACKLOG-006, because CTO currently depends on long-lived service credentials in `/opt/cto/.env`.
- [unverified] Unknown: whether Codex/OpenClaw's current ChatGPT-account OAuth/provider path can use WIF, and which external identity provider John wants for CTO workloads.
- Decision: defer until the coordinated credential rotation window; include WIF as the preferred research path for OpenAI API-key replacement if the provider stack supports it.

### Private MCP tunnel convergence
- [verified] OpenAI and Anthropic both shipped/private-previewed ways for agents to reach private MCP servers without exposing those servers publicly.
- [verified] Why it matters to CTO: validates CTO's current loopback-only posture and suggests future external-agent integrations should prefer tunnel/relay patterns over public MCP exposure.
- [unverified] Unknown: enterprise/account access and cost; OpenAI explicitly says initial GA is account-led.
- Decision: monitor only; no adoption until access/cost and provider fit are known.

### Microsoft Agent Framework
- [verified] What it is: Microsoft-owned MIT framework for production-grade agents and multi-agent workflows with Python/.NET, graph workflows, checkpointing, streaming, human-in-loop, A2A, MCP, OpenTelemetry, DevUI, and Foundry hosting.
- [verified] Why it matters to CTO: confirms community movement toward A2A/MCP + observability + durable workflows, all aligned with CTO/A2A2H priorities.
- [verified] Why not adopt now: CTO is already built around OpenClaw/Hermes/A2A2H; migration would be high-blast-radius while P0 PWA/security work remains open.
- Decision: defer and monitor; harvest patterns (A2A v1.0, OpenTelemetry-by-default, background non-streaming A2A ops) rather than replacing the brain stack.

## Backlog implications
- [verified] No new BACKLOG item opened. The material credential-hygiene finding maps to existing BACKLOG-006; private MCP tunnel findings are future architecture guidance, not a current missing capability.
- [verified] No active backlog item was observably complete enough to close without John/device confirmation or approval.

## Operations snapshot
- [verified] Loopback listeners observed: OpenClaw gateway `127.0.0.1:18789`, Hermes gateway `127.0.0.1:8642`, Hermes A2A sidecar `127.0.0.1:8643`, PWA backend `127.0.0.1:8088`.
- [verified] `systemctl --failed` reported 0 failed system units in this shell context.
- [verified] Recent failed verification remains Hermes work-pump provider failure: `logs/repairs/hermes-work-pump-agent-incomplete-2026-05-27T053639Z.md`.

## Daily result
- [verified] Items scanned: 6 source groups / 6 scored findings.
- [verified] Findings scored 7+: 3.
- [verified] Decisions logged: 3 deferred decisions (`CTO-DECISION-019` through `CTO-DECISION-021`).
- [verified] Adopt decisions: 0.
