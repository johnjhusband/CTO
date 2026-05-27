#!/usr/bin/env python3
"""Local no-spend tests for CTO PWA routing and clone isolation."""
from __future__ import annotations

import importlib
import json
import os
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import unittest
from contextlib import redirect_stderr
from io import BytesIO, StringIO
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SERVICES = REPO / "services"
for p in (str(REPO), str(SERVICES)):
    if p not in sys.path:
        sys.path.insert(0, p)


def fresh_server_module(
    tmpdir: str,
    *,
    instance_id: str = "test-suite",
    openclaw_session_id: str | None = "test-openclaw-session",
    openclaw_session_base: str | None = "",
):
    os.environ["CHAT_DB"] = str(Path(tmpdir) / "chat.db")
    os.environ["CTO_INSTANCE_ID"] = instance_id
    if openclaw_session_base == "":
        os.environ.pop("OPENCLAW_SESSION_ID_BASE", None)
    elif openclaw_session_base is not None:
        os.environ["OPENCLAW_SESSION_ID_BASE"] = openclaw_session_base
    if openclaw_session_id is not None:
        os.environ["OPENCLAW_SESSION_ID"] = openclaw_session_id
    os.environ["PWA_CHAT_LOG_DIR"] = str(Path(tmpdir) / "logs" / "pwa-chat")
    for name in list(sys.modules):
        if name == "services.pwa.backend.server" or name == "chat.db":
            sys.modules.pop(name, None)
    return importlib.import_module("services.pwa.backend.server")


