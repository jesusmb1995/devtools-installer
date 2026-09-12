---
name: cmdrun
description: Run a saved command bookmark by name (tab completion), optionally resolving deps first. Uses cmdrun from cmd_bookmarks. /cmdrun [name] [-d]
---

# cmdrun

Run a bookmark saved with `/cmdsave`. Tab-complete, most-recent first.

## Trigger

`/cmdrun [name] [-d]`

## Source

`user/repos/cmd_bookmarks/savecmd.zsh`.

## Procedure

1. Name given? Look it up in `.local_cmd_bookmarks`.
2. No name? `cmdlist` + ask user to pick, or run most recent.
3. `-d` + `+` deps? Run each dep first (recursively), then the bookmark.
4. `eval` the command. Update stats.

## Format

```
<name>|<command>
clean+build|make clean && make -j8
```

`cmdrun -d build` → `make clean && make -j8 && ./myapp --serve` (deps resolve recursively).

## Command

```zsh
cmdrun <name>        # run
cmdrun -d <name>     # deps first
cmdrun a b c         # several in order
cmdlist              # list all
```

## nvim

`lua/savecmd-nvim.lua` — Telescope picker. `Enter` runs, `Ctrl+D` runs with deps, `Ctrl+E` edits the line.

## Rules

- Run the real `cmdrun` function. Dep resolution and stats live there — don't hand-roll.
- Bookmark file missing? Say so, suggest `/cmdsave`.