import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/security/openclaw-upgrade-promotion-packet.py"


def write_json(path: Path, payload: dict):
    path.write_text(json.dumps(payload), encoding="utf-8")


def test_promotion_packet_blocks_when_clone_gate_blocked(tmp_path):
    candidate = tmp_path / "candidate.json"
    gate = tmp_path / "gate.json"
    out = tmp_path / "packet.md"
    write_json(candidate, {
        "current_version": "2026.5.7",
        "target_version": "2026.5.26",
        "help_smoke_passed": True,
    })
    write_json(gate, {
        "status": "blocked",
        "clone_verify": {"installed_version": "2026.5.7", "target_version": "2026.5.26"},
        "failures": ["openclaw clone version/help verification failed"],
        "a2a2h_drift_lines": [],
        "production_mutated_by_this_check": False,
        "spend_or_infrastructure_change": False,
        "secret_values_printed": False,
    })

    result = subprocess.run([
        "python3", str(SCRIPT),
        "--candidate-summary", str(candidate),
        "--clone-gate-summary", str(gate),
        "--output", str(out),
    ], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    assert result.returncode == 0, result.stderr
    text = out.read_text(encoding="utf-8")
    assert "Not promotion-ready" in text
    assert "openclaw clone version/help verification failed" in text
    assert "No spend or infrastructure change" in text
    assert "Secret values printed: `false`" in text


def test_promotion_packet_marks_ready_only_when_gate_verified(tmp_path):
    candidate = tmp_path / "candidate.json"
    gate = tmp_path / "gate.json"
    out = tmp_path / "packet.md"
    write_json(candidate, {
        "current_version": "2026.5.7",
        "target_version": "2026.5.26",
        "help_smoke_passed": True,
    })
    write_json(gate, {
        "status": "clone_gate_verified",
        "clone_verify": {"installed_version": "2026.5.26", "target_version": "2026.5.26"},
        "failures": [],
        "a2a2h_drift_lines": [],
        "production_mutated_by_this_check": False,
        "spend_or_infrastructure_change": False,
        "secret_values_printed": False,
    })

    result = subprocess.run([
        "python3", str(SCRIPT),
        "--candidate-summary", str(candidate),
        "--clone-gate-summary", str(gate),
        "--output", str(out),
    ], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    assert result.returncode == 0, result.stderr
    text = out.read_text(encoding="utf-8")
    assert "Promotion-ready" in text
    assert "do not upgrade production in place" in text


def test_promotion_packet_script_syntax():
    result = subprocess.run(["python3", "-m", "py_compile", str(SCRIPT)], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert result.returncode == 0, result.stderr
