---
name: review-stack-up
description: Check if review comments on the current patch also apply to other patches in the stack with the same thematic issue. /review-stack-up
---

# review-stack-up

Review comment fixed on one patch? Same theme may rot unfixed on sibling patches. Check up the stack.

## Trigger

`/review-stack-up`

## Procedure

1. Get current patch comments (open/unresolved; forge recipes: `system_assets` skill, `forge.md`).
2. List the stack (`stg series`, else `jj log` / branch diff).
3. Per comment, extract the theme (not the line — the rule behind it).
4. Grep each sibling patch for the same theme.
5. Report only hits:

```
- <theme> — fixed in <patch-A>, also present in <patch-B> (<file:line>)
```

6. No hits? Say so in one line. No code changes — analysis only.
