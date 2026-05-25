# OpenClaw + Hermes + Codex OAuth (Pro — dedicated cto@husband.llc account)
**L0:** Primary auth as of 2026-05-24 is **ChatGPT Pro on `cto@husband.llc`** (dedicated, separate from John's personal Business workspace). Headless VPS uses device-code flow. Enable **Device Code Authorization** in cto@husband.llc Security Settings before running `codex login --device-auth`. Embeddings not included — need separate OPENAI_API_KEY.
**L1:** Per CTO-DECISION-013 (2026-05-24), the auth account is the dedicated Pro subscription on `cto@husband.llc`. This exercises the documented Pro-escape clause from CTO-DECISION-008. Pro $200 ≈ 20× Plus quota — significantly above Business standard-seat quotas. OpenAI explicitly allows subscription access through OpenClaw and Hermes via `openai-codex` provider. Known bugs to watch: store:true rejection, stale OAuth profiles. **No PAYG Codex seats** per John's no-accidental-overspend policy.
**Last updated:** 2026-05-24
**Verification:** Both hemispheres' provider support verified at primary docs (docs.openclaw.ai/providers/openai, hermes-agent.nousresearch.com/docs/integrations/providers). Pro device-code-auth toggle path verified in OpenAI account UI 2026-05-24.

## Prerequisites (Pro plan on `cto@husband.llc` — PRIMARY)
1. **ChatGPT Pro subscription** on `cto@husband.llc` ($200/mo) — created by John 2026-05-24 [CTO-DECISION-013]
2. Enable **Device Code Authorization** in `cto@husband.llc` Security Settings (https://chatgpt.com → signed in as cto@husband.llc → Settings → Security → Device Code Authorization toggle ON). This is an individual user-level setting, NOT a workspace toggle. Without it, `codex login --device-auth` returns an authorization error.
3. OpenClaw v2026.4.22+ [verified — device-code flow added in this version]
4. Hermes Agent v0.13.0+ (for `openai-codex` provider support) [verified — Hermes providers docs]

## Prerequisites (Business plan on `john@husband.llc` — RETIRED for CTO use)
John retains this seat for his personal use. Kept here for the rollback path. To rollback: restore `~/.codex/auth.json.bak-john-business-*` on cto-vps; no other changes needed since the OAuth mechanism is identical.
1. ChatGPT Business — $30/seat/month
2. Workspace admin toggles at https://chatgpt.com/admin/settings → Settings and Permissions: both "Allow members to use Codex Local" and "Enable device code authentication for Codex CLI" ON
3. OpenClaw v2026.4.22+, Hermes v0.13.0+

## Authentication Flow (Headless VPS — verified 2026-05-11)

**Strategy: ONE device-code approval via upstream Codex CLI, then both hemispheres consume the same auth state.** This avoids OpenClaw issue #74212 (fixed in v2026.5.6 but defence in depth) where the device code wasn't surfaced over SSH, and minimises phone interactions.

```bash
# 1) ONE device-code flow via upstream Codex CLI
codex login --device-auth
# Prints URL + 8-char code. John opens URL signed in as cto@husband.llc, enters code, clicks Authorize.
# Result: ~/.codex/auth.json populated with the cto@husband.llc Pro tokens.

# 2) Verify the token landed
jq '{auth_mode, last_refresh, has_access_token: ((.tokens.access_token // "") != "")}' ~/.codex/auth.json

# 3) Register profile with OpenClaw (reuses ~/.codex/auth.json on v2026.5.6+)
openclaw models auth login --provider openai-codex --device-code
# If OpenClaw still asks for a code, approve the SECOND code.

# 4) Register profile with Hermes (auto-imports ~/.codex/auth.json)
hermes model add openai-codex --device-code  # or interactive: hermes model

# 5) Configure both halves to use the codex model
openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5
hermes config set model openai-codex/gpt-5.5

# 6) Restart and verify
openclaw gateway restart
openclaw models status
```

### Token auto-refresh — quoted from OpenAI Codex CI/CD auth docs
- "Codex refreshes tokens automatically during use before they expire, so active sessions usually continue without requiring another browser login."
- "If `last_refresh` is older than about 8 days, Codex refreshes the token bundle before the run continues, and after a successful refresh, Codex writes the new tokens and a new `last_refresh` back to `auth.json`."
- "If a request gets a 401, Codex also has a built-in refresh-and-retry path."

No manual re-auth needed during normal operation. The token bundle includes refresh tokens used silently.

### To revoke (if VPS is ever compromised)
`chatgpt.com` → Settings → Security → Connected Devices / Active Sessions → find the Codex CLI, OpenClaw, or Hermes entry → Revoke. CTO loses access on the next refresh attempt (typically within minutes).

### openclaw.json model config
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
