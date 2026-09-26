---
name: just-dpatch
description: Justify the current patch — why these changes are needed, summarized. Use when user writes /just-dpatch.
---

# just-dpatch

Not what changed — why it had to change.

## Trigger

`/just-dpatch`

## Procedure

1. Read the current patch diff.
2. Answer, compact (a few bullets, not the diff retold):
   - Problem: what breaks / what is missing without this?
   - Why this shape: why this fix over the obvious alternatives?
3. Skip mechanics already visible in the diff.
