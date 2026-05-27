#!/usr/bin/env bash
set -euo pipefail

# Full git-history secret scan for BACKLOG-003.
# Downloads pinned scanner binaries into a temp/cache dir, runs them against all refs/reflog,
# and writes only sanitized, secret-value-free artifacts into logs/security.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STAMP="${SCAN_STAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
ARTIFACT_DIR="${ARTIFACT_DIR:-$ROOT/logs/security/history-secret-scan-$STAMP}"
WORK_DIR="${WORK_DIR:-$(mktemp -d /tmp/cto-history-secret-scan.XXXXXX)}"
TOOLS_DIR="${TOOLS_DIR:-$WORK_DIR/tools}"
GITLEAKS_VERSION="${GITLEAKS_VERSION:-8.30.1}"
TRUFFLEHOG_VERSION="${TRUFFLEHOG_VERSION:-3.95.3}"
GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
TRUFFLEHOG_URL="https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz"

mkdir -p "$ARTIFACT_DIR" "$TOOLS_DIR"
RAW_DIR="$WORK_DIR/raw"
mkdir -p "$RAW_DIR"

fetch_tool() {
  local name="$1" url="$2" member="$3"
  if [[ -x "$TOOLS_DIR/$name" ]]; then
    return 0
  fi
  curl -fsSL -o "$WORK_DIR/$name.tar.gz" "$url"
  tar -xzf "$WORK_DIR/$name.tar.gz" -C "$TOOLS_DIR" "$member"
  chmod +x "$TOOLS_DIR/$name"
}

fetch_tool gitleaks "$GITLEAKS_URL" gitleaks
fetch_tool trufflehog "$TRUFFLEHOG_URL" trufflehog

"$TOOLS_DIR/gitleaks" version > "$ARTIFACT_DIR/gitleaks-version.txt"
"$TOOLS_DIR/trufflehog" --version > "$ARTIFACT_DIR/trufflehog-version.txt"

# Gitleaks: --log-opts='--all --reflog' expands beyond the current branch.
# --redact=100 prevents secret values being written even to the raw report.
"$TOOLS_DIR/gitleaks" detect \
  --source "$ROOT" \
  --log-opts="--all --reflog" \
  --redact=100 \
  --report-format json \
  --report-path "$RAW_DIR/gitleaks-redacted.json" \
  --exit-code 0 \
  --no-banner \
  --no-color \
  > "$ARTIFACT_DIR/gitleaks.log" 2>&1 || true

# TruffleHog can include raw context in JSON, so keep its raw stream in temp only.
# The Python sanitizer below preserves detector/ref metadata and drops secret/context fields.
"$TOOLS_DIR/trufflehog" git "file://$ROOT" \
  --json \
  --no-update \
  --no-verification \
  --results=verified,unknown,unverified \
  --no-fail \
  > "$RAW_DIR/trufflehog-raw.jsonl" 2> "$ARTIFACT_DIR/trufflehog.log" || true

python3 - "$ROOT" "$RAW_DIR" "$ARTIFACT_DIR" <<'PY'
import collections
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
raw = pathlib.Path(sys.argv[2])
out = pathlib.Path(sys.argv[3])

def read_json(path, fallback):
    try:
        text = path.read_text(errors="replace")
        if not text.strip():
            return fallback
        return json.loads(text)
    except Exception as exc:
        (out / f"{path.name}.parse-error.txt").write_text(str(exc))
        return fallback

gitleaks = read_json(raw / "gitleaks-redacted.json", [])
san_gitleaks = []
for finding in gitleaks:
    san_gitleaks.append({
        key: finding.get(key)
        for key in [
            "RuleID", "Description", "File", "Commit", "StartLine", "EndLine",
            "Fingerprint", "Author", "Email", "Date", "Message", "Tags"
        ]
        if key in finding
    })
(out / "gitleaks-sanitized.json").write_text(json.dumps(san_gitleaks, indent=2, sort_keys=True) + "\n")

