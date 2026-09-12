---
name: cmdsave
description: Save the last shell command as a named bookmark for the current project, using cmdsave from the cmd_bookmarks script. /cmdsave [name]
---

# cmdsave

Save the last command as a named bookmark. Autocomplete + `cmdrun` later.

## Trigger

`/cmdsave [name]`

## Source

`user/repos/cmd_bookmarks/savecmd.zsh` — deployed at `~/.local/share/cmd_bookmarks`. nvim plugin: `lua/savecmd-nvim.lua`.

## Procedure

1. No name? Use most recent bookmark from stats (re-save appends to it).
2. Grab last command from history (strip the `cmdsave` call).
3. Bookmark exists? Append with `&&`. Else create.
4. Update stats (name + timestamp). Refresh zsh completion cache.

## Format

`.local_cmd_bookmarks`, one per line:

```
<name>|<command>
<dep>+<dep>+<name>|<cmd1> && <cmd2>
```

Last segment = name. Earlier = deps.

## Command

```zsh
cmdsave <name>     # save as <name>
cmdsave             # save to last-used (appends)
```

## Rules

- Run the real `cmdsave` function. Don't hand-roll `.local_cmd_bookmarks` — stats, completion cache, dep parsing live there.
- Central mode stores per-project at `~/.local/share/cmd_bookmarks/<flattened_cwd>/`, not in the project dir.