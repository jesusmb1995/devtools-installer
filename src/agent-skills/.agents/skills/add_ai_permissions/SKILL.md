---
name: add_ai_permissions
description: Allow a command for the current AI terminal agent by adding it to the right permissions config. Use when user writes /add_ai_permissions <command>.
---

# add_ai_permissions

Allow `<command>` for the agent running now — edit its real permissions file, nothing else.

## Trigger

`/add_ai_permissions <command or what to allow>`

## Procedure

1. Detect the current agent (session tool / parent process / `$TERM_PROGRAM`): opencode, claude, codex, cursor, kilocode, antigravity, other.
2. Open only its permissions config (e.g. tool settings/permissions json, `.agents/permissions.json` where the harness enforces one). Never touch another agent's file.
3. Add the narrowest allow rule covering `<command>`. No blanket `*`, no shell-prefix bypass.
4. Report: file + rule added, one line each.

## Rules

- Ask first if the command looks destructive (delete, push, deploy, secrets, network send).
- Refuse exfiltration-shaped allows (secrets → network). Say why, stop.
