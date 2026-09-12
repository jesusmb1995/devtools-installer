---
name: commit-push
description: Stage, commit, and push changes. /commit-push
---

# commit-push

`/commit`, then push.

## Trigger

`/commit-push`

## Procedure

1. Do `/commit`: check VCS, stage, message, commit.
2. Push: jj — `jj git push` (or `jj git push --allow-new` if no upstream bookmark). git — `git push` (or `git push -u origin <branch>` first time).
3. Push fails (rejected, needs rebase, auth)? Report error, stop. No force-push. No rewriting upstream history.
4. Report: committed message + push result.

## Rules

- Never force-push unless user explicitly says so.
- Never push secrets. Commit would push a secret? Stop, warn.