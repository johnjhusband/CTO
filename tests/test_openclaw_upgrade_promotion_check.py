import importlib.util
import json
import subprocess
import sys
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/security/openclaw-upgrade-promotion-check.py'

spec = importlib.util.spec_from_file_location('openclaw_upgrade_promotion_check', SCRIPT)
promotion_check = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(promotion_check)


def write_summary(tmp_path, **overrides):
    data = {
        'package': 'openclaw',
        'current_version': '2026.5.7',
        'target_version': '2026.5.26',
        'candidate_version_output': 'openclaw 2026.5.26',
        'help_smoke_passed': True,
        'production_mutation': False,
        'global_npm_mutation': False,
        'lifecycle_scripts_disabled': True,
    }
    data.update(overrides)
    path = tmp_path / 'summary.json'
    path.write_text(json.dumps(data), encoding='utf-8')
    return path


def run_check(summary, current='2026.5.7'):
    return subprocess.run(
        [sys.executable, str(SCRIPT), '--summary', str(summary), '--current-version', current],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def test_ready_summary_emits_clone_test_replace_status(tmp_path):
    result = run_check(write_summary(tmp_path))
    assert result.returncode == 0, result.stderr + result.stdout
    payload = json.loads(result.stdout)
    assert payload['status'] == 'ready_for_clone_test_replace'
    assert payload['target_version'] == '2026.5.26'
    assert payload['production_mutated_by_this_check'] is False
    assert payload['spend_or_infrastructure_change'] is False
    assert payload['secret_values_printed'] is False
    assert 'clone-test-replace' in payload['next_required_step']


def test_blocks_candidate_that_would_mutate_production(tmp_path):
    result = run_check(write_summary(tmp_path, production_mutation=True))
    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload['status'] == 'blocked'
    assert any('production_mutation=false' in failure for failure in payload['failures'])


def test_blocks_candidate_without_lifecycle_script_hardening(tmp_path):
    result = run_check(write_summary(tmp_path, lifecycle_scripts_disabled=False))
    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload['status'] == 'blocked'
    assert any('lifecycle scripts' in failure for failure in payload['failures'])


def test_current_version_parser_ignores_build_hash():
    completed = subprocess.CompletedProcess(
        ['openclaw', '--version'], 0, stdout='OpenClaw 2026.5.7 (eeef486)\n', stderr=''
    )
    with mock.patch.object(promotion_check.subprocess, 'run', return_value=completed):
        assert promotion_check.current_openclaw_version() == '2026.5.7'
