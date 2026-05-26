# BACKLOG-006 Git History Secret Marker Scan — 2026-05-26T20:10Z

## Selected item
BACKLOG-006 (P0 security): identify secret-bearing operational patterns in git history without printing secret values or rewriting history.

## Safe step completed
Added `scripts/security/check-git-history-secret-markers.sh`, a non-destructive git-history marker scan. It reports revision prefixes, marker names, and paths only; it does not print matched lines or secret values.

The gate intentionally exits non-zero while history still contains credential-propagation markers. It does not rotate credentials and does not rewrite public history.

## Verification
```text
$ scripts/security/check-git-history-secret-markers.sh
rc=1
Git history secret marker scan found nonzero marker(s) across repository history. Values were not printed.
```

Unique marker/path summary from the verification run:

```text
provider_api_key_env scripts/install.sh
hermes_api_key_env scripts/install.sh
hermes_api_key_env scripts/install-cto.sh
```

Exact hit counts can increase by three each time a new commit preserves the current install-script propagation markers; the gate remains useful because it exits non-zero until those patterns are remediated or history is scrubbed.

Synthetic redaction-test fixtures are allowlisted so the scan focuses on operational history, not unit-test sample strings.

## Interpretation
The scan confirms BACKLOG-006 remains open: install/provisioning history contains credential-propagation patterns that should be addressed by the coordinated credential-rotation/history-cleanup path.
