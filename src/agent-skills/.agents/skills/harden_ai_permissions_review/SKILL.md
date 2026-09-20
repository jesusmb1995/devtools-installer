---
name: harden_ai_permissions_review
description: Review the current AI agent permissions config for dangerous or risky allows. Read-only — reports weaknesses, changes nothing.
---

# harden_ai_permissions_review

Audit the allows. Change nothing.

## Trigger

`/harden_ai_permissions_review`

## Procedure

1. Detect the current agent like `/add_ai_permissions`; open its permissions config.
2. Flag: blanket allows, shell-prefix bypasses, destructive commands (delete/push/deploy), secrets + network combos, disabled guardrails.
3. Report, worst first:

```
- <rule> — <risk> — <tighten to>
```

4. Clean? Say so in one line. Apply fixes only if user says so (`/add_ai_permissions` in reverse — narrow, one rule at a time).
