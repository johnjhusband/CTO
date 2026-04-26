# Communication Module
**L0:** Telegram Bot primary (free, no phone, zero ban risk). Gmail SMTP fallback. WhatsApp deferred.
**L1:** Telegram Bot API is primary — free, instant setup via @BotFather, zero ban risk, rich formatting, designed for automation. OpenClaw has Telegram built in. Gmail SMTP as fallback (100 emails/day free). WhatsApp deferred: Baileys needs physical phone + ban risk, Business API needs Meta verification. CTO operates autonomously — sends daily digest and immediate alerts, John reviews after the fact.
**Last updated:** 2026-04-26
**Verification:** Telegram verified (token works, bot exists). Gmail SMTP unverified. WhatsApp ban risk claims from research, not independently confirmed.
**Source:** Live web research (April 2026). Audit-corrected April 26.

## Key Facts
- Telegram Bot API is the primary channel — free, no phone needed, zero ban risk, designed for automation
- WhatsApp deferred — requires physical phone for initial pairing (Baileys) or Meta business verification (Business API)
- Gmail SMTP as email fallback

## Primary: Telegram Bot
- Free, zero ongoing cost
- No phone needed at any point — set up via @BotFather in 3 minutes
- Official Bot API designed for automation (not a hack like Baileys)
- Zero ban risk
- Rich formatting (Markdown/HTML), file attachments, inline keyboards
- 30 messages/second rate limit
- Bot can message John proactively (daily reports, alerts)
- Simple HTTP API: `curl "https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<ID>&text=Hello"`
- OpenClaw has Telegram built in as a supported channel

### Setup
1. John messages @BotFather on Telegram: `/newbot`
2. Choose name and username
3. Receive bot token
4. Configure in OpenClaw: `channels.telegram.enabled: true` with bot token
5. John starts a chat with the bot — done

## Fallback: Gmail SMTP
- 100 emails/day via SMTP (free Gmail)
- Uses existing Gmail account + App Password
- For daily summary emails or when Telegram is down

## WhatsApp — Deferred
Evaluated three paths:
- **Baileys (OpenClaw built-in):** Free but requires one-time QR scan from physical phone. Ban risk.
- **WhatsApp Business API:** No phone needed but requires Meta business verification (days) and per-message costs ($0.004-0.14/msg).
- **Decision:** Neither path justified for v1. Telegram does everything needed with zero friction.

May revisit if WhatsApp Business API simplifies or if CTO determines a switch is warranted (macro evolution decision).

## Relationships
- [Architecture](architecture.md) — comms module is a core component
- [Decision Log Format](decision-log-format.md) — decisions are reported via this channel

## Sources
- [Telegram Bot API](https://core.telegram.org/bots/faq)
- [OpenClaw WhatsApp Docs](https://docs.openclaw.ai/channels/whatsapp)
- [Gmail SMTP limits](https://support.google.com/mail/answer/22839)
