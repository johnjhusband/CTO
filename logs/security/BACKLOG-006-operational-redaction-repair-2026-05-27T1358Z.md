# BACKLOG-006 operational redaction repair — 2026-05-27T1358Z

## Scope
Repair the failed non-destructive credential/security gate from 13:50Z by redacting secret-shaped assignment values in operational logs/chat.db. This does not rotate, revoke, print, or expose any credential values.

## Redaction apply
REDACTED chat_db_row=1527 markers=env:PWA_AUTH_TOKEN:1
REDACTED chat_db_row=1529 markers=env:PWA_AUTH_TOKEN:1
REDACTED chat_db_row=1532 markers=env:PWA_AUTH_TOKEN:1
Operational secret redaction redacted 3 marker(s) across 292 file(s) plus chat.db.

## Verification
- `scripts/security/run-safe-security-gates.sh`
== secret artifact guard ==
Secret artifact guard passed: scanned 440 source-visible files.

== operational secret redaction check ==
Operational secret redaction check passed: scanned 292 file(s) plus chat.db; no unredacted markers found.

== install secret-handling guard ==
Install secret-handling guard passed: checked scripts/install.sh metadata only.

== credential rotation preflight syntax ==

== credential rotation smoke syntax ==

== credential rotation preflight (names only) ==
Credential rotation preflight (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Required credential names:
- HETZNER_API_TOKEN: present_nonempty
- GITHUB_TOKEN: present_nonempty
- HERMES_API_SERVER_KEY: present_nonempty
- HERMES_A2A_TOKEN: present_nonempty
- OPENAI_API_KEY: present_nonempty
- PWA_AUTH_TOKEN: present_nonempty

Optional/retired credential names to reconcile during rotation window:
- CTO_EMAIL_SMTP_PASSWORD: present_nonempty
- GOOGLE_ACCOUNT_PASSWORD_PENDING: present_nonempty
- OPENROUTER_API_KEY: present_nonempty

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Recommended coordinated order (names only):
1. Prepare replacement values out of band for all present required names.
2. Update /opt/cto/.env atomically with mode 600 and no shell history echo.
3. Restart dependent user services in a controlled window.
4. Verify PWA auth, Hermes A2A, OpenClaw gateway, embeddings, GitHub, and Hetzner paths.
5. Revoke superseded provider credentials only after verification.
6. Run scripts/security/run-safe-security-gates.sh and record evidence.

Preflight result: ready_for_coordinated_rotation_window

== credential rotation smoke check (no values) ==
Credential rotation smoke check (no secret values printed)
env_file=/opt/cto/.env owner=cto:cto mode=600

Dependent user services:
- openclaw-gateway.service: active
- hermes-gateway.service: active
- cto-hermes-a2a-sidecar.service: active
- cto-pwa-backend.service: active
- cto-a2a-registry.service: active

Local health endpoints:
- openclaw-gateway: ok (27 bytes)
- hermes-gateway: ok (44 bytes)
- hermes-a2a-sidecar: ok (49 bytes)
- pwa-backend: ok (42 bytes)

Smoke result: local_services_healthy

== redaction unit tests ==
test_does_not_report_secret_values_in_counts (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_does_not_report_secret_values_in_counts) ... ok
test_leaves_existing_placeholders_safe (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_leaves_existing_placeholders_safe) ... ok
test_redacts_adjacent_url_query_secret_names (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_adjacent_url_query_secret_names) ... ok
test_redacts_http_auth_headers_and_pwa_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_http_auth_headers_and_pwa_session_cookies) ... ok
test_redacts_legacy_pwa_query_token_values (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_legacy_pwa_query_token_values) ... ok
test_redacts_natural_language_password_pastes (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_natural_language_password_pastes) ... ok
test_redacts_runtime_token_names_missing_from_initial_gate (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_runtime_token_names_missing_from_initial_gate) ... ok
test_redacts_sensitive_http_headers_and_generic_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_sensitive_http_headers_and_generic_session_cookies) ... ok

----------------------------------------------------------------------
Ran 8 tests in 0.001s

OK

