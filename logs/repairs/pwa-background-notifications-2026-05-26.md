# PWA background notifications — 2026-05-26

## Problem
John reported that the PWA only works when foregrounded, making it too easy to miss CTO replies while context-switching. BACKLOG-014 tracks this as P1.

## Change
Agent replies now go through a shared `append_agent_reply()` path that persists chat output and triggers best-effort Web Push delivery to saved browser subscriptions. Push payloads are short notification-safe summaries with sender labels and correlation tags. Missing VAPID keys, no subscriptions, or missing `pywebpush` degrade to no-op so chat delivery remains canonical in `chat.db`. Stale 404/410 subscriptions are removed. The detached PWA job runner now uses the same notification path for terminal background-job replies.

The service-worker shell cache was bumped so the browser refreshes the updated shell assets.

## Verification
- `python3 -m py_compile services/pwa/backend/server.py services/pwa/backend/job_runner.py`
- `python3 -m unittest tests/test_pwa_routing.py`

## Remaining follow-up
Live push delivery still depends on valid VAPID keys, browser permission, and `pywebpush` being present in the PWA runtime environment. If that dependency is missing in production, this commit fails closed to chat-only delivery rather than losing messages.
