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
2. **Verify `@` is empty before touching anything** — `jj st` must show no uncommitted changes, or `stg status` clean. Existing changes on `@` means edits land on top of someone else's work and corrupt it. Stuck? Stop and ask. This check is mandatory, not optional.
3. Make changes in a **new child** on top — `jj new @`, then edit. Do not touch the parent.
3. Describe the child so the squash step is obvious.
4. Report concise summary with code blocks — key hunks only.

## Placement: chain vs siblings

Stack is `A -> B` and `A` needs a fixup. Ask first: does `B` need the fixup underneath it?
- Yes — `B` touches the same lines or builds on the fixed code → put fixup in the middle: `A -> fixup -> B` (rebase `B` onto the fixup). `B` then builds on fixed code.
- No — unrelated → siblings fine: `A -> {fixup, B}`.

Sibling placement with a dependent `B` leaves `B` built on broken lines. When in doubt, chain — a needless rebase is cheaper than a fixup that silently misses its dependent.

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