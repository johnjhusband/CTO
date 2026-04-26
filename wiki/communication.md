# Communication Module
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026) — all data verified via web search

## Key Facts
- User prefers WhatsApp but official WhatsApp APIs are overkill for one person
- Unofficial WhatsApp libraries (Baileys, WAHA) carry high ban risk in 2026
- Telegram Bot API is the clear winner for primary notifications
- Multiple fallback channels available at zero cost

## Channel Comparison (Verified April 2026)

| Channel | Cost | Setup | Reliability | Ban Risk | Best For |
|---------|------|-------|-------------|----------|----------|
| **Telegram Bot** | Free | 5-10 min | Excellent | None | **Primary channel** |
| **ntfy (self-hosted)** | Free | 10 min | Excellent | None | Supplementary push |
| **Discord Webhook** | Free | 5 min | Excellent | None | Rich report logging |
| **Gmail SMTP** | Free | 15-30 min | Good | Low | Email fallback |
| **Pushover** | $5 one-time | 10 min | Excellent | None | Mobile push fallback |
| WhatsApp Business API | $30-100/mo + per-msg | Days-weeks | Excellent | None | Overkill |
| Twilio WhatsApp | Same + $0.005/msg | Days-weeks | Excellent | None | Overkill |
| Baileys/WAHA/Evolution | Free | 30 min | Good | **HIGH** | **DO NOT USE on personal #** |
| Green API (alt mode) | Free tier | Minutes | Good | **HIGH** | Risky |
| CallMeBot | Free | 5 min | Poor | Low | Not recommended |

## Recommendation: Tiered Approach

### Phase 1 (v1 — get it working)
**Telegram Bot API** — free, instant setup, zero ban risk
- Message @BotFather → `/newbot` → get token → done
- Send via HTTP: `curl "https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<ID>&text=Hello"`
- Rich formatting (Markdown/HTML), file attachments, inline keyboards
- 30 messages/second rate limit (more than enough)
- John installs Telegram on phone for push notifications

### Phase 1 supplement
**Gmail SMTP** — fallback for daily summary emails
- 100 emails/day via SMTP (free Gmail)
- Uses existing Gmail account + App Password
- Risk: Google may block VPS IP initially

### Phase 2 (optional enhancements)
- **ntfy** — self-hosted push notifications on same Hetzner VPS, Docker container, zero cost
- **Discord webhook** — persistent searchable log of all CTO reports with rich embeds

### WhatsApp — Deferred
Official WhatsApp requires Meta Business Manager verification, template approvals, BSP fees ($30-100/mo). Unofficial libraries (Baileys) have HIGH ban risk in 2026 — users report bots that ran 3+ years suddenly banned. Not worth risking personal WhatsApp number. Revisit if official API simplifies or if CTO gets a dedicated number.

## Relationships
- [Architecture](architecture.md) — comms module is a core component
- [Decision Log Format](decision-log-format.md) — decisions are reported via this channel

## Sources
- [Telegram Bot API](https://core.telegram.org/bots/faq)
- [Baileys ban reports](https://github.com/WhiskeySockets/Baileys/issues/1869)
- [Meta WhatsApp pricing](https://business.whatsapp.com/products/platform-pricing)
- [ntfy.sh](https://ntfy.sh/)
- [Gmail SMTP limits](https://support.google.com/mail/answer/22839)
