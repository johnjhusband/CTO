#!/usr/bin/env python3
"""Non-mutating SSH/fail2ban hardening verifier for CTO hosts.

The check is deliberately read-only. It prefers effective `sshd -T` output when
available, falls back to readable sshd_config snippets, and records fail2ban
status only if the current user is allowed to query it. It never changes SSH,
firewall, packages, services, or cloud resources.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "logs" / "security" / "ssh-fail2ban-hardening-check-latest.json"
SSHD_CONFIG_PATHS = [Path("/etc/ssh/sshd_config"), Path("/etc/ssh/sshd_config.d")]

DESIRED = {
    "passwordauthentication": {"no"},
    "kbdinteractiveauthentication": {"no"},
    "challengeresponseauthentication": {"no"},
    "permitrootlogin": {"no", "prohibit-password"},
    "pubkeyauthentication": {"yes"},
    "x11forwarding": {"no"},
}
MAX_AUTH_TRIES_LIMIT = 4

SECRETISH = re.compile(r"(?i)(token|secret|password|private[_ -]?key|authorization|cookie)\s*[:=]\s*\S+")


def sanitize(text: str) -> str:
    return SECRETISH.sub(lambda m: m.group(1) + "=<redacted>", text)


def run_command(argv: list[str], *, timeout: int = 10) -> tuple[int | None, str, str]:
    try:
        completed = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError:
        return None, "", f"command not found: {argv[0]}"
    except subprocess.TimeoutExpired:
        return None, "", f"command timed out after {timeout}s: {' '.join(argv)}"
    return completed.returncode, sanitize(completed.stdout), sanitize(completed.stderr)


def parse_sshd_t(output: str) -> dict[str, str]:
    settings: dict[str, str] = {}
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition(" ")
        if key and value:
            settings[key.lower()] = value.strip().lower()
    return settings


def parse_config_text(text: str) -> dict[str, str]:
    settings: dict[str, str] = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.lower().startswith("match "):
            continue
        parts = re.split(r"\s+", line, maxsplit=1)
        if len(parts) != 2:
            continue
        key, value = parts
        settings[key.lower()] = value.strip().lower()
    return settings


def read_visible_config(paths: list[Path]) -> tuple[dict[str, str], list[str]]:
    merged: dict[str, str] = {}
    sources: list[str] = []
    for path in paths:
        if path.is_file():
            try:
                merged.update(parse_config_text(path.read_text(encoding="utf-8", errors="replace")))
                sources.append(str(path))
            except OSError:
                continue
        elif path.is_dir():
            for child in sorted(path.glob("*.conf")):
                try:
                    merged.update(parse_config_text(child.read_text(encoding="utf-8", errors="replace")))
                    sources.append(str(child))
                except OSError:
                    continue
    return merged, sources


def evaluate(settings: dict[str, str], *, effective: bool) -> tuple[str, list[str], list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    for key, allowed in DESIRED.items():
        value = settings.get(key)
        if value is None:
            warnings.append(f"{key} not observed" if not effective else f"{key} missing from effective sshd output")
        elif value not in allowed:
            failures.append(f"{key}={value} (expected one of {sorted(allowed)})")

    mat = settings.get("maxauthtries")
    if mat is None:
        warnings.append("maxauthtries not observed" if not effective else "maxauthtries missing from effective sshd output")
    else:
        try:
            if int(mat) > MAX_AUTH_TRIES_LIMIT:
                failures.append(f"maxauthtries={mat} (expected <= {MAX_AUTH_TRIES_LIMIT})")
        except ValueError:
            failures.append(f"maxauthtries={mat} is not numeric")

    if failures:
        return "hardening_required", failures, warnings
    if warnings or not effective:
        return "needs_privileged_verification", failures, warnings
    return "hardened_observed", failures, warnings


def collect_fail2ban() -> dict[str, Any]:
    status_rc, status_out, status_err = run_command(["fail2ban-client", "status"])
    sshd_rc, sshd_out, sshd_err = run_command(["fail2ban-client", "status", "sshd"])
    if status_rc == 0 and sshd_rc == 0:
        state = "observed"
    elif status_rc is None or sshd_rc is None:
        state = "not_available"
    elif "permission denied" in (status_err + sshd_err).lower():
        state = "needs_privileged_verification"
    else:
        state = "check_failed"
    return {
        "state": state,
        "status_returncode": status_rc,
        "sshd_returncode": sshd_rc,
        "status_excerpt": status_out[:1200],
        "sshd_excerpt": sshd_out[:1200],
        "stderr_excerpt": (status_err + "\n" + sshd_err).strip()[:1200],
    }


def build_record(*, fixture_sshd_t: Path | None = None, fixture_config: Path | None = None) -> dict[str, Any]:
    source = "visible_config"
    effective = False
    command_error = None

    if fixture_sshd_t:
        settings = parse_sshd_t(fixture_sshd_t.read_text(encoding="utf-8"))
        source = "fixture_sshd_t"
        effective = True
        config_sources = [str(fixture_sshd_t)]
    elif fixture_config:
        settings = parse_config_text(fixture_config.read_text(encoding="utf-8"))
        config_sources = [str(fixture_config)]
    else:
        rc, out, err = run_command(["/usr/sbin/sshd", "-T"])
        if rc == 0 and out.strip():
            settings = parse_sshd_t(out)
            source = "sshd_T"
            effective = True
            config_sources = ["/usr/sbin/sshd -T"]
        else:
            settings, config_sources = read_visible_config(SSHD_CONFIG_PATHS)
            command_error = err or f"sshd -T exited {rc}"

    status, failures, warnings = evaluate(settings, effective=effective)
    fixture_mode = bool(fixture_sshd_t or fixture_config)
    fail2ban = {"state": "fixture_skipped"} if fixture_mode else collect_fail2ban()
    if not fixture_mode and fail2ban.get("state") != "observed" and status == "hardened_observed":
        status = "needs_fail2ban_verification"

    return {
        "status": status,
        "source": source,
        "effective_sshd_config_observed": effective,
        "settings_checked": {k: settings.get(k) for k in sorted(set(DESIRED) | {"maxauthtries", "allowusers", "allowgroups", "authenticationmethods", "port"})},
        "failures": failures,
        "warnings": warnings,
        "config_sources": config_sources,
        "sshd_T_error_excerpt": command_error[:800] if command_error else None,
        "fail2ban": fail2ban,
        "next_required_step": (
            "If status is not hardened_observed, run this checker with sudo or apply an approved sshd_config.d hardening drop-in "
            "only with an active rollback session/console path. Do not tighten SSH before BACKLOG-007 confirms a safe perimeter/SSH source."
        ),
        "production_mutated_by_this_check": False,
        "spend_or_infrastructure_change": False,
        "secret_values_printed": False,
        "uid": os.getuid() if hasattr(os, "getuid") else None,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Read-only SSH/fail2ban hardening check.")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Write JSON result here as well as stdout.")
    parser.add_argument("--fixture-sshd-t", type=Path, help="Test fixture containing sshd -T output.")
    parser.add_argument("--fixture-config", type=Path, help="Test fixture containing sshd_config-style directives.")
    args = parser.parse_args(argv)

    record = build_record(fixture_sshd_t=args.fixture_sshd_t, fixture_config=args.fixture_config)
    payload = json.dumps(record, indent=2, sort_keys=True)
    print(payload)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(payload + "\n", encoding="utf-8")
    return 0 if record["status"] in {"hardened_observed", "needs_privileged_verification", "needs_fail2ban_verification"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
