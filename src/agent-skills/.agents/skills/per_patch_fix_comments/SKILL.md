---
name: per_patch_fix_comments
description: Per-patch fix for review comments — group fixes per patch, then fix direct. Tiny combo of /per_patch_fixups + /pr-comments-fix-direct.
---

# per_patch_fix_comments

Combo, nothing new: `/per_patch_fixups` + `/pr-comments-fix-direct`.

## Trigger

`/per_patch_fix_comments`

## Procedure

1. Group comment fixes per patch (`/per_patch`).
2. Fix each group as a child on top (`/per_patch_fixups`) — never edit the parent. Chain vs siblings per that skill's placement rule.
3. Fix mechanics per `/pr-comments-fix-direct`. TDD needed → swap in `/pr-comments-tdd-fix-direct`.
