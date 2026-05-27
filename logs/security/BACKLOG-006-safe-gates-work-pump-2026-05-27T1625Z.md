# BACKLOG-006 safe credential/access-control gate — 2026-05-27T16:25Z

- A2A2H per-tick check: no upstream-eligible CTO commits since tracker SHA 353253a7366345676d06c775bdcd5c7f9d61daf7; no port required.
- Hermes semantic delegation: skipped because `.cache/hermes-work-pump-provider-failure.json` shows the provider circuit open (`agent_incomplete_provider_NoneType`).
- Scope: non-destructive P0 credential/access-control verification only; no credential values read/printed, no rotation/revocation, no history rewrite, no infrastructure mutation.

## Verification command

```bash
scripts/security/run-safe-security-gates.sh
```

## Result

PASS

```text
- cto-a2a-registry.service: active

Local health endpoints:
- openclaw-gateway: ok (27 bytes)
- hermes-gateway: ok (44 bytes)
- hermes-a2a-sidecar: ok (49 bytes)
- pwa-backend: ok (42 bytes)

Smoke result: local_services_healthy

== redaction unit tests ==
test_does_not_report_secret_values_in_counts (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_does_not_report_secret_values_in_counts) ... ok
test_leaves_angle_bracket_placeholders_safe (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_leaves_angle_bracket_placeholders_safe) ... ok
test_leaves_existing_placeholders_safe (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_leaves_existing_placeholders_safe) ... ok
test_redacts_adjacent_url_query_secret_names (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_adjacent_url_query_secret_names) ... ok
test_redacts_http_auth_headers_and_pwa_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_http_auth_headers_and_pwa_session_cookies) ... ok
test_redacts_legacy_pwa_query_token_values (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_legacy_pwa_query_token_values) ... ok
test_redacts_natural_language_password_pastes (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_natural_language_password_pastes) ... ok
test_redacts_runtime_token_names_missing_from_initial_gate (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_runtime_token_names_missing_from_initial_gate) ... ok
test_redacts_sensitive_http_headers_and_generic_session_cookies (tests.test_redact_operational_secrets.RedactOperationalSecretsTests.test_redacts_sensitive_http_headers_and_generic_session_cookies) ... ok

----------------------------------------------------------------------
Ran 9 tests in 0.001s

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
test_frontend_has_visible_a2a_coordination_toggle (tests.test_pwa_routing.PwaRoutingTests.test_frontend_has_visible_a2a_coordination_toggle) ... ok
test_frontend_resyncs_history_on_foreground (tests.test_pwa_routing.PwaRoutingTests.test_frontend_resyncs_history_on_foreground) ... ok
test_manifest_icons_exist_and_are_cached_by_service_worker (tests.test_pwa_routing.PwaRoutingTests.test_manifest_icons_exist_and_are_cached_by_service_worker) ... ok
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

----------------------------------------------------------------------
Ran 38 tests in 0.270s

OK

== PWA voice UI regression tests ==
test_voice_controls_are_visible_and_cache_bumped (tests.test_pwa_voice_ui.PwaVoiceUiTests.test_voice_controls_are_visible_and_cache_bumped) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK

Safe security gates passed.
```
