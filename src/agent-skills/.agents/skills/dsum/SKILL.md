---
name: dsum
description: Compact summary of recent code changes — what was touched, with small snippets. /dsum
---

# dsum

What changed. Compact. Done.

## Trigger

`/dsum`

## Procedure

1. `jj status` (or `git status --short`), then diff stat.
2. Per touched area: one line + key hunk only (5 lines max per snippet).

## Output

```
## Changed
- <path> — <what, one line>
```diff
<key hunk>
```

## Note
<unfinished / caveat, or none>
```
