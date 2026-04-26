# Research Sources
**Last updated:** 2026-04-26
**Source:** Live web research (April 2026) — all data verified via web search

## Key Facts
- YouTube transcripts are the **primary** research source
- `youtube-transcript-api` Python library is the best extraction method (free, reliable, 3 lines of code)
- yt-dlp reliability has degraded due to YouTube anti-bot protections in 2026
- YouTube Data API v3 cannot extract public video transcripts (only your own videos)
- Gemini API can process YouTube URLs directly (audio/video) as a powerful fallback

## Recommended Transcript Pipeline

### Primary: youtube-transcript-api → Gemini Flash summarization
1. Discover new videos via YouTube Data API v3 metadata (1 unit/call)
2. Extract transcripts with `youtube-transcript-api` (free, no auth, ~60-100 req/min)
3. Summarize/analyze with Gemini 2.5 Flash ($0.30/M input tokens)

### Fallback chain:
- If youtube-transcript-api fails → try yt-dlp with `--write-auto-subs --skip-download`
- If no captions exist → send YouTube URL to Gemini API for multimodal transcription (8hrs/day limit)
- Nuclear option → download audio with yt-dlp, transcribe with Whisper locally

## Transcript Extraction Methods (Verified)

| Method | Reliability | Rate Limits | Cost | Auth Required | Best For |
|--------|-------------|-------------|------|---------------|----------|
| **youtube-transcript-api** | HIGH | ~60-100 req/min | Free | None | Primary source |
| **Gemini API (URL)** | HIGH | 250 RPD free | $0.30/M tokens | API key | No-caption videos |
| **yt-dlp** | DEGRADED | ~300/hr guest | Free | Cookies optional | Fallback |
| **Supadata** | HIGH | Per plan | 100 free/mo | API key | AI fallback |
| **YouTube Data API v3** | N/A for transcripts | 50 captions/day | Free | OAuth (own only) | Metadata only |
| **Whisper** | GOOD (8-12% WER) | Self-hosted: none | Free local / $0.006/min API | None/key | Last resort |

## YouTube Premium Value
Marginal for this use case. Main benefit: higher yt-dlp rate limits with exported cookies (~7x). But youtube-transcript-api doesn't support cookie auth currently. Premium does NOT help with YouTube Data API or Gemini API.

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

### Tier 4: Official/Enterprise
| Channel | Focus |
|---------|-------|
| **Google Cloud Tech** | Vertex AI, ML pipelines |
| **NVIDIA Developer** | GPUs, frameworks |

## Secondary Research Sources
| Source | Method | Why |
|--------|--------|-----|
| GitHub Trending | API/scraping | New tools, frameworks, libraries |
| GitHub Releases | Watch key repos | Version updates to tools CTO uses |
| Hacker News | API | Community signal on what matters |
| Product changelogs | Web scraping | Anthropic, OpenAI, Google official updates |
| AI newsletters | Email/web | Curated weekly digests |
| arxiv | API | Research papers (lower priority) |

## Relationships
- [Architecture](architecture.md) — how research fits into the system
- [Decision Log Format](decision-log-format.md) — how research findings become decisions

## Sources
- [youtube-transcript-api PyPI](https://pypi.org/project/youtube-transcript-api/)
- [Gemini video understanding](https://ai.google.dev/gemini-api/docs/video-understanding)
- [yt-dlp GitHub](https://github.com/yt-dlp/yt-dlp)
- [YouTube Data API quota](https://developers.google.com/youtube/v3/determine_quota_cost)
- [Best AI YouTube channels 2026](https://ryandoser.com/ai-youtube-channels/)
