# Assumption Audit — All Documents
**L0:** Systematic check of every assumption in every document. Status: IN PROGRESS.
**L1:** Going through PRD, beads, README, SOUL.md, AGENTS.md, HANDOFF.md, and all wiki pages to identify every assumption that was treated as fact. Each tagged [verified], [wrong], or [unverified].
**Last updated:** 2026-04-26
**Source:** Hands-on testing + primary source verification

## API Keys & Services
| Assumption | Status | Evidence |
|-----------|--------|----------|
| OpenRouter API key works | [verified] | HTTP 200 on /v1/models |
| OpenRouter model ID format: provider/model | [verified] | anthropic/claude-sonnet-4 returned in model list |
| OpenRouter free credits cover Claude Sonnet | [wrong] | $1 free insufficient — needs more credits for paid models |
| OpenRouter is prepaid | [verified] | Error message confirms credit-based billing |
| Telegram bot token works | [verified] | getMe returns bot name "CTO", username "HusbandCTObot" |
| Telegram proactive messaging works | [verified-with-caveat] | Fails with "chat not found" until John messages bot first — documented bug confirmed |
| Hetzner API token works | [verified] | Returns our server list (CTO cx43) |
| Hetzner can create servers via API | [verified] | Created and deleted test server successfully |
| Hetzner SSH key must be uploaded via API | [verified] | Server creation failed until key was uploaded |
| OpenAI API key works | [verified] | HTTP 200 on /v1/models |

## Packages & Tools
| Assumption | Status | Evidence |
|-----------|--------|----------|
| openclaw npm package exists | [verified] | v2026.4.24 on npm |
| @bitbonsai/mcpvault exists | [verified] | v0.11.0 on npm |
| @modelcontextprotocol/server-filesystem exists | [verified] | v2026.1.14 on npm |
| @brave/brave-search-mcp-server exists | [verified] | v2.0.80 on npm |
| @lazyants/hetzner-mcp-server exists | [verified] | v1.1.0 on npm |
| mcp-server-fetch exists on PyPI | [verified] | v2025.4.7 |
| github-mcp-server repo exists | [verified] | HTTP 302 (redirect to latest release) |
| memweave exists on PyPI | [verified] | v0.2.0 |
| memweave FTS-only works without API key | [wrong] | No built-in FTS strategy — only hybrid, which requires embeddings |
| memweave hybrid search works with OpenAI key | [verified-with-caveat] | Works but scores very low (0.14 max), search quality is poor, needs tuning |
| MCPVault search works | [verified] | Returns ranked results by match count |

## VPS State
| Assumption | Status | Evidence |
|-----------|--------|----------|
| VPS is cx33 with 8GB RAM | [wrong] | Actually cx43 (8 vCPU, 16GB RAM) |
| Node.js 22 available to cto user | [verified] | Was broken (nvm under root only), now fixed |
| Python 3.12 on VPS | [verified] | python3 --version = 3.12.3 |
| pip available on VPS | [verified] | pip 24.0 |
| venv available on VPS | [verified] | python3 -m venv works |
| Port 18789 free on VPS | [verified] | ss -tlnp shows no listener |
| ufw installed on VPS | [verified] | /usr/sbin/ufw exists |
| fail2ban installed | [wrong] | Not installed |

## OpenClaw Behavior (verified against official docs)
| Assumption | Status | Evidence |
|-----------|--------|----------|
| Auto-loads SOUL.md every session | [verified] | docs.openclaw.ai/concepts/system-prompt |
| Auto-loads AGENTS.md every session | [verified] | docs.openclaw.ai/concepts/system-prompt |
| Auto-loads IDENTITY.md every session | [verified] | docs.openclaw.ai/concepts/system-prompt |
| Auto-loads USER.md every session | [verified] | docs.openclaw.ai/concepts/system-prompt |
| Auto-loads TOOLS.md every session | [verified] | docs.openclaw.ai/concepts/system-prompt |
| Auto-loads MEMORY.md every session | [verified-with-caveat] | Main private session only, not shared/group |
| --skip-bootstrap prevents file overwrite | [verified] | Skips all 7 default files |
| --auth-choice "openrouter-api-key" workaround | [verified in source code] | `choiceId: "openrouter-api-key"` confirmed in extensions/openrouter/openclaw.plugin.json. Issue #17191 never recommended it but source code validates it. Not tested end-to-end. |
| Heartbeat reads HEARTBEAT.md every 30 min | [verified-with-caveat] | 30m default, 1h for Anthropic OAuth auth |
| memorySearch.extraPaths indexes wiki | [verified] | Config key is real. "Tier 3" label is fabricated — OpenClaw doesn't use that term. |
| Skills lazy-loaded from workspace/skills/ | [wrong] | Skills are eagerly snapshot-loaded at session start, injected into system prompt |
| Cron jobs persist across restarts | [verified] | Stored in ~/.openclaw/cron/jobs.json |
| gateway.bind: "loopback" works | [verified] | Default, binds to 127.0.0.1 |
| Telegram config keys correct | [verified] | botToken, dmPolicy, allowFrom confirmed. allowFrom uses "tg:ID" format. |
| Model format openrouter/provider/model | [verified] | Format confirmed, specific model IDs need checking against OpenRouter catalog |
| openclaw message send command exists | [verified] | --channel, --target, --message flags confirmed |
| Schema validation rejects unknown keys | [verified] | Gateway refuses to start. openclaw doctor --fix strips unknown keys. |
| SearXNG works as OpenClaw web search | [verified] | Official built-in provider, uses JSON API, no API key needed |
| MCP config key is mcpServers | [wrong] | Actual key is mcp.servers (nested) |
| SearXNG one-liner docker command | [wrong] | Missing volume mounts vs official docs |
| MCPVault is OpenClaw-specific integration | [wrong] | Generic MCP server, works with any MCP client |

## Architecture Assumptions
| Assumption | Status | Evidence |
|-----------|--------|----------|
| Five-layer architecture is community consensus | [verified] | Multiple independent sources in research |
| Memory is the #1 agent failure cause | [verified] | Gartner, Databricks, multiple sources |
| MCP has 97M monthly installs | [unverified] | From research, not checked against primary source |
| A2A has 150+ organizations | [unverified] | From research |
| Single agent outperforms multi-agent 64% of time | [unverified] | Princeton NLP claim from research |
| 76% of 847 deployments failed | [unverified] | Medium article, not peer-reviewed |
| Error compounds: 85% per-step = 20% for 10 steps | [verified] | Math: 0.85^10 = 0.197 |
| Obsidian can't run headless | [verified] | Research confirmed, requires GUI/Electron |
| Docker can't test system-level changes | [verified] | Conceptually sound — containers share host kernel |
| Brave needed for web search | [wrong] | OpenClaw has SearXNG, built-in search, and other alternatives |

## PRD-Specific Assumptions
| Assumption | Status | Evidence |
|-----------|--------|----------|
| Clone-test-replace on fresh VPS costs ~EUR 0.05 | [partially verified] | API creation/deletion works. Exact billing not tested. |
| Hetzner bills hourly, stops on DELETE | [awaiting verification] | Research says yes, not confirmed against docs yet |
| Snapshot pricing EUR 0.0143/GB/month | [awaiting verification] | Research agent checking |

## Telegram Configuration Correction
| Our Config | Reality |
|-----------|---------|
| `allowFrom: [123456789]` (bare integer) | Should be `allowFrom: ["tg:123456789"]` (prefixed string) |

This needs to be corrected in openclaw-setup.md.
