# A2A Communication Layer
**L0:** A2A is open source (Apache 2.0, Linux Foundation). Human-to-agent UIs already exist (a2a-ui, A2UI, AG-UI). Replaces Telegram as primary but Telegram can remain as a frontend.
**L1:** Google's A2A protocol is fully open source, Apache 2.0, governed by Linux Foundation with 150+ organizations. SDKs in Python, JS, Java, Go, Rust, .NET. Protocol explicitly supports human-to-agent interaction (not just agent-to-agent). Existing UIs: a2a-ui (Next.js chat client), A2UI (Google's rich UI components), AG-UI (CopilotKit agent-to-human). Building a human interface is "days not weeks" using existing code. Best approach: A2A as core protocol with optional Telegram frontend on top.
**Last updated:** 2026-05-03
**Verification:** All verified against GitHub repos, Linux Foundation announcements, and official docs.

## Why Replace Telegram?
- Bot conflict when cloning (two CTOs can't share one bot)
- No programmatic bot creation via BotFather
- `/approve` cards don't work on mobile
- Rate limits (1 msg/sec per chat, 429 blocks all users)
- No message history for bots

## A2A Protocol
- **License:** Apache 2.0 [verified]
- **Governance:** Linux Foundation (AAIF) [verified]
- **Spec:** [a2a-protocol.org](https://a2a-protocol.org/latest/)
- **GitHub:** [github.com/a2aproject](https://github.com/a2aproject) (12 repos)
- **SDKs:** Python, JavaScript, Java, Go, Rust, .NET [verified]
- **150+ organizations** including Google, Microsoft, AWS [verified]

## Human-to-Agent Interaction [verified — protocol designed for this]
A2A explicitly supports humans at either end. Key features:
- Human-in-the-loop (`TASK_STATE_AUTH_REQUIRED`)
- Async tasks (hours/days with human involvement)
- Multimodal (text, audio, video, forms, UI components)
- Input-required state (agent asks human for clarification)

## Existing Human UIs
| UI | What | Repo |
|----|------|------|
| **a2a-ui** | Next.js + Material UI chat client | [github.com/a2anet/a2a-ui](https://github.com/a2anet/a2a-ui) |
| **A2UI** | Google's rich declarative UI components | [github.com/google/A2UI](https://github.com/google/A2UI) |
| **AG-UI** | CopilotKit's agent-to-human event protocol | [github.com/ag-ui-protocol/ag-ui](https://github.com/ag-ui-protocol/ag-ui) |
| **Demo App** | Web demo with chat, task inspection | [agent2agent.info/docs/demo](https://agent2agent.info/docs/demo/) |

## Architecture for CTO
```
Human (phone/desktop)
  ↕ a2a-ui web app (or Telegram as optional frontend)
  ↕ A2A Protocol (HTTP, JSON-RPC 2.0, SSE)
  ↕ CTO Agent (OpenClaw with A2A endpoint)
  ↕ MCP (tools: GitHub, Hetzner, engram, web search)
```

## Implementation Path
1. CTO exposes an Agent Card at `/.well-known/agent-card.json`
2. Deploy a2a-ui pointing at CTO's A2A endpoint
3. John accesses via web browser on phone/desktop
4. Optionally keep Telegram as a secondary frontend

## For Clone-Test-Replace
Each CTO instance gets its own A2A endpoint (IP:port). No shared bot accounts. No BotFather dependency. Cloning just means a new VPS with a new A2A endpoint.

## Sources
- [A2A GitHub](https://github.com/a2aproject/A2A)
- [A2A Specification](https://a2a-protocol.org/latest/specification/)
- [a2a-ui](https://github.com/a2anet/a2a-ui)
- [A2UI](https://github.com/google/A2UI)
- [AG-UI](https://github.com/ag-ui-protocol/ag-ui)
- [Linux Foundation AAIF](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project)
