# Tools & Conventions

- **VPS:** Hetzner 178.104.213.9 (8 vCPU, 16 GB RAM, 150 GB disk), SSH via cto-deploy key
- **Git:** github.com/johnjhusband/CTO (private repo)
- **LLM:** OpenRouter (multi-model, single API key)
- **Communication:** Telegram Bot (primary), Gmail SMTP (fallback)
- **Knowledge base:** wiki/ directory indexed for Tier 3 search
- **Decision logs:** logs/decisions/ as JSON per decision-log-format wiki page
- **Skills:** skills/ directory, lazy-loaded on demand
- **Version tags:** v{x.y.z} for active, v{x.y.z}-archived-{date} for replaced
- **Upgrade testing:** Fresh Hetzner VPS via API, never Docker, never in-place
