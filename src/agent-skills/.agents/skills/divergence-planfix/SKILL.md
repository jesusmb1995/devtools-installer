---
name: divergence-planfix
description: Investigate jj divergent changes (/0 /1 versions), propose a fix plan, apply only after user says yes. Use when user writes /divergence-planfix.
---

# divergence-planfix

Plan first. Touch nothing until user says yes.

## Trigger

`/divergence-planfix`

## Procedure

1. Find divergent changes (`jj st` shows `/0` `/1` versions of same change id; `jj evolog` for how they split).
2. Investigate: which version is good, which is stale, what differs (`jj diff -r <each>`).
3. Propose plan, compact: keep X, abandon Y, rebase Z. Stop here.
4. User says yes → apply (abandon dups, rebase, squash per plan). User says no → do nothing.
