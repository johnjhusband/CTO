import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "security" / "install-ssh-hardening-dropin.sh"


def run_script(*args, env=None):
    return subprocess.run(
        [str(SCRIPT), *args],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
        check=False,
    )


def test_dry_run_prints_hardening_config_without_writes(tmp_path):
    target = tmp_path / "99-cto-hardening.conf"
    result = run_script("--dry-run", "--target", str(target))
    assert result.returncode == 0
    assert "DRY RUN" in result.stdout
    assert "PasswordAuthentication no" in result.stdout
    assert "PermitRootLogin no" in result.stdout
    assert "X11Forwarding no" in result.stdout
    assert not target.exists()


def test_apply_requires_explicit_rollback_confirmation(tmp_path):
    target = tmp_path / "99-cto-hardening.conf"
    result = run_script("--apply", "--target", str(target), "--allow-non-ssh")
    assert result.returncode == 3
    assert "I_HAVE_ROLLBACK_ACCESS" in result.stderr
    assert not target.exists()


def test_apply_to_temp_target_writes_config_when_confirmed(tmp_path):
    target = tmp_path / "99-cto-hardening.conf"
    env = os.environ.copy()
    env["SSH_TTY"] = "/dev/pts/test"
    result = run_script(
        "--apply",
        "--target",
        str(target),
        "--confirm",
        "I_HAVE_ROLLBACK_ACCESS",
        env=env,
    )
    assert result.returncode == 0, result.stderr
    content = target.read_text()
    assert "PasswordAuthentication no" in content
    assert "KbdInteractiveAuthentication no" in content
    assert "PubkeyAuthentication yes" in content
    assert "MaxAuthTries 4" in content
    assert "Reload skipped" in result.stdout


def test_real_etc_target_refuses_non_root_apply():
    if os.geteuid() == 0:
        return
    result = run_script(
        "--apply",
        "--target",
        "/etc/ssh/sshd_config.d/99-cto-hardening.conf",
        "--confirm",
        "I_HAVE_ROLLBACK_ACCESS",
        "--allow-non-ssh",
    )
    assert result.returncode == 4
    assert "must run as root" in result.stderr
