---
name: md-block
description: Wrap markdown output in a codeblock so it can be copypasted with formatting intact. Use when user writes /md-block.
---

# md-block

Markdown dies when pasted as rich text. A codeblock keeps it intact.

## Trigger

`/md-block`

## Procedure

1. Take the last answer (or the one the user points at).
2. Re-emit its markdown wrapped in a single ```` ```markdown ```` fence.
3. Facts, paths, commands verbatim — rewrap only, never reword.
