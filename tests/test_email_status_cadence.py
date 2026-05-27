import importlib.util
import json
import os
import tempfile
from argparse import Namespace
from pathlib import Path
from unittest import TestCase, mock

MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "email-status-cadence.py"


def load_module():
    spec = importlib.util.spec_from_file_location("email_status_cadence", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class EmailStatusCadenceTests(TestCase):
    def setUp(self):
        self.module = load_module()
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.digest_dir = self.root / "digest"
        self.digest_dir.mkdir()
        self.digest = self.digest_dir / "digest-2026-05-27.md"
        self.digest.write_text("# Status\n\nAll good.\n")
        self.state_path = self.root / "state.json"

    def tearDown(self):
        self.tmp.cleanup()

    def args(self, **overrides):
        base = dict(
            digest_dir=str(self.digest_dir),
            state_path=str(self.state_path),
            env_file=None,
            subject=None,
            dry_run=False,
            check_credentials=False,
            send=False,
            force=False,
        )
        base.update(overrides)
        return Namespace(**base)

    def test_dry_run_does_not_check_credentials_or_send(self):
        with mock.patch.object(self.module, "load_send_status_module") as loader, mock.patch("builtins.print") as printed:
            send_status = mock.Mock(DEFAULT_TO="john@husband.llc")
            loader.return_value = send_status
            result = self.module.run(self.args(dry_run=True))

        self.assertEqual(result, 0)
        send_status.check_credentials.assert_not_called()
        send_status.send_message.assert_not_called()
        self.assertIn("dry_run would_send", printed.call_args.args[0])

    def test_check_credentials_reports_missing_api_key_name_only(self):
        send_status = mock.Mock(DEFAULT_TO="john@husband.llc")
        send_status.configured_provider.return_value = "resend"
        send_status.check_credentials.side_effect = RuntimeError("missing email credentials: CTO_EMAIL_API_KEY")
        with mock.patch.object(self.module, "load_send_status_module", return_value=send_status):
            with self.assertRaises(self.module.CadenceBlocked) as raised:
                self.module.run(self.args(check_credentials=True))

        message = str(raised.exception)
        self.assertIn("CTO_EMAIL_API_KEY", message)
        self.assertNotIn("secret", message.lower())
        send_status.send_message.assert_not_called()

    def test_send_updates_state_and_suppresses_duplicate(self):
        send_status = mock.Mock(DEFAULT_TO="john@husband.llc")
        send_status.configured_provider.return_value = "resend"
        send_status.build_message.return_value = "message-object"
        with mock.patch.object(self.module, "load_send_status_module", return_value=send_status):
            result = self.module.run(self.args(send=True))
            duplicate = self.module.run(self.args(send=True))

        self.assertEqual(result, 0)
        self.assertEqual(duplicate, 0)
        send_status.check_credentials.assert_called_once()
        send_status.send_message.assert_called_once_with("message-object")
        state = json.loads(self.state_path.read_text())
        self.assertEqual(state["last_sent_digest"], "digest-2026-05-27.md")
        self.assertEqual(state["last_provider"], "resend")

    def test_load_env_file_does_not_override_existing_env(self):
        env_file = self.root / ".env"
        env_file.write_text("CTO_EMAIL_PROVIDER=resend\nCTO_EMAIL_API_KEY=file-secret\n")
        with mock.patch.dict(os.environ, {"CTO_EMAIL_API_KEY": "existing-secret"}, clear=True):
            self.module.load_env_file(env_file)
            self.assertEqual(os.environ["CTO_EMAIL_API_KEY"], "existing-secret")
            self.assertEqual(os.environ["CTO_EMAIL_PROVIDER"], "resend")