== PWA auth/routing regression tests ==
test_access_log_redacts_legacy_query_token (tests.test_pwa_routing.PwaAccessControlTests.test_access_log_redacts_legacy_query_token) ... ok
test_api_query_token_no_longer_authenticates (tests.test_pwa_routing.PwaAccessControlTests.test_api_query_token_no_longer_authenticates) ... ok
test_auth_rejects_bare_url_without_cookie (tests.test_pwa_routing.PwaAccessControlTests.test_auth_rejects_bare_url_without_cookie) ... ok
test_legacy_stream_query_token_204_access_log_is_suppressed (tests.test_pwa_routing.PwaAccessControlTests.test_legacy_stream_query_token_204_access_log_is_suppressed) ... ok
test_legacy_stream_query_token_stops_eventsource_retry_storm (tests.test_pwa_routing.PwaAccessControlTests.test_legacy_stream_query_token_stops_eventsource_retry_storm) ... ok
test_non_production_without_auth_token_is_dev_mode_only (tests.test_pwa_routing.PwaAccessControlTests.test_non_production_without_auth_token_is_dev_mode_only) ... ok
test_previous_pwa_token_alone_does_not_satisfy_production_startup (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_alone_does_not_satisfy_production_startup) ... ok
test_previous_pwa_token_does_not_authenticate_api_query_token (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_does_not_authenticate_api_query_token) ... ok
test_previous_pwa_token_keeps_existing_session_valid_during_rotation (tests.test_pwa_routing.PwaAccessControlTests.test_previous_pwa_token_keeps_existing_session_valid_during_rotation) ... ok
test_production_without_auth_token_fails_closed (tests.test_pwa_routing.PwaAccessControlTests.test_production_without_auth_token_fails_closed) ... ok
test_pwa_shell_is_not_public_when_auth_token_configured (tests.test_pwa_routing.PwaAccessControlTests.test_pwa_shell_is_not_public_when_auth_token_configured) ... ok
test_session_cookie_authenticates (tests.test_pwa_routing.PwaAccessControlTests.test_session_cookie_authenticates) ... ok
test_session_cookie_does_not_store_bearer_token (tests.test_pwa_routing.PwaAccessControlTests.test_session_cookie_does_not_store_bearer_token) ... ok
test_static_file_disconnect_does_not_raise (tests.test_pwa_routing.PwaAccessControlTests.test_static_file_disconnect_does_not_raise) ... ok
test_unauthorized_json_responses_are_no_store (tests.test_pwa_routing.PwaAccessControlTests.test_unauthorized_json_responses_are_no_store) ... ok
test_push_payload_truncates_reply_body (tests.test_pwa_routing.PwaPushNotificationTests.test_push_payload_truncates_reply_body) ... ok
test_push_without_vapid_key_degrades_to_noop (tests.test_pwa_routing.PwaPushNotificationTests.test_push_without_vapid_key_degrades_to_noop) ... ok
test_a2a_audit_sanitizer_redacts_obvious_secrets (tests.test_pwa_routing.PwaRoutingTests.test_a2a_audit_sanitizer_redacts_obvious_secrets) ... ok
test_candidate_chat_connection_creates_parent_directory (tests.test_pwa_routing.PwaRoutingTests.test_candidate_chat_connection_creates_parent_directory) ... ok
test_candidate_clone_allows_isolated_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_candidate_clone_allows_isolated_chat_db) ... ok
test_candidate_clone_rejects_production_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_candidate_clone_rejects_production_chat_db) ... ok
test_chat_append_writes_human_markdown_log_and_skips_a2a_json (tests.test_pwa_routing.PwaRoutingTests.test_chat_append_writes_human_markdown_log_and_skips_a2a_json) ... ok
test_chat_log_helpers_reject_traversal_and_limit_export_range (tests.test_pwa_routing.PwaRoutingTests.test_chat_log_helpers_reject_traversal_and_limit_export_range) ... ok
test_coordinated_both_calls_openclaw_before_hermes (tests.test_pwa_routing.PwaRoutingTests.test_coordinated_both_calls_openclaw_before_hermes) ... ok
test_frontend_has_visible_a2a_coordination_toggle (tests.test_pwa_routing.PwaRoutingTests.test_frontend_has_visible_a2a_coordination_toggle) ... FAIL
test_frontend_resyncs_history_on_foreground (tests.test_pwa_routing.PwaRoutingTests.test_frontend_resyncs_history_on_foreground) ... ok
test_manifest_icons_exist_and_are_cached_by_service_worker (tests.test_pwa_routing.PwaRoutingTests.test_manifest_icons_exist_and_are_cached_by_service_worker) ... FAIL
test_openclaw_session_id_base_override_is_bounded_to_utc_day (tests.test_pwa_routing.PwaRoutingTests.test_openclaw_session_id_base_override_is_bounded_to_utc_day) ... ok
test_openclaw_session_id_is_bounded_to_utc_day (tests.test_pwa_routing.PwaRoutingTests.test_openclaw_session_id_is_bounded_to_utc_day) ... ok
test_parse_mention_mixed_openclaw_and_hermes_becomes_coordinated_both (tests.test_pwa_routing.PwaRoutingTests.test_parse_mention_mixed_openclaw_and_hermes_becomes_coordinated_both) ... ok
test_parse_mention_recognizes_explicit_both (tests.test_pwa_routing.PwaRoutingTests.test_parse_mention_recognizes_explicit_both) ... ok
test_production_allows_production_chat_db (tests.test_pwa_routing.PwaRoutingTests.test_production_allows_production_chat_db) ... ok
test_push_device_status_summary_is_bounded_and_non_secret (tests.test_pwa_routing.PwaRoutingTests.test_push_device_status_summary_is_bounded_and_non_secret) ... ok
test_send_to_hermes_reports_a2a_token_mismatch_actionably (tests.test_pwa_routing.PwaRoutingTests.test_send_to_hermes_reports_a2a_token_mismatch_actionably) ... ok
test_send_to_hermes_writes_visible_sanitized_a2a_audit_rows (tests.test_pwa_routing.PwaRoutingTests.test_send_to_hermes_writes_visible_sanitized_a2a_audit_rows) ... ok
test_stale_chat_worker_watchdog_writes_visible_system_event (tests.test_pwa_routing.PwaRoutingTests.test_stale_chat_worker_watchdog_writes_visible_system_event) ... ok
test_voice_device_status_summary_is_bounded_and_non_secret (tests.test_pwa_routing.PwaRoutingTests.test_voice_device_status_summary_is_bounded_and_non_secret) ... ok
test_worker_crash_event_is_visible_in_chat_db_contract (tests.test_pwa_routing.PwaRoutingTests.test_worker_crash_event_is_visible_in_chat_db_contract) ... ok

