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
            chat_db = importlib.import_module("chat.db")
            row_id = chat_db.append(sender="system", recipient="john", kind="system_event", content="ok")
            self.assertGreater(row_id, 0)
            self.assertTrue(Path(os.environ["CHAT_DB"]).exists())


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

    def test_api_query_token_no_longer_authenticates(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages?token=test-secret-token"
            handler.headers = {}
            self.assertFalse(handler._auth_ok())

    def test_session_cookie_authenticates(self):
        with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp:
            os.environ["PWA_AUTH_TOKEN"] = "test-secret-token"
            server = fresh_server_module(tmp)
            value = server.Handler._make_session_value(now=int(time.time()))
            handler = object.__new__(server.Handler)
            handler.path = "/api/messages"
            handler.headers = {"Cookie": f"cto_pwa_session={urllib.parse.quote(value)}"}
            self.assertTrue(handler._auth_ok())
