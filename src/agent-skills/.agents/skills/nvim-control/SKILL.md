---
name: nvim-control
description: Execute commands in a running nvim instance via its RPC socket — open tabs, edit files, send notifications. Use when user writes /nvim-control, asks to drive/open/show something in their live nvim, or notify an nvim instance.
---

# nvim-control

Drive a live nvim. Never kill/restart a session to affect it.

## Find the instance

1. Embedded callers already have one: `$NVIM` is the server address (only inside `:terminal`).
2. Otherwise scan for sockets: `ls /tmp/nvim.*/` — each entry is usually `<user>/<id>/nvim.<pid>.0`. Multiple instances: pick by asking, or by matching cwd (`--remote-expr "getcwd()"` per socket).
3. No socket: no live instance — say so, do not start one uninvited.
4. Caveat: a bare TUI nvim opens no socket; only `--embed` children do. Commands sent to an embed child's socket run in its context, not on the visible UI. For full control of the main instance, start it with `--listen`, e.g. `alias nvim='nvim --listen /tmp/nvim-$USER-main.sock'`.

## Talk to it

```bash
SOCK=/tmp/nvim.user/Id4Ged/nvim.11564.0
nvim --server "$SOCK" --remote-expr "getcwd()"        # query (prints result)
nvim --server "$SOCK" --remote-send ":tabnew<CR>"      # Ex command
nvim --server "$SOCK" --remote-send ":e ~/file<CR>"    # open file (expands ~ server-side)
nvim --server "$SOCK" --remote-expr "tabpagenr('$')"   # tab count
```

`--remote-send` keys go through mappings — `<CR>` executes. Quote carefully: the string is vim keystrokes, not shell.

## Examples

```bash
# open a tab on the journal and jump to today
nvim --server "$SOCK" --remote-send ":tabnew<CR>:Journal<CR>"
# approval ping (lands in noice when present, tab number + instance included)
nvim --server "$SOCK" --remote-send ":lua vim.notify('approval needed [tab 2, nvim-htoggle]: run migration? (y/n)', vim.log.levels.WARN)<CR>"
# close the tab you opened (only tabs you opened)
nvim --server "$SOCK" --remote-send ":tabclose<CR>"
```

## Rules

- Read-only first: `--remote-expr` to inspect before `--remote-send` to change.
- Open tabs/files only when asked; close only what you opened.
- Notify text always carries tab number + instance id (see `rules/nvim.md`).
- An `--embed` child's socket also works, but commands run in its context — prefer the main instance socket when several exist.
