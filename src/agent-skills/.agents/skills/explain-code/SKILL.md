---
name: explain-code
description: Explain why a code module/function exists and how it works. Use when user asks to explain, understand, or document code.
---

# Explain Code

Two questions only:

1. **Why** — what problem does this exist to solve? What breaks without it?
2. **How** — what does it actually do? Walk the logic top-down.

## Rules

- Read the target file/module first. Grep for callers if context is thin.
- No line-by-line narration. Group by concern.
- Name real things: function names, types, data flows.
- Keep it tight. One paragraph per question is enough unless complexity demands more.

## Output format

```
## Why
<purpose, problem it solves, what depends on it>

## How
<mechanism, data flow, key logic — top-down>
```
