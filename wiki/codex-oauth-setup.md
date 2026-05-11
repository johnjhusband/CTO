# OpenClaw + Hermes + Codex OAuth (Business or Pro)
**L0:** ChatGPT **Business** ($30/seat — what John has) AND Pro ($200/mo) both work with OpenClaw and Hermes via Codex OAuth. Headless VPS uses device-code flow. For Business: enable BOTH "Allow members to use Codex Local" AND "Enable device code authentication for Codex CLI" in workspace admin at chatgpt.com/admin/settings. Embeddings not included — need separate OPENAI_API_KEY.
**L1:** Per CTO-DECISION-008 (2026-05-11), primary is John's existing **Business standard seat** at $30/month — Pro on a separate email is the escape if observed Business Codex quotas constrain operation. OpenAI explicitly allows subscription access through OpenClaw and Hermes — use `openai-codex` provider, authenticate via device-code flow on headless VPS. Business and Pro both support the same auth path; quota tiers differ. Documented Business Codex 5-hour quotas: GPT-5.4-mini 1,200-7,000 local msgs / 5h; GPT-5.3-Codex 600-3,000 local + 200-1,200 cloud / 5h; GPT-5.4 400-2,000 / 5h. Pro $200 = 20× Plus equivalent (typically higher than Business). Known bugs: store:true rejection, stale OAuth profiles. **No PAYG Codex seats** per John's no-accidental-overspend policy.
**Last updated:** 2026-05-11
**Verification:** Business quotas verified at OpenAI Codex rate card 2026-05-11. Both hemispheres' provider support verified at primary docs (docs.openclaw.ai/providers/openai, hermes-agent.nousresearch.com/docs/integrations/providers).

## Prerequisites (Business plan — what John has)
1. **ChatGPT Business** subscription — $30/seat/month [John already pays this — CTO-DECISION-008]
2. **Workspace admin toggles** — both must be ON at https://chatgpt.com/admin/settings → Settings and Permissions:
   - "Allow members to use Codex Local"
   - "Enable device code authentication for Codex CLI"
   - Wait up to 10 minutes after enabling for propagation [verified — OpenAI Codex Admin Setup docs]
3. OpenClaw v2026.4.22+ [verified — device-code flow added in this version]
4. Hermes Agent v0.13.0+ (for `openai-codex` provider support) [verified — Hermes providers docs]

## Prerequisites (Pro plan — future escape path, on a separate email)
1. ChatGPT Pro subscription ($200/mo) — created manually at chatgpt.com/pricing **on a different email from the Business workspace** (Pro and Business cannot coexist on one email if no Personal workspace exists)
2. Enable **Device Code Authorization** in ChatGPT Security Settings (individual user-level setting; not the Business workspace toggle)
3. OpenClaw v2026.4.22+, Hermes v0.13.0+

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