class PwaRoutingTests(unittest.TestCase):
    def test_parse_mention_recognizes_explicit_both(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            self.assertEqual(server.parse_mention("@both check routing"), ("both", "check routing"))

    def test_parse_mention_mixed_openclaw_and_hermes_becomes_coordinated_both(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            target, stripped = server.parse_mention("@openclaw start with strategy. @hermes implement after.")
            self.assertEqual(target, "both")
            self.assertIn("@hermes implement after", stripped)

    def test_coordinated_both_calls_openclaw_before_hermes(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            calls: list[str] = []

            def fake_openclaw(message: str):
                calls.append("openclaw")
                return {"ok": True, "reply": "Strategy: scoped handoff for Hermes."}

            def fake_hermes(message: str, task_id=None, **kwargs):
                calls.append("hermes")
                self.assertEqual(kwargs["sender"], "openclaw")
                self.assertEqual(kwargs["inputs"]["audience"], "agent")
                self.assertIn("scoped handoff", kwargs["inputs"]["openclaw_strategy_and_handoff"])
                return {"ok": True, "findings": json.dumps({"status": "implemented"})}

            server.send_to_openclaw = fake_openclaw
            server.send_to_hermes = fake_hermes
            result = server.send_coordinated_both("do the thing")

            self.assertTrue(result["ok"])
            self.assertEqual(calls, ["openclaw", "hermes"])

    def test_openclaw_session_id_is_bounded_to_utc_day(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["OPENCLAW_SESSION_ID"] = "pwa-john-20260527-1203"
            server = fresh_server_module(tmp, openclaw_session_id=None)
            session_id = server.openclaw_session_id(server.datetime(2026, 5, 28, tzinfo=server.timezone.utc))
            self.assertEqual(session_id, "pwa-john-20260528")

    def test_openclaw_session_id_base_override_is_bounded_to_utc_day(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp, openclaw_session_id=None, openclaw_session_base="pwa-john-custom")
            session_id = server.openclaw_session_id(server.datetime(2026, 5, 28, tzinfo=server.timezone.utc))
            self.assertEqual(session_id, "pwa-john-custom-20260528")

    def test_worker_crash_event_is_visible_in_chat_db_contract(self):
        source = (REPO / "services" / "pwa" / "backend" / "server.py").read_text()
        self.assertIn("pwa_chat_worker_crashed", source)
        self.assertIn("traceback.format_exception", source)

    def test_stale_chat_worker_watchdog_writes_visible_system_event(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            server.PWA_PENDING_WORKER_WARN_S = 10
            server._record_active_chat_worker("worker-test", target="openclaw")
            server._ACTIVE_CHAT_WORKERS["worker-test"]["started"] -= 11
            emitted = server._emit_stale_chat_worker_events()
            self.assertEqual(emitted, 1)
            rows = server.tail(0, 10)
            self.assertTrue(any("pwa_chat_worker_stuck" in row["content"] for row in rows))
            self.assertEqual(server._emit_stale_chat_worker_events(), 0)
            server._clear_active_chat_worker("worker-test")

    def test_candidate_clone_rejects_production_chat_db(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            error = server._clone_chat_isolation_error(
                instance_id="candidate-abc",
                chat_db="/opt/cto/chat.db",
                cto_root="/opt/cto",
            )
            self.assertIsNotNone(error)
            self.assertIn("Candidate clone", error)

    def test_production_allows_production_chat_db(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            error = server._clone_chat_isolation_error(
                instance_id="production",
                chat_db="/opt/cto/chat.db",
                cto_root="/opt/cto",
            )
            self.assertIsNone(error)

    def test_candidate_clone_allows_isolated_chat_db(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            error = server._clone_chat_isolation_error(
                instance_id="candidate-abc",
                chat_db="/opt/cto/.candidate/candidate-abc/chat.db",
                cto_root="/opt/cto",
            )
            self.assertIsNone(error)
    def test_candidate_chat_connection_creates_parent_directory(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            sys.modules.pop("chat.db", None)
            os.environ["CTO_INSTANCE_ID"] = "candidate-db-test"
            os.environ["CHAT_DB"] = str(Path(tmp) / "nested" / "candidate" / "chat.db")
            os.environ["PWA_CHAT_LOG_DIR"] = str(Path(tmp) / "logs" / "pwa-chat")
            chat_db = importlib.import_module("chat.db")
            row_id = chat_db.append(sender="system", recipient="john", kind="system_event", content="ok")
            self.assertGreater(row_id, 0)
            self.assertTrue(Path(os.environ["CHAT_DB"]).exists())

    def test_chat_append_writes_human_markdown_log_and_skips_a2a_json(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            sys.modules.pop("chat.db", None)
            os.environ["CTO_INSTANCE_ID"] = "test-suite"
            os.environ["CHAT_DB"] = str(Path(tmp) / "chat.db")
            log_dir = Path(tmp) / "logs" / "pwa-chat"
            os.environ["PWA_CHAT_LOG_DIR"] = str(log_dir)
            chat_db = importlib.import_module("chat.db")
            row_id = chat_db.append(sender="openclaw", recipient="john", kind="chat", content="Readable answer")
            chat_db.log_a2a_request(task_id="task-1", sender="openclaw", recipient="hermes", payload={"secret_shape": "json"})
            files = list(log_dir.glob("*.md"))
            self.assertEqual(len(files), 1)
            text = files[0].read_text()
            self.assertIn("Readable answer", text)
            self.assertIn(f"#{row_id}", text)
            self.assertNotIn("secret_shape", text)

    def test_chat_log_helpers_reject_traversal_and_limit_export_range(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            self.assertIsNone(server._safe_chat_log_path("../../etc/passwd"))
            self.assertIsNotNone(server._safe_chat_log_path("2026-05-26"))
            self.assertEqual(server._chat_log_dates_between("2026-05-26", "2026-05-27"), ["2026-05-26", "2026-05-27"])
            self.assertEqual(server._chat_log_dates_between("2026-05-27", "2026-05-26"), [])
            self.assertEqual(server._chat_log_dates_between("2026-01-01", "2026-03-01"), [])

    def test_frontend_resyncs_history_on_foreground(self):
        app_js = (REPO / "services" / "pwa" / "frontend" / "app.js").read_text()
        self.assertIn("visibilitychange", app_js)
        self.assertIn("loadHistory({ replace: true })", app_js)

    def test_manifest_icons_exist_and_are_cached_by_service_worker(self):
        frontend = REPO / "services" / "pwa" / "frontend"
        manifest = json.loads((frontend / "manifest.json").read_text())
        icon_srcs = {icon["src"] for icon in manifest["icons"]}
        self.assertEqual(icon_srcs, {"/static/icon-192.png", "/static/icon-512.png"})
        for src in icon_srcs:
            icon_path = frontend / src.removeprefix("/static/")
            self.assertTrue(icon_path.exists(), src)
            self.assertGreater(icon_path.stat().st_size, 100, src)
            self.assertEqual(icon_path.read_bytes()[:8], b"\x89PNG\r\n\x1a\n", src)
        service_worker = (frontend / "service-worker.js").read_text()
        self.assertIn('"/static/icon-192.png"', service_worker)
        self.assertIn('"/static/icon-512.png"', service_worker)
        self.assertRegex(service_worker, r'const SHELL_CACHE = "cto-shell-v\d+"')

    def test_frontend_has_visible_a2a_coordination_toggle(self):
        frontend = REPO / "services" / "pwa" / "frontend"
        index_html = (frontend / "index.html").read_text()
        app_js = (frontend / "app.js").read_text()
        style_css = (frontend / "style.css").read_text()
        service_worker = (frontend / "service-worker.js").read_text()

        self.assertIn('class="settings"', index_html)
        self.assertIn('id="toggle-a2a"', index_html)
        self.assertIn("Show agent coordination", index_html)
        self.assertIn('id="chat-history"', index_html)
        self.assertIn("Chat history", index_html)
        self.assertIn('id="enable-push"', index_html)
        self.assertIn("Test push", index_html)
        self.assertIn('id="voice-toggle"', index_html)
        self.assertIn('id="refresh-app"', index_html)
        self.assertIn('id="push-status"', index_html)
        self.assertIn('id="push-help"', index_html)
        self.assertIn('id="report-push-status"', index_html)
        self.assertIn('id="voice-status"', index_html)
        self.assertIn('id="voice-help"', index_html)
        self.assertIn('id="report-voice-status"', index_html)
        self.assertIn("describePushCapability()", app_js)
        self.assertIn("reportPushDeviceStatus", app_js)
        self.assertIn("currentPushSubscriptionState", app_js)
        self.assertIn("autoReportDailyDeviceReadiness", app_js)
        self.assertIn("pwa-device-readiness-auto-report-day", app_js)
        self.assertIn('/api/push/device_status', app_js)
        self.assertIn("reportVoiceDeviceStatus", app_js)
        self.assertIn('/api/voice/device_status', app_js)
        self.assertIn("setPushStatus", app_js)
        self.assertIn("pushHelpText", app_js)
        self.assertIn("add CTO to Home Screen", app_js)
        self.assertIn(".settings", style_css)
        self.assertIn(".settings-panel", style_css)
        self.assertIn(".settings-row", style_css)
        self.assertIn("m.kind.startsWith(\"a2a_\")", app_js)
        self.assertIn("a2a-capability", app_js)
        self.assertIn("Raw JSON", app_js)
        self.assertIn("initToggle($toggleA2A, \"a2a\")", app_js)
        self.assertIn("body:not(.show-a2a) .msg.a2a { display: none; }", style_css)
        self.assertRegex(service_worker, r'const SHELL_CACHE = "cto-shell-v\d+"')
        self.assertIn("let reported = false", app_js)
        self.assertIn("if (reported) localStorage.setItem(key, day);", app_js)
        self.assertIn('event.request.mode === "navigate" || SHELL_PATHS.has(url.pathname)', service_worker)
        self.assertIn('url.pathname.startsWith("/chat-log/")', service_worker)
        self.assertIn('fetch(event.request).then((resp) => {', service_worker)


    def test_push_device_status_summary_is_bounded_and_non_secret(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            summary = server._summarize_push_device_status({
                "notification_supported": True,
                "service_worker_supported": True,
                "push_supported": True,
                "permission": "granted",
                "subscribed": True,
                "standalone": True,
                "manual": True,
                "test_attempted": 1,
                "test_failed": 0,
                "status_text": "ready",
                "user_agent": "Mozilla/5.0 secret-token-should-not-all-be-copied",
            })
            self.assertEqual(summary["event"], "push_device_status")
            self.assertTrue(summary["subscribed"])
            self.assertFalse(summary["auto_daily"])
            self.assertEqual(summary["permission"], "granted")
            self.assertEqual(summary["user_agent_family"], "Mozilla/5.0")
            self.assertNotIn("secret-token", json.dumps(summary))

    def test_voice_device_status_summary_is_bounded_and_non_secret(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            summary = server._summarize_voice_device_status({
                "speech_synthesis_supported": True,
                "speech_recognition_supported": False,
                "voice_enabled": True,
                "standalone": True,
                "manual": True,
                "status_text": "read aloud only",
                "user_agent": "Mozilla/5.0 secret-token-should-not-all-be-copied",
            })
            self.assertEqual(summary["event"], "voice_device_status")
            self.assertTrue(summary["speech_synthesis_supported"])
            self.assertFalse(summary["speech_recognition_supported"])
            self.assertFalse(summary["auto_daily"])
            self.assertEqual(summary["user_agent_family"], "Mozilla/5.0")
            self.assertNotIn("secret-token", json.dumps(summary))

    def test_a2a_audit_sanitizer_redacts_obvious_secrets(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            sanitized = server._sanitize_a2a_audit_value({
                "api_key": "live-secret",
                "inputs": {
                    "message": "open https://x.test/?token=legacy-secret and Authorization: Bearer live-token; pw is pasted-secret",
                },
            })
            rendered = json.dumps(sanitized)
            self.assertIn("[REDACTED]", rendered)
            self.assertNotIn("live-secret", rendered)
            self.assertNotIn("legacy-secret", rendered)
            self.assertNotIn("live-token", rendered)
            self.assertNotIn("pasted-secret", rendered)

    def test_send_to_hermes_writes_visible_sanitized_a2a_audit_rows(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            chat_db = importlib.import_module("chat.db")

            class FakeResponse:
                def __enter__(self):
                    return self
                def __exit__(self, *_args):
                    return False
                def read(self):
                    return json.dumps({"findings": "done; Authorization: Bearer response-secret"}).encode()

            original_urlopen = urllib.request.urlopen
            try:
                urllib.request.urlopen = lambda *_args, **_kwargs: FakeResponse()
                result = server.send_to_hermes(
                    "the pw is request-secret",
                    task_id="audit-test-1",
                    sender="openclaw",
                    inputs={"message": "the pw is request-secret", "token": "input-secret"},
                )
            finally:
                urllib.request.urlopen = original_urlopen

            self.assertTrue(result["ok"])
            rows = [row for row in chat_db.tail(0, 20) if row["correlation"] == "audit-test-1"]
            self.assertEqual([row["kind"] for row in rows], ["a2a_request", "a2a_response"])
            joined = "\n".join(row["content"] for row in rows)
            self.assertNotIn("request-secret", joined)
            self.assertNotIn("input-secret", joined)
            self.assertNotIn("response-secret", joined)
            self.assertIn("[REDACTED]", joined)

    def test_send_to_hermes_reports_a2a_token_mismatch_actionably(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)

            def fake_urlopen(*_args, **_kwargs):
                raise urllib.error.HTTPError(
                    url="http://127.0.0.1:8643/a2a/",
                    code=401,
                    msg="Unauthorized",
                    hdrs=None,
                    fp=BytesIO(b'{"error":"unauthorized"}'),
                )

            original_urlopen = urllib.request.urlopen
            try:
                urllib.request.urlopen = fake_urlopen
                result = server.send_to_hermes("check", task_id="unauth-test-1")
            finally:
                urllib.request.urlopen = original_urlopen

            self.assertFalse(result["ok"])
            self.assertIn("HERMES_A2A_TOKEN", result["error"])


if __name__ == "__main__":
    unittest.main()

class PwaAccessControlTests(unittest.TestCase):
    def test_production_without_auth_token_fails_closed(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = ""
            os.environ.pop("PWA_AUTH_TOKEN_PREVIOUS", None)
            os.environ.pop("PWA_ALLOW_DEV_NO_AUTH", None)
            server = fresh_server_module(tmp, instance_id="production")
            self.assertIn("required", server._pwa_auth_startup_error())
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {}
            self.assertFalse(handler._auth_ok())

    def test_non_production_without_auth_token_is_dev_mode_only(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = ""
            os.environ.pop("PWA_AUTH_TOKEN_PREVIOUS", None)
            os.environ.pop("PWA_ALLOW_DEV_NO_AUTH", None)
            server = fresh_server_module(tmp, instance_id="test-suite")
            self.assertIsNone(server._pwa_auth_startup_error())
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {}
            self.assertTrue(handler._auth_ok())

    def test_session_cookie_does_not_store_bearer_token(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            value = server.Handler._make_session_value(now=1_000)
            self.assertNotIn("test-secret-token", value)
            self.assertTrue(server.Handler._valid_session_value(value, now=1_010))

    def test_auth_rejects_bare_url_without_cookie(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.path = "/"
            handler.headers = {}
            self.assertFalse(handler._auth_ok())


    def test_static_file_disconnect_does_not_raise(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            asset = Path(tmp) / "manifest.json"
            asset.write_text('{"name":"test"}')

            class BrokenWriter:
                def write(self, _data):
                    raise BrokenPipeError()

            handler = object.__new__(server.Handler)
            handler.wfile = BrokenWriter()
            handler.send_response = lambda _status: None
            handler.send_header = lambda *_args: None
            handler.end_headers = lambda: None

            handler._file(asset, "application/manifest+json")

    def test_pwa_shell_is_not_public_when_auth_token_configured(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            self.assertFalse(handler._is_public_get("/"))
            self.assertFalse(handler._is_public_get("/index.html"))
            self.assertTrue(handler._is_public_get("/manifest.json"))

    def test_api_query_token_no_longer_authenticates(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages?token=test-secret-token"
            handler.headers = {}
            self.assertFalse(handler._auth_ok())

    def test_access_log_redacts_legacy_query_token(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.log_date_time_string = lambda: "date"
            err = StringIO()
            with redirect_stderr(err):
                handler.log_message('"GET /api/stream?token=%s HTTP/1.1" 401 -', "test-secret-token")
            logged = err.getvalue()
            self.assertIn("token=[REDACTED]", logged)
            self.assertNotIn("test-secret-token", logged)

    def test_legacy_stream_query_token_204_access_log_is_suppressed(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.log_date_time_string = lambda: "date"
            err = StringIO()
            with redirect_stderr(err):
                handler.log_message('"GET /api/stream?token=%s HTTP/1.1" 204 -', "test-secret-token")
            self.assertEqual(err.getvalue(), "")

    def test_legacy_stream_query_token_stops_eventsource_retry_storm(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.path = "/api/stream?token=test-secret-token"
            handler.headers = {}
            statuses = []
            headers = []
            handler.send_response = lambda code: statuses.append(code)
            handler.send_header = lambda name, value: headers.append((name, value))
            handler.end_headers = lambda: None

            handler.do_GET()

            self.assertEqual(statuses, [204])
            self.assertIn(("Cache-Control", "no-store"), headers)
            self.assertIn(("Clear-Site-Data", '"cache"'), headers)


    def test_unauthorized_json_responses_are_no_store(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            statuses = []
            headers = []
            body = BytesIO()
            handler.send_response = lambda code: statuses.append(code)
            handler.send_header = lambda name, value: headers.append((name, value))
            handler.end_headers = lambda: None
            handler.wfile = body

            handler._json(401, {"error": "unauthorized"})

            self.assertEqual(statuses, [401])
            self.assertIn(("Cache-Control", "no-store"), headers)
            self.assertIn(b"unauthorized", body.getvalue())

    def test_session_cookie_authenticates(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            os.environ.pop("PWA_AUTH_TOKEN_PREVIOUS", None)
            server = fresh_server_module(tmp)
            value = server.Handler._make_session_value(now=int(time.time()))
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {"Cookie": f"cto_pwa_session={urllib.parse.quote(value)}"}
            self.assertTrue(handler._auth_ok())

    def test_previous_pwa_token_keeps_existing_session_valid_during_rotation(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "old-token"
            os.environ.pop("PWA_AUTH_TOKEN_PREVIOUS", None)
            server = fresh_server_module(tmp)
            issued_at = int(time.time())
            old_cookie = server.Handler._make_session_value(now=issued_at)

            os.environ["PWA_AUTH_TOKEN"] = "new-token"
            os.environ["PWA_AUTH_TOKEN_PREVIOUS"] = "old-token"
            server = fresh_server_module(tmp)
            self.assertTrue(server.Handler._valid_session_value(old_cookie, now=issued_at + 10))
            self.assertTrue(server._pwa_auth_token_matches("old-token"))
            self.assertTrue(server._pwa_auth_token_matches("new-token"))

            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {"Cookie": f"cto_pwa_session={urllib.parse.quote(old_cookie)}"}
            self.assertTrue(handler._auth_ok())

    def test_previous_pwa_token_does_not_authenticate_api_query_token(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "new-token"
            os.environ["PWA_AUTH_TOKEN_PREVIOUS"] = "old-token, older-token"
            server = fresh_server_module(tmp)

            self.assertTrue(server._pwa_auth_token_matches("old-token"))
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages?token=old-token"
            handler.headers = {}
            self.assertFalse(handler._auth_ok())

    def test_previous_pwa_token_alone_does_not_satisfy_production_startup(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = ""
            os.environ["PWA_AUTH_TOKEN_PREVIOUS"] = "old-token"
            os.environ.pop("PWA_ALLOW_DEV_NO_AUTH", None)
            server = fresh_server_module(tmp, instance_id="production")

            self.assertIn("required", server._pwa_auth_startup_error())

class PwaPushNotificationTests(unittest.TestCase):
    def test_push_payload_truncates_reply_body(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            server = fresh_server_module(tmp)
            payload = server._push_payload(sender="openclaw", body="x" * 250, correlation="job-1")
            self.assertEqual(payload["title"], "OpenClaw replied")
            self.assertEqual(payload["tag"], "job-1")
            self.assertLessEqual(len(payload["body"]), 180)

    def test_push_without_vapid_key_degrades_to_noop(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["VAPID_PRIVATE_KEY_FILE"] = str(Path(tmp) / "missing.pem")
            server = fresh_server_module(tmp)
            self.assertEqual(server._send_push_notification(sender="openclaw", body="done"), (0, 0))