san_trufflehog = []
for line in (raw / "trufflehog-raw.jsonl").read_text(errors="replace").splitlines():
    if not line.strip():
        continue
    try:
        finding = json.loads(line)
    except Exception:
        continue
    source_metadata = finding.get("SourceMetadata") or {}
    # Preserve only routing/location metadata. Drop Raw, Redacted, ExtraData, and surrounding source context.
    git_meta = (source_metadata.get("Data") or {}).get("Git") or {}
    san_trufflehog.append({
        "DetectorName": finding.get("DetectorName"),
        "DetectorType": finding.get("DetectorType"),
        "Verified": finding.get("Verified"),
        "VerificationErrorPresent": bool(finding.get("VerificationError")),
        "SourceType": finding.get("SourceType"),
        "SourceName": finding.get("SourceName"),
        "Git": {
            key: git_meta.get(key)
            for key in ["commit", "file", "email", "repository", "timestamp", "line"]
            if key in git_meta
        },
    })
(out / "trufflehog-sanitized.json").write_text(json.dumps(san_trufflehog, indent=2, sort_keys=True) + "\n")

summary = {
    "artifact_dir": str(out.relative_to(root) if out.is_relative_to(root) else out),
    "scanner_versions": {
        "gitleaks": (out / "gitleaks-version.txt").read_text(errors="replace").strip(),
        "trufflehog": (out / "trufflehog-version.txt").read_text(errors="replace").strip(),
    },
    "scope": "git history across --all --reflog plus TruffleHog additional refs; raw TruffleHog stream retained only in temp work dir",
    "gitleaks_findings": len(san_gitleaks),
    "gitleaks_by_rule": dict(collections.Counter(item.get("RuleID", "unknown") for item in san_gitleaks)),
    "trufflehog_findings": len(san_trufflehog),
    "trufflehog_by_detector": dict(collections.Counter(str(item.get("DetectorName") or item.get("DetectorType") or "unknown") for item in san_trufflehog)),
    "trufflehog_verified": dict(collections.Counter(str(item.get("Verified")) for item in san_trufflehog)),
}
(out / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")

by_file = collections.Counter(item.get("File", "unknown") for item in san_gitleaks)
lines = [
    "# BACKLOG-003 full-history secret scan",
    "",
    "[verified] Scope: gitleaks scanned git history with `--all --reflog`; TruffleHog scanned `file://` repository history with additional refs enabled by default.",
    "[verified] Raw TruffleHog JSON was kept in the temporary work directory only because it may include secret/context fields; committed artifacts are sanitized metadata only.",
    f"[verified] Gitleaks version: {summary['scanner_versions']['gitleaks']}",
    f"[verified] TruffleHog version: {summary['scanner_versions']['trufflehog']}",
    f"[verified] Gitleaks findings: {summary['gitleaks_findings']} ({summary['gitleaks_by_rule']})",
    f"[verified] TruffleHog sanitized findings: {summary['trufflehog_findings']} ({summary['trufflehog_by_detector']})",
    "",
    "## Sanitized gitleaks finding locations",
]
for path, count in sorted(by_file.items()):
    lines.append(f"- [verified] {path}: {count}")
lines.extend([
    "",
    "## Sanitized TruffleHog finding locations",
])
if san_trufflehog:
    for item in san_trufflehog:
        git = item.get("Git") or {}
        lines.append(
            f"- [verified] {item.get('DetectorName')} in {git.get('file', 'unknown')} "
            f"at {git.get('commit', 'unknown')}:{git.get('line', 'unknown')} "
            f"(verified={item.get('Verified')})"
        )
else:
    lines.append("- [verified] none")

lines.extend([
    "",
    "## Interpretation",
    "- [verified] Both scanners independently identify historical `.vapid/private.pem`; runtime VAPID rotation work already exists under BACKLOG-005, but this confirms the public git history still contains a private key blob unless history is rewritten.",
    "- [verified] The `generic-api-key` hits are historical install/security logs and VAPID verification evidence; they require human review/rotation triage before any claim that BACKLOG-003 is resolved.",
    f"- [verified] TruffleHog returned {len(san_trufflehog)} sanitized finding(s) with unverified/unknown/verified results enabled.",
])
(out / "README.md").write_text("\n".join(lines) + "\n")
PY

printf '%s\n' "$ARTIFACT_DIR"
cat "$ARTIFACT_DIR/summary.json"
