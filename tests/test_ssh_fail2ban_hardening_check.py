import importlib.util
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts/security/ssh-fail2ban-hardening-check.py'

spec = importlib.util.spec_from_file_location('ssh_fail2ban_hardening_check', SCRIPT)
checker = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(checker)


def run_check(args):
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def test_hardened_effective_sshd_output_passes(tmp_path):
    fixture = tmp_path / 'sshd-T.txt'
    fixture.write_text(
        '\n'.join([
            'port 22',
            'pubkeyauthentication yes',
            'passwordauthentication no',
            'kbdinteractiveauthentication no',
            'challengeresponseauthentication no',
            'permitrootlogin no',
            'x11forwarding no',
            'maxauthtries 3',
        ]),
        encoding='utf-8',
    )
    result = run_check(['--fixture-sshd-t', str(fixture), '--output', str(tmp_path / 'out.json')])
    assert result.returncode == 0, result.stderr + result.stdout
    payload = json.loads(result.stdout)
    assert payload['status'] == 'hardened_observed'
    assert payload['production_mutated_by_this_check'] is False
    assert payload['spend_or_infrastructure_change'] is False
    assert payload['secret_values_printed'] is False


def test_detects_weak_effective_sshd_settings(tmp_path):
    fixture = tmp_path / 'sshd-T-weak.txt'
    fixture.write_text(
        '\n'.join([
            'passwordauthentication yes',
            'kbdinteractiveauthentication no',
            'challengeresponseauthentication no',
            'permitrootlogin yes',
            'pubkeyauthentication yes',
            'x11forwarding yes',
            'maxauthtries 6',
        ]),
        encoding='utf-8',
    )
    result = run_check(['--fixture-sshd-t', str(fixture), '--output', str(tmp_path / 'out.json')])
    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload['status'] == 'hardening_required'
    assert any('passwordauthentication=yes' in failure for failure in payload['failures'])
    assert any('permitrootlogin=yes' in failure for failure in payload['failures'])
    assert any('x11forwarding=yes' in failure for failure in payload['failures'])
    assert any('maxauthtries=6' in failure for failure in payload['failures'])


def test_visible_config_without_effective_root_check_requires_privileged_verification(tmp_path):
    fixture = tmp_path / 'sshd_config'
    fixture.write_text(
        '\n'.join([
            'PasswordAuthentication no',
            'KbdInteractiveAuthentication no',
            'PermitRootLogin prohibit-password',
            'PubkeyAuthentication yes',
            'X11Forwarding no',
            'MaxAuthTries 4',
        ]),
        encoding='utf-8',
    )
    result = run_check(['--fixture-config', str(fixture), '--output', str(tmp_path / 'out.json')])
    assert result.returncode == 0, result.stderr + result.stdout
    payload = json.loads(result.stdout)
    assert payload['status'] == 'needs_privileged_verification'
    assert payload['effective_sshd_config_observed'] is False


def test_sanitizes_secret_shaped_command_text():
    text = 'token=abc123 password: hunter2 private_key=/tmp/key Authorization=Bearer secret'
    sanitized = checker.sanitize(text)
    assert 'abc123' not in sanitized
    assert 'hunter2' not in sanitized
    assert 'Bearer' not in sanitized
    assert sanitized.count('<redacted>') >= 3