======================================================================
FAIL: test_frontend_has_visible_a2a_coordination_toggle (tests.test_pwa_routing.PwaRoutingTests.test_frontend_has_visible_a2a_coordination_toggle)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/opt/cto/tests/test_pwa_routing.py", line 209, in test_frontend_has_visible_a2a_coordination_toggle
    self.assertIn("Agent coordination", index_html)
AssertionError: 'Agent coordination' not found in '<!doctype html>\n<html lang="en">\n<head>\n  <meta charset="utf-8" />\n  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />\n  <title>CTO</title>\n  <meta name="theme-color" content="#0a0a0a" />\n  <link rel="manifest" href="/manifest.json" />\n  <link rel="stylesheet" href="/static/style.css" />\n  <link rel="icon" href="/static/icon-192.png" />\n  <link rel="apple-touch-icon" href="/static/icon-192.png" />\n</head>\n<body>\n  <header class="topbar">\n    <h1>CTO</h1>\n    <div class="status" id="status">connecting…</div>\n    <details class="settings">\n      <summary aria-label="Settings and features">⋯</summary>\n      <div class="settings-panel">\n        <label class="settings-row" title="Show OpenClaw ↔ Hermes coordination traffic inline with chat"><input type="checkbox" id="toggle-a2a" /> Show agent coordination</label>\n        <a class="settings-row" id="chat-history" href="/chat-log/" target="_blank" rel="noopener">Chat history</a>\n        <button class="settings-row" id="enable-push" title="Subscribe this device and send a live self-test push notification">Test push</button>\n        <button class="settings-row" id="voice-toggle" aria-pressed="false" title="Speak new CTO replies aloud">Voice off</button>\n        <button class="settings-row" id="refresh-app" title="Refresh the installed PWA shell">Update app</button>\n        <span class="settings-row settings-status" id="push-status"></span>\n        <span class="settings-row settings-status" id="voice-status"></span>\n        <button class="settings-row settings-secondary" id="report-push-status" hidden>Report push status</button>\n        <button class="settings-row settings-secondary" id="report-voice-status" hidden>Report voice status</button>\n        <span class="settings-row settings-help" id="push-help" hidden></span>\n        <span class="settings-row settings-help" id="voice-help" hidden></span>\n      </div>\n    </details>\n  </header>\n  <main id="messages" aria-live="polite"></main>\n  <form id="composer" autocomplete="off">\n    <button type="button" id="voice-input" title="Dictate a message">🎙</button>\n    <input id="input" name="text" placeholder="Talk to CTO. Use @Hermes to address Hermes directly." autofocus />\n    <button type="submit">Send</button>\n  </form>\n  <script src="/static/app.js" defer></script>\n</body>\n</html>\n'

