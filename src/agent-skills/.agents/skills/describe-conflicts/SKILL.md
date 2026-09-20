---
name: describe-conflicts
description: Summarize merge/rebase conflicts with short snippets and how to solve each. Compact terminal output + full report in a .md file. /describe-conflicts
---

# describe-conflicts

Conflicts, summed up. Terminal stays compact; details go in a file the user can open.

Load `/tmp-agent-skill` for the scratch root (`$AGENT_TMP`).

## Trigger

`/describe-conflicts`

## Procedure

1. Find conflicts: `git status --short | grep -E '^(UU|AA|DD|AU|UA|DU|UD)'`, markers (`<<<<<<<`/`=======`/`>>>>>>>`).
2. Per conflict: why it collides, both sides in 3-5 lines each, how to solve (take ours / take theirs / merge / rewrite).
3. Write full report to `$AGENT_TMP/conflicts-<slug>.md`. Print only the table:

```
| File | Why | How to solve |
|---|---|---|
| <path> | <one line> | <take/merge/rewrite> |
```

4. Need a resolution plan per file in parallel → `/team-solve-conflicts`. No edits here — analysis only.
