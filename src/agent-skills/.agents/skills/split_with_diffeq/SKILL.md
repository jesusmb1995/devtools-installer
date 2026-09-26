---
name: split_with_diffeq
description: Split a patch into multiple patches per instructions, then verify the split diffs sum to the original. Use when user writes /split_with_diffeq <how to split>.
---

# split_with_diffeq

Split, then prove nothing was lost or added.

## Trigger

`/split_with_diffeq <how to split, e.g. "move the rename into its own patch">`

## Procedure

1. Save the original diff (`jj diff` / `stg show` / `git diff`) to a tmp file.
2. Split per instructions (`/per_patch` groups; `/per_patch_fixups` placement — chain if dependent).
3. Verify: concat the split diffs and diff against the original. Empty diff = equal = good.
4. Non-empty → fix the split, re-verify. Never hand over an unverified split.
