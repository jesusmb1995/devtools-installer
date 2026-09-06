---
name: comp-use
description: Resume from /tmp/compacted.md written by /comp-now. Use when user writes /comp-use, asks to continue, restore context, or load compacted summary.
---

# comp-use

Restore context previously saved by `/comp-now`.

## Trigger

User writes `/comp-use` or asks to continue from compacted summary.

## Procedure

1. Check `/tmp/compacted.md` exists:
   ```bash
   ls -l /tmp/compacted.md && wc -l /tmp/compacted.md
   cat /tmp/compacted.md
   ```
   If missing, report `No /tmp/compacted.md found — run /comp-now first` and stop. Optionally check fallback `$AGENT_TMP/compacted.md` and mention it.
2. Read the full file and inject its content into current context. Treat every section (`Goal`, `Key decisions`, `Files / patches touched`, `State / pending`, `Context to continue`) as authoritative.
3. Summarize what was restored in 5-10 bullets (goal, pending todos, last state) so the user can verify.
4. Continue exactly where the previous session left off: execute the next pending step or await the user's instruction — do not re-ask for information already in the compacted file.
5. Do not modify `/tmp/compacted.md` (read-only). Updates go via an explicit `/comp-now` call.

## Rules

- Read-only — never write, truncate, or delete `/tmp/compacted.md`.
- If the file is large (> 400 lines), read it fully anyway; do not summarize away load-bearing details.
- After loading, state clearly: `Loaded /tmp/compacted.md (N lines) — continuing from: <goal>`.
