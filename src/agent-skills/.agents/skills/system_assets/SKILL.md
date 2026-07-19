---
name: system_assets
description: Shared host/tool recipe assets used by other skills (forge/PR-MR CLI commands, task-tracker commands). This skill is a catalog — read the listed sub-asset files in this same folder for the actual recipes. Rendered at install time from feature flags.
---

# System Assets

A library skill that holds reusable, host/tool-specific recipe files. Other skills
link here by name (`system_assets`) and read the relevant sub-asset file from this
folder — no global path reference needed.

The sub-asset files below are rendered at install time based on feature flags, so
they stay generic: when a feature is off, the file contains an *adaptive* block that
tells the agent to discover what the current machine/repo actually supports.

## Sub-assets in this folder

- `forge.md` — code-host / PR-MR CLI recipes.
  Rendered with `features.github`:
  - `true` → GitHub `gh` recipes (view/diff PRs, fetch comments, post, resolve, CI).
  - `false` → adaptive "discover what's available" block (map host from remote, pick
    the tool that exists on PATH, fall back to read-only git when nothing is present).
- `tasks.md` — task-tracker recipes.
  Rendered with `features.asana_mcp`:
  - `true` → Asana (MCP) recipes.
  - `false` → adaptive "discover what's available" block (MCP tools in session, issue
    IDs in branch/commits, user paste, local notes).

## How other skills use this

Reference the skill by name and the sub-asset file, e.g.:

> Forge commands: `system_assets` skill (`forge.md`).
> Task tracker: `system_assets` skill (`tasks.md`).

Skills should never hardcode a vendor CLI. They delegate to the matching sub-asset,
which is already gated by the relevant feature flag.
