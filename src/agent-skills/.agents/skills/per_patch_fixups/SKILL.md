---
name: per_patch_fixups
description: Fix things as a child patch on top of the target, leaving the parent untouched. User squashes later. /per_patch_fixups
---

# per_patch_fixups

Like `/per_patch`. Never edit a patch in place. Build a child on top, leave parent alone, hand the squash to the user.

## Trigger

`/per_patch_fixups`

## Procedure

1. Find target patch (named, or `@`).
2. Make changes in a **new child** on top — `jj new @`, then edit. Do not touch the parent.
3. Describe the child so the squash step is obvious.
4. Report concise summary with code blocks — key hunks only.

## Placement: chain vs siblings

Stack is `A -> B` and `A` needs a fixup:
- `B` depends on the fixed lines (touches same lines/children) → chain: `A -> fixup -> B` (rebase `B` onto the fixup). `B` then builds on fixed code.
- Independent → siblings fine: `A -> {fixup, B}`.

When in doubt, chain — a needless rebase is cheaper than a fixup that silently misses its dependent.

## Output

```
## Child patch
<change-id or description>

## Changed
```diff
<key hunks>
```

## Squash
jj squash --from <child> --into <parent>
```

User squashes. You don't.