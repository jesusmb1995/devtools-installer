---
name: wrap-up
description: Wrap up. Summarize changes, files, caveats, stop. /wrap-up
---

# wrap-up

Close. No new work. No questions.

Trigger: `/wrap-up`, wrap up, finish, done.

1. `jj status` (or `git status`). List changed files.
2. `jj diff` (or `git diff --stat`). Key pieces only.
3. Note unfinished, blocked, caveats.
4. Stop.

Output:

```
## Done
<what changed, 2-4 lines>

## Files
- <path> — <what>

## Caveats
<none, or real ones>
```

Nothing changed? Say so. No "anything else?".