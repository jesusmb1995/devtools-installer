---
name: readability_review
description: Review the current patch or stack for readability — simpler, clearer, better practices. Use when user writes /readability_review_patch or /readability_review_stack.
---

# readability_review

Readability only. Not bugs, not tests — can this be simpler to read?

## Trigger

`/readability_review_patch` (current patch) or `/readability_review_stack` (whole stack).

## Procedure

1. Read the diff (`stg show`, else `jj diff` / branch diff). One patch or the stack, per trigger.
2. Flag: convoluted control flow, needless abstraction, bad names, redundant comments (see `/stg-last-patch-nonverbosecomments`), non-idiomatic constructs.
3. Ask per flag: does an aux/helper lib already in the repo (abseil, shlib, stdlib, etc.) make it shorter and clearer? Suggest the concrete call.
4. Report, biggest win first:

```
- <file:line> — <current> → <suggested> — <why clearer>
```

5. Change nothing. Apply via `/per_patch_fixups` only if user says so.
