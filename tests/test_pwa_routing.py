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
import unittest
from contextlib import redirect_stderr
from io import StringIO
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SERVICES = REPO / "services"
for p in (str(REPO), str(SERVICES)):
    if p not in sys.path:
        sys.path.insert(0, p)


def fresh_server_module(tmpdir: str):
    os.environ["CHAT_DB"] = str(Path(tmpdir) / "chat.db")
    os.environ["CTO_INSTANCE_ID"] = "test-suite"
    os.environ["OPENCLAW_SESSION_ID"] = "test-openclaw-session"
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


if __name__ == "__main__":
    unittest.main()

class PwaAccessControlTests(unittest.TestCase):
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

    def test_session_cookie_authenticates(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            value = server.Handler._make_session_value(now=int(time.time()))
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {"Cookie": f"cto_pwa_session={urllib.parse.quote(value)}"}
            self.assertTrue(handler._auth_ok())

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
