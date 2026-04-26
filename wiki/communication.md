# Communication Module
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026). Audit-corrected April 26.

## Key Facts
- User prefers WhatsApp — this is the primary channel
- OpenClaw has WhatsApp built in via Baileys (unofficial WhatsApp Web protocol)
- Ban risk exists but is manageable with low volume and dedicated number
- Telegram and Gmail SMTP as fallbacks

## Channel Comparison (Verified April 2026)

| Channel | Cost | Setup | Reliability | Ban Risk | Best For |
|---------|------|-------|-------------|----------|----------|
| **WhatsApp (via OpenClaw)** | Free | 10 min (QR scan) | Good | Moderate | **Primary — user preference** |
| **Telegram Bot** | Free | 5-10 min | Excellent | None | Fallback |
| **Gmail SMTP** | Free | 15-30 min | Good | Low | Email fallback |
| **Discord Webhook** | Free | 5 min | Excellent | None | Rich report logging |
| WhatsApp Business API | $30-100/mo + per-msg | Days-weeks | Excellent | None | Overkill for one person |
| Baileys/WAHA standalone | Free | 30 min | Good | **HIGH** | Redundant — OpenClaw handles this |

## Recommendation

### Primary: WhatsApp via OpenClaw
OpenClaw has WhatsApp built in using the Baileys library (reverse-engineered WhatsApp Web protocol). Setup:
1. Configure in `openclaw.json`: `channels.whatsapp.enabled: true`
2. Set `dmPolicy: "allowlist"` and add John's number to `allowFrom`
3. Run `openclaw channels login` and scan QR code with WhatsApp
4. Phone must stay online; session unlinks after ~14 days offline

**Ban risk mitigation:**
- Use a **dedicated SIM/number** for CTO, not John's personal WhatsApp
- Low message volume (1-2 daily reports) keeps risk minimal
- OpenClaw has built-in rate limiting
- If banned, Telegram fallback is instant

### Fallback: Telegram Bot
- Free, zero ban risk, 5-minute setup via @BotFather
- Already supported by OpenClaw
- Activates automatically if WhatsApp fails

### Fallback: Gmail SMTP
- 100 emails/day via SMTP (free Gmail)
- Uses existing Gmail account + App Password
- For daily summary emails or when messaging channels are down

## Relationships
- [Architecture](architecture.md) — comms module is a core component
- [Decision Log Format](decision-log-format.md) — decisions are reported via this channel

## Sources
- [OpenClaw WhatsApp Docs](https://docs.openclaw.ai/channels/whatsapp)
- [Baileys ban reports](https://github.com/WhiskeySockets/Baileys/issues/1869)
- [Telegram Bot API](https://core.telegram.org/bots/faq)
- [Gmail SMTP limits](https://support.google.com/mail/answer/22839)
