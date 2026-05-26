# BACKLOG-005 secret artifact guard — 2026-05-26

## Selected item
BACKLOG-005 (P0 security): VAPID/Web Push private key rotation and history exposure.

## Before
`git status --short` showed an untracked `.vapid-new/` directory containing a candidate runtime VAPID keypair generated for rotation. The existing `.gitignore` ignored `.vapid/` but not `.vapid-new/` or future `.vapid-compromised-*` rollback directories.

## Safe action taken
Added these runtime secret directories to `.gitignore`:

- `.vapid-new/`
- `.vapid-compromised-*/`

This does not rotate keys, delete subscriptions, rewrite git history, or expose secret values. It prevents the currently generated candidate private key and future rollback copies from appearing as untracked source artifacts or being accidentally staged during BACKLOG-005 work.

## Verification
Command:

```bash
cd /opt/cto && git check-ignore -v .vapid-new/private.pem .vapid-new/public.pem .vapid-new/public.b64url .vapid-compromised-test/private.pem
```

Expected result: all paths are ignored by `.gitignore`.

## Remaining BACKLOG-005 work
Runtime rotation, push re-enrollment, and any public history rewrite remain open. Runtime rotation touches live push identity/subscriptions and should be coordinated with John/OpenClaw rather than performed inside this safe work-pump tick.
