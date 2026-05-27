import os
import subprocess
import tempfile
from pathlib import Path
from unittest import TestCase

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "security" / "credential-rotation-plan.sh"


class CredentialRotationPlanTests(TestCase):
    def test_check_only_reports_names_not_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            security = root / "scripts" / "security"
            security.mkdir(parents=True)
            for rel in [
                "rotation-preflight.sh",
                "rotation-smoke.sh",
                "check-git-history-secret-markers.sh",
                "run-safe-security-gates.sh",
            ]:
                p = security / rel
                p.write_text("#!/usr/bin/env bash\nset -euo pipefail\n", encoding="utf-8")
                p.chmod(0o755)
            redactor = security / "redact-operational-secrets.py"
            redactor.write_text("print('ok')\n", encoding="utf-8")
            redactor.chmod(0o755)

            env_file = root / ".env"
            secret_value = "super-secret-rotation-value"
            env_file.write_text(
                "\n".join(
                    f"{name}={secret_value}-{name}"
                    for name in [
                        "HETZNER_API_TOKEN",
                        "GITHUB_TOKEN",
                        "HERMES_API_SERVER_KEY",
                        "HERMES_A2A_TOKEN",
                        "OPENAI_API_KEY",
                        "PWA_AUTH_TOKEN",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )
            env_file.chmod(0o600)

            proc = subprocess.run(
                [str(SCRIPT), "--check-only"],
                cwd=ROOT,
                env={**os.environ, "ROOT": str(root), "ENV_FILE": str(env_file)},
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
            )

        self.assertIn("Plan check result: ready_for_coordinated_rotation_window", proc.stdout)
        self.assertIn("HETZNER_API_TOKEN: present_nonempty", proc.stdout)
        self.assertNotIn("super-secret-rotation-value", proc.stdout)
        self.assertNotIn("super-secret-rotation-value", proc.stderr)

    def test_rejects_mutating_modes(self):
        proc = subprocess.run(
            [str(SCRIPT), "--apply"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.assertEqual(proc.returncode, 2)
        self.assertIn("--check-only", proc.stderr)