======================================================================
FAIL: test_manifest_icons_exist_and_are_cached_by_service_worker (tests.test_pwa_routing.PwaRoutingTests.test_manifest_icons_exist_and_are_cached_by_service_worker)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/opt/cto/tests/test_pwa_routing.py", line 199, in test_manifest_icons_exist_and_are_cached_by_service_worker
    self.assertIn('const SHELL_CACHE = "cto-shell-v23"', service_worker)
AssertionError: 'const SHELL_CACHE = "cto-shell-v23"' not found in '// CTO PWA service worker — minimal: caches the app shell for offline launch +\n// handles Web Push events (delivered by the backend via pywebpush when wired).\n// Bump SHELL_CACHE when shipping any change to index.html / app.js / style.css.\n// The activate handler deletes any cache != current, so the bump is the only\n// thing the user needs for an update to take effect on next page load.\nconst SHELL_CACHE = "cto-shell-v24";\nconst SHELL_FILES = ["/", "/index.html", "/static/app.js", "/static/style.css", "/manifest.json", "/static/icon-192.png", "/static/icon-512.png"];\nconst SHELL_PATHS = new Set(SHELL_FILES);\n\nself.addEventListener("install", (event) => {\n  event.waitUntil(\n    caches.open(SHELL_CACHE).then((c) => c.addAll(SHELL_FILES))\n  );\n  self.skipWaiting();\n});\n\nself.addEventListener("activate", (event) => {\n  event.waitUntil(\n    caches.keys().then((keys) =>\n      Promise.all(keys.filter((k) => k !== SHELL_CACHE).map((k) => caches.delete(k)))\n    )\n  );\n  self.clients.claim();\n});\n\nself.addEventListener("fetch", (event) => {\n  const url = new URL(event.request.url);\n  // API/chat-log/export routes are always network-only so private data and\n  // history never come from a stale cache.\n  if (url.pathname.startsWith("/api/") || url.pathname.startsWith("/chat-log/")) {\n    event.respondWith(fetch(event.request));\n    return;\n  }\n\n  // The visible PWA shell must update quickly on John\'s installed phone PWA.\n  // Use network-first for shell files instead of cache-first, then refresh the\n  // cache from the successful response. This prevents old cached HTML/JS from\n  // hiding newly shipped feature-request UI until a manual cache purge.\n  const isShellRequest = event.request.mode === "navigate" || SHELL_PATHS.has(url.pathname);\n  if (isShellRequest) {\n    event.respondWith(\n      fetch(event.request).then((resp) => {\n        const copy = resp.clone();\n        caches.open(SHELL_CACHE).then((c) => c.put(event.request, copy)).catch(() => {});\n        return resp;\n      }).catch(() => caches.match(event.request))\n    );\n    return;\n  }\n\n  event.respondWith(\n    caches.match(event.request).then((hit) => hit || fetch(event.request))\n  );\n});\n\nself.addEventListener("push", (event) => {\n  let data = { title: "CTO", body: "New activity" };\n  try { if (event.data) data = event.data.json(); } catch (e) {}\n  const options = {\n    body: data.body || "",\n    icon: "/static/icon-192.png",\n    badge: "/static/icon-192.png",\n    tag: data.tag || "cto",\n    data: { url: data.url || "/" },\n    requireInteraction: !!data.requireInteraction,\n  };\n  event.waitUntil(self.registration.showNotification(data.title || "CTO", options));\n});\n\nself.addEventListener("notificationclick", (event) => {\n  event.notification.close();\n  event.waitUntil(\n    clients.matchAll({ type: "window" }).then((wins) => {\n      for (const w of wins) {\n        if (w.url.includes(event.notification.data.url) && "focus" in w) return w.focus();\n      }\n      return clients.openWindow(event.notification.data.url || "/");\n    })\n  );\n});\n'

----------------------------------------------------------------------
Ran 38 tests in 0.221s

FAILED (failures=2)

## Conclusion
Operational redaction repair did not clear the full gate suite. Use this artifact as the next repair target.
