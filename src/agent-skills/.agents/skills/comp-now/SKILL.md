---
name: comp-now
description: Compact current conversation into /tmp/compacted.md for later resumption via /comp-use. Use when user writes /comp-now, asks to compact, summarize context, or save session state.
---

# comp-now

Summarize the current session into `/tmp/compacted.md` so `/comp-use` can restore it.

## Trigger

User writes `/comp-now` or asks to compact / save context.

## Output file

`/tmp/compacted.md` — single global file (shared across agents). Overwrite on each invocation. Requires exception to `tmp-agent-skill`: companion rule in `.agents/permissions.json` allows `read/write:/tmp/compacted.md`.

## Procedure

1. Gather context: original goal, key decisions/constraints, files touched, commands run, pending TODOs, open questions, and any facts needed to continue without re-asking the user.
2. Write compact markdown to `/tmp/compacted.md`:

```markdown
# Compacted — YYYY-MM-DD HH:MM

## Goal
<1-2 sentences>

## Key decisions / constraints
- ...

## Files / patches touched
- path — what changed and why

## State / pending
- [ ] todo / next step

## Context to continue
<concise bullet facts the next agent needs — no fluff>

## Raw notes (optional)
<anything else worth preserving>
```

3. Keep it concise: aim < 150 lines, dense bullets, no filler. Prefer facts over prose.
4. After writing, print confirmation: `Wrote /tmp/compacted.md (N lines)` and show the first ~20 lines as preview.
5. Do not delete or rotate previous compacted files — single file only.

## Rules

- Overwrite `/tmp/compacted.md` atomically (`mkdir -p /tmp && cat > /tmp/compacted.md`).
- Never write under `$AGENT_TMP` for this skill — the contract is the global `/tmp/compacted.md` consumed by `/comp-use`.
- If `/tmp/compacted.md` cannot be written (permissions), report the error and fall back to `$AGENT_TMP/compacted.md` with a note.
