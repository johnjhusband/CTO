# PWA scroll regression test

Timestamp: 2026-05-27T11:50Z

John asked whether PWA fixes were being tested or just coded. The honest answer for the scroll hotfix was: static/server checks only, not an actual phone-browser interaction test.

Added a stdlib unittest regression covering the scroll-critical layout invariants:
- body remains a bounded flex column with `min-height: 0`.
- `#messages` is the shrinking scroll container with touch scrolling enabled.
- mobile feature panel and summary have viewport caps so they cannot consume the whole screen.
- visible PWA feature controls remain present.
- service-worker cache bump remains present.

Verification run:
- `python3 -m unittest tests.test_pwa_layout tests.test_pwa_voice_ui tests.test_pwa_routing` passed.
- `python3 -m py_compile services/pwa/backend/server.py services/pwa/backend/job_runner.py` passed.

Limit: this still is not a real iPhone/Safari gesture test. It is a regression gate to catch the exact flex/overflow bug class before shipping CSS changes.
