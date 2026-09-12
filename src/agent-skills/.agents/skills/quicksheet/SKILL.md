---
name: quicksheet
description: Look up a keybinding in quicksheet.txt — user says what they want to do, reply with the matching key, nothing else.
---

# quicksheet

User asks how to do something in nvim/tmux/shell → grep the quicksheet, reply with the matching `action | key` line(s), shortly.

## Trigger

User writes `/quicksheet <what they want to do>`.

## Source

`~/.config/nvim/quicksheet.txt` (deployed from `user/repos/nvim/quicksheet.txt`).

## Procedure

1. `rg -i "<keywords>" ~/.config/nvim/quicksheet.txt` (fall back to the repo copy if missing).
2. Reply with only the matching lines, verbatim. No explanation, no extra text.
3. No match? Say so in one line and suggest the closest section header (`^## ` lines).
