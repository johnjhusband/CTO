# BACKLOG-005 public-history scrub blocked note — 2026-05-26T22:25Z

## Selected item
P0 security/access-control: BACKLOG-005 still has a public git-history exposure after runtime Web Push identity rotation and server-side push verification.

## Why this was selected
The continuous-work priority order puts P0 security first. The full remediation is a public-history rewrite plus coordinated repository/user cutover, which is destructive and not safe for an unattended work-pump tick. The safe advancement here is to record fresh value-safe evidence, tool readiness, and the exact approval boundary so the next coordinated window starts from verified facts rather than rediscovery.

## Fresh verification
- `scripts/security/check-git-history-secret-markers.sh` syntax check: passed.
- Non-destructive history marker scan: exit code 1 as expected while exposure remains; 18 metadata-only marker rows across 197 revisions; values were not printed.
- Marker class: historical Web Push private-key material marker.
- Historical path metadata: `.vapid/private.pem`.
- Local scrub tools: `git-filter-repo` not found; `bfg` not found.
- Current safe security gate status before this artifact: latest pump reported `scripts/security/run-safe-security-gates.sh` passed after clone env secret-streaming hardening.
- User-unit health during this pump: PWA backend, OpenClaw work-pump timer, and Hermes work-pump timer active.

## Stop condition
Do not rewrite public git history, force-push, revoke broad live credentials, or require John/device re-enrollment from an unattended pump tick. Those actions can disrupt repository clones, live services, and human access.

## Next safe coordinated action
When OpenClaw/John schedules an explicit security window:
1. Install or vendor a reviewed history rewrite tool in a disposable clone, not directly in the production working tree.
2. Rewrite only the known historical Web Push private-key path/marker.
3. Run the metadata-only history scanner and safe security gates on the rewritten clone.
4. Coordinate force-push and collaborator reclone guidance.
5. Re-run live Web Push runtime/public-key verification and server-side push verification after cutover.

## Result
BACKLOG-005 remains blocked on a coordinated destructive history-scrub window, but the current exposure evidence and stop boundary are captured without printing or storing secret values.
