# PWA visible feature panel

Timestamp: 2026-05-27T02:45Z

John reported that PWA feature requests were not visible from his perspective. Treating invisible UI as not done, the PWA shell was updated to surface the requested features directly on the main screen:

- Background alerts: Enable/Test push button.
- Agent coordination: visible toggle for OpenClaw ↔ Hermes traffic.
- Chat history: direct link to durable transcript view.
- Voice: visible control for read-aloud mode.
- Update app: topbar button to refresh service-worker cache and reload the latest PWA shell.

Service worker cache bumped from cto-shell-v8 to cto-shell-v9 so installed PWAs fetch the new shell on reload/update.

Verification:
- Python backend compile passed.
- Static feature checks passed for index.html, app.js, style.css, and service-worker.js.
- cto-pwa-backend.service restarted and is active.

Note: local HTTP content fetch is protected by Secure/HttpOnly cookie auth and cannot fully simulate the installed HTTPS PWA shell without the browser session; final UX confirmation needs John to tap "Update app" or reload the PWA.
