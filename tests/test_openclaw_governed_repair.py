import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "openclaw-governed-repair.py"


def run(args, *, env=None, cwd=None):
    merged = os.environ.copy()
    if env:
        merged.update(env)
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=cwd,
        env=merged,
        check=False,
    )


def test_begin_snapshot_finalize_records_diff_and_verification(tmp_path):
    allowed = tmp_path / "allowed"
    allowed.mkdir()
    target = allowed / "config.txt"
    target.write_text("before\n")
    sessions = tmp_path / "sessions"
    env = {"OPENCLAW_GOVERNED_REPAIR_ALLOWED_ROOTS": str(allowed)}

    # Import the module and override SESSION_ROOT so the test does not write /opt/cto/logs.
    spec = importlib.util.spec_from_file_location("governed_repair", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    module.SESSION_ROOT = sessions

    assert module.main(["begin", "--ticket", "BACKLOG-002", "--reason", "unit test", "--scope", "cto-workspace"]) == 0
    session = next(sessions.iterdir())
    os.environ.update(env)
    assert module.main(["snapshot", "--session", str(session), "--path", str(target)]) == 0
    target.write_text("after\n")
    assert module.main(["finalize", "--session", str(session), "--verify", "python3 -c 'print(123)'"]) == 0

    manifest = json.loads((session / "manifest.json").read_text())
    assert manifest["ticket"] == "BACKLOG-002"
    assert manifest["snapshots"][0]["sha256_before"]
    assert manifest["verification"]["passed"] is True
    assert len(manifest["diffs"]) == 1
    assert "-before" in Path(manifest["diffs"][0]["diff"]).read_text()
    assert "+after" in Path(manifest["diffs"][0]["diff"]).read_text()


def test_snapshot_rejects_denied_secret_path(tmp_path):
    allowed = tmp_path / "allowed"
    secret_dir = allowed / ".env"
    secret_dir.mkdir(parents=True)
    secret_file = secret_dir / "value"
    secret_file.write_text("SECRET=value\n")
    session = tmp_path / "session"
    session.mkdir()
    (session / "manifest.json").write_text(json.dumps({"snapshots": []}))
    env = {"OPENCLAW_GOVERNED_REPAIR_ALLOWED_ROOTS": str(allowed)}

    result = run(["snapshot", "--session", str(session), "--path", str(secret_file)], env=env)
    assert result.returncode != 0
    assert "Refusing sensitive path" in result.stderr


def test_snapshot_rejects_outside_allowed_roots(tmp_path):
    allowed = tmp_path / "allowed"
    allowed.mkdir()
    outside = tmp_path / "outside.txt"
    outside.write_text("nope\n")
    session = tmp_path / "session"
    session.mkdir()
    (session / "manifest.json").write_text(json.dumps({"snapshots": []}))
    env = {"OPENCLAW_GOVERNED_REPAIR_ALLOWED_ROOTS": str(allowed)}

    result = run(["snapshot", "--session", str(session), "--path", str(outside)], env=env)
    assert result.returncode != 0
    assert "outside governed repair roots" in result.stderr


def test_finalize_requires_snapshot(tmp_path):
    session = tmp_path / "session"
    session.mkdir()
    (session / "manifest.json").write_text(json.dumps({"snapshots": []}))

    result = run(["finalize", "--session", str(session), "--no-verify"])
    assert result.returncode != 0
    assert "without at least one pre-edit snapshot" in result.stderr
