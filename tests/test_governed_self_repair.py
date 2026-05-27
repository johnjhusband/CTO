import json
import subprocess
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "repair" / "governed-self-repair.py"


def write_manifest(tmp_path: Path, **overrides):
    target = tmp_path / "target.txt"
    target.write_text("before")
    data = {
        "title": "Repair test",
        "reason": "Need an auditable direct edit",
        "paths": [str(target)],
        "verification": ["pytest tests/test_governed_self_repair.py"],
        "rollback_plan": "Restore the generated backup or revert the commit",
        "owner": "openclaw",
    }
    data.update(overrides)
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps(data))
    return manifest, target


def run_cmd(*args, cwd: Path):
    return subprocess.run(["python3", str(SCRIPT), *args], cwd=cwd, text=True, capture_output=True, check=True)


def test_begin_creates_open_record_and_backup(tmp_path):
    subprocess.run(["git", "init"], cwd=tmp_path, check=True, capture_output=True)
    manifest, target = write_manifest(tmp_path)
    result = run_cmd("--root", str(tmp_path), "begin", "--manifest", str(manifest), "--allow-prefix", str(tmp_path), cwd=tmp_path)
    record_path = Path(result.stdout.strip())
    record = json.loads(record_path.read_text())
    assert record["state"] == "open"
    assert record["manifest"]["paths"] == [str(target.resolve())]
    assert record["backups"][0]["sha256_before"]
    assert (tmp_path / record["backups"][0]["backup"]).exists()


def test_close_requires_verification_and_closes_record(tmp_path):
    subprocess.run(["git", "init"], cwd=tmp_path, check=True, capture_output=True)
    manifest, _ = write_manifest(tmp_path)
    begin = run_cmd("--root", str(tmp_path), "begin", "--manifest", str(manifest), "--allow-prefix", str(tmp_path), cwd=tmp_path)
    record_path = Path(begin.stdout.strip())
    close = run_cmd(
        "--root", str(tmp_path),
        "close", "--record", str(record_path),
        "--verification", "pytest passed",
        "--notes", "done",
        cwd=tmp_path,
    )
    assert close.stdout.strip() == str(record_path)
    record = json.loads(record_path.read_text())
    assert record["state"] == "closed"
    assert record["verification_results"] == ["pytest passed"]


def test_rejects_out_of_scope_paths(tmp_path):
    manifest, _ = write_manifest(tmp_path, paths=["/etc/shadow"])
    result = subprocess.run(
        ["python3", str(SCRIPT), "--root", str(tmp_path), "begin", "--manifest", str(manifest), "--allow-prefix", str(tmp_path)],
        cwd=tmp_path,
        text=True,
        capture_output=True,
    )
    assert result.returncode != 0
    assert "outside allowed repair scope" in result.stderr
