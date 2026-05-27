import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/security/openclaw-upgrade-clone-verify.py'
spec = importlib.util.spec_from_file_location('openclaw_upgrade_clone_verify', SCRIPT)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def test_clone_verified_when_installed_matches_target():
    status, record = mod.evaluate(
        target_version='2026.5.26',
        summary_path='/tmp/summary.json',
        version_stdout='openclaw 2026.5.26\n',
        version_rc=0,
        version_stderr='',
        help_rc=0,
        help_stdout='Usage: openclaw ...\n',
        help_stderr='',
        warnings=[],
    )
    assert status == 'clone_upgrade_verified'
    assert record['checks']['installed_matches_target'] is True
    assert record['production_mutated_by_this_check'] is False
    assert record['spend_or_infrastructure_change'] is False
    assert record['secret_values_printed'] is False


def test_blocks_when_production_still_old_version():
    status, record = mod.evaluate(
        target_version='2026.5.26',
        summary_path='/tmp/summary.json',
        version_stdout='openclaw 2026.5.7\n',
        version_rc=0,
        version_stderr='',
        help_rc=0,
        help_stdout='Usage: openclaw ...\n',
        help_stderr='',
        warnings=[],
    )
    assert status == 'blocked'
    assert record['installed_version'] == '2026.5.7'
    assert 'does not match target' in record['failures'][0]


def test_blocks_when_target_missing():
    status, record = mod.evaluate(
        target_version=None,
        summary_path=None,
        version_stdout='openclaw 2026.5.26\n',
        version_rc=0,
        version_stderr='',
        help_rc=0,
        help_stdout='Usage: openclaw ...\n',
        help_stderr='',
        warnings=['no candidate summary found'],
    )
    assert status == 'blocked'
    assert 'target OpenClaw version is unknown' in record['failures']
    assert record['warnings'] == ['no candidate summary found']


def test_help_smoke_failure_blocks():
    status, record = mod.evaluate(
        target_version='2026.5.26',
        summary_path='/tmp/summary.json',
        version_stdout='openclaw 2026.5.26\n',
        version_rc=0,
        version_stderr='',
        help_rc=1,
        help_stdout='',
        help_stderr='boom',
        warnings=[],
    )
    assert status == 'blocked'
    assert 'openclaw help smoke failed' in record['failures']
    assert record['help_stderr_present'] is True
