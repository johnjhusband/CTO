# OpenClaw + ChatGPT Pro via Codex OAuth
**L0:** ChatGPT Pro $200/mo works with OpenClaw via Codex OAuth. Headless VPS uses device-code flow. Must enable Device Code Authorization in ChatGPT settings first. Embeddings not included — need separate OPENAI_API_KEY.
**L1:** OpenAI explicitly allows subscription access through OpenClaw. Use `openai-codex` provider, authenticate via device-code flow on headless VPS (v2026.4.22+). Pro $200 = 20x Plus limits. Embeddings require separate API key. Known bugs: store:true rejection, stale OAuth profiles.
**Last updated:** 2026-05-03
**Verification:** All verified against OpenClaw docs, GitHub issues, and community guides.

## Prerequisites
1. ChatGPT Pro subscription ($200/mo or $100/mo) — created manually at chatgpt.com/pricing [verified — no programmatic creation possible]
2. Enable **Device Code Authorization** in ChatGPT Security Settings [verified — required for headless VPS]
3. OpenClaw v2026.4.22+ [verified — device-code flow added in this version]

## Configuration

### openclaw.json
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.5"
      }
    }
  }
}
```

### Authentication (Headless VPS)
```bash
# Device-code flow — no browser on VPS needed
openclaw models auth login --provider openai-codex --device-code
# Shows URL + one-time code
# Open URL on any device, enter code, approve
```

### Full Setup Sequence
```bash
openclaw models auth login --provider openai-codex --device-code
openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5
openclaw gateway restart
openclaw models status
```

## Available Models
- `gpt-5.5` (latest, 160K context)
- `gpt-5.4` / `gpt-5.4-mini`
- `gpt-5.3-codex` (legacy, battle-tested with OAuth)
- `gpt-5.2`

## Rate Limits
| Tier | Cost | Codex Quota |
|------|------|-------------|
| Plus | $20/mo | 5-hour weekly cap |
| Pro $100 | $100/mo | 5x Plus (10x through May 31 promo) |
| Pro $200 | $200/mo | 20x Plus (25x through May 31 promo) |

Subscription limits feel tighter than ChatGPT web experience [verified — GitHub issue #61666].

## Embeddings — Critical
Codex subscription does NOT include embeddings. Set `OPENAI_API_KEY` in `~/.openclaw/.env` separately for `text-embeddings-3` access. Costs pennies. Without this, memory search indexing fails.

## Known Bugs [verified against GitHub issues]
1. `store: true` rejection (#67740) — Codex OAuth endpoint rejects it
2. `gpt-5.3-codex` hard-routed to OAuth (#30844) — breaks API-key users
3. Tools stop executing after update (#53959) — regression, fixed in later releases
4. OAuth token refresh — tokens refresh automatically during use but expired sessions need manual re-auth
5. Stale OAuth profiles — run `openclaw doctor --fix` to clean up

## Fallback Configuration
```bash
# Add fallback in case subscription quota is hit
openclaw models fallbacks add openrouter/google/gemini-3-flash-preview
```

## Sources
- [OpenClaw OpenAI Provider Docs](https://docs.openclaw.ai/providers/openai)
- [LumaDock Tutorial](https://lumadock.com/tutorials/openclaw-openai-codex-chatgpt-subscription)
- [OpenClaw Release 2026.4.22](https://github.com/openclaw/openclaw/releases/tag/v2026.4.22)
- [OpenAI Codex Auth Docs](https://developers.openai.com/codex/auth)
