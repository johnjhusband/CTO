import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/security/openclaw-upgrade-clone-gate.sh'


def test_clone_gate_script_syntax():
    result = subprocess.run(['bash', '-n', str(SCRIPT)], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert result.returncode == 0, result.stderr


def test_clone_gate_documents_read_only_safety_flags():
    text = SCRIPT.read_text(encoding='utf-8')
    assert 'production_mutated_by_this_check' in text
    assert 'spend_or_infrastructure_change' in text
    assert 'secret_values_printed' in text
    assert 'validate-no-spend.sh' in text
    assert 'openclaw-upgrade-clone-verify.py' in text
    assert 'A2A2H_LAST_SYNC.md' in text


def test_clone_gate_fails_closed_on_unknown_argument():
    result = subprocess.run([str(SCRIPT), '--definitely-not-valid'], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert result.returncode == 2
    assert 'unknown argument' in result.stderr
