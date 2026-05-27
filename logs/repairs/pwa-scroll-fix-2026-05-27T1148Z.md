# PWA scroll fix

Timestamp: 2026-05-27T11:48Z

John reported scrolling on the PWA did not work after the visible feature panel changes.

Fix:
- Added `min-height: 0` to the flex layout so the chat message pane can actually shrink and scroll inside the viewport.
- Made `#messages` a real touch scroll container with `-webkit-overflow-scrolling: touch`, `overscroll-behavior: contain`, and `touch-action: pan-y`.
- Limited the mobile feature panel and feature summary heights so they cannot consume the whole viewport and block chat scrolling.
- Bumped service-worker shell cache to `cto-shell-v20` so the installed PWA updates.

Verification:
- Static CSS checks passed for the scrolling rules and cache bump.
- `cto-pwa-backend.service` restarted and is active.

Final confirmation requires John testing on the installed phone PWA because the bug is touch/viewport specific.
