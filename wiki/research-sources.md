# Research Sources
**L0:** YouTube (browser-based for v1), GitHub Trending, HN, arXiv, HuggingFace, changelogs. LLM scoring for relevance. 15+ AI YouTube channels identified.
**L1:** Primary sources ranked by signal quality: arXiv (highest for research), GitHub Trending (highest for tools), HN via Algolia API (community pre-filtered), Twitter/X (breaking news, noisy), HuggingFace (models/papers), Reddit r/MachineLearning, YouTube AI channels (browser-based for v1, transcript APIs later). Tier 1 YouTube: Matt Wolfe, Matthew Berman, AI Explained, The AI Grid, Wes Roth. v1 uses browser interaction — no separate API keys. CTO can evaluate switching to youtube-transcript-api or Horizon as a macro evolution decision.
**Last updated:** 2026-04-26
**Verification:** YouTube channel list from research. Source quality rankings are subjective assessments from research agents. Channel existence not independently verified.
**Source:** Live web research (April 2026). Audit-corrected April 26.

## Key Facts
- YouTube is the **primary** research source — humans digest AI news well
- v1 uses **browser-based YouTube interaction** via OpenClaw skills/MCPs (no separate API keys)
- Alternative transcript methods (youtube-transcript-api, yt-dlp) documented for future optimization
- Multiple secondary sources for breadth

## v1 YouTube Pipeline: Browser-Based

For v1, CTO interacts with YouTube through the browser via OpenClaw's browser automation skills/MCPs. This avoids:
- Separate API key provisioning (YouTube Data API, Gemini)
- Rate limit complexity
- Dependency on third-party Python libraries that may break

CTO can browse YouTube, read transcripts (YouTube provides them in the UI), and summarize content using its LLM. Simple, no extra infrastructure.

### Future Optimization (post-v1)
Once the foundation is working, CTO can evaluate whether to adopt:
- `youtube-transcript-api` Python library (free, reliable, 3 lines of code)
- YouTube Data API v3 for video discovery (free tier, 10K units/day)
- yt-dlp for batch transcript downloads (degraded reliability in 2026)
- Gemini API for multimodal YouTube processing

This is exactly the kind of macro evolution decision CTO should make for itself.

## AI YouTube Channels to Monitor

### Tier 1: Daily AI News & Tool Tracking
| Channel | Focus |
|---------|-------|
| **Matt Wolfe** | AI tools, launches, weekly roundups. Created FutureTools.io |
| **Matthew Berman** | LLMs, open-source models, 5-6 videos/week |
| **AI Explained** | Deep analysis of GPT-5, Claude, Gemini, Sora |
| **The AI Grid** | In-depth software demos |
| **Wes Roth** | Business-centric AI analysis |

### Tier 2: AI Coding & Frameworks
| Channel | Focus |
|---------|-------|
| **Corbin Brown** | AI coding tutorials (Claude, Cursor) |
| **Developers Digest** | AI APIs, frameworks, tutorials |
| **Sentdex** | ML projects, build walkthroughs |
| **Nate (Uppit AI)** | AI automation, n8n integrations |

### Tier 3: Research & Deep Dives
| Channel | Focus |
|---------|-------|
| **Yannic Kilcher** | ML paper analysis |
| **Two Minute Papers** | Bite-sized research breakdowns |
| **DeepLearning.AI** | Courses, MLOps, GenAI |

## Secondary Research Sources
| Source | Method | Why |
|--------|--------|-----|
| GitHub Trending | Browser/API | New tools, frameworks, libraries |
| GitHub Releases | Watch key repos | Version updates to tools CTO uses |
| Hacker News | API/browser | Community signal on what matters |
| Product changelogs | Browser | Anthropic, OpenAI, Google official updates |
| AI newsletters | Email/web | Curated weekly digests |
| arxiv | API/browser | Research papers (lower priority) |

## Relationships
- [Architecture](architecture.md) — how research fits into the system
- [Decision Log Format](decision-log-format.md) — how research findings become decisions
