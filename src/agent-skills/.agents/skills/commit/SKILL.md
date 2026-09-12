---
name: commit
description: Stage and commit changes with a proper message. No push. /commit
---

# commit

Commit what is changed. Right message. No push.

## Trigger

`/commit`

## Procedure

1. Check VCS: `jj status` first, else `git status`. Neither? Say so, stop.
2. Stage: jj — nothing to stage (changes already in `@`). git — `git add -A`.
3. Message: match repo convention (`feat:`, `fix:`, `docs:`). One line. Say what bug, not "fix bug". Fixup? jj: `jj describe -m "fixup <target>"` or `jj squash --into <target>`. git: `git commit --fixup=<target>`.
4. Commit: jj — `jj commit` (or `jj squash --into <target>`). git — `git commit -m "<message>"`.
5. Report: what got committed, message, whether fixup.