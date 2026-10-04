---
description: Drive a running nvim via its RPC socket. Notify approval requests through noice with tab number + instance. Skip notify when that nvim is focused.
paths:
  - "**/*nvim*"
  - "**/nvim/**/*.lua"
globs:
  - "**/*nvim*"
  - "**/nvim/**/*.lua"
alwaysApply: false
---

<!-- dual frontmatter: paths (claude) + globs/alwaysApply (cursor); each tool ignores the other's keys. -->

# Nvim Instance Control

- Control a live nvim through `/nvim-control` (socket discovery + `--remote-send`/`--remote-expr`). Never `kill` a session to "reload" it.
- Approval needed: send one noice message to the instance the request came from: what blocks + tab number + instance id, e.g. `approval needed [tab 3, nvim-htoggle]: run migration? (y/n)`. `vim.notify` surfaces through noice when present.
- Skip the notify when that nvim is currently focused/open in front of the requester — it can already see the question. No hook for this yet; the check is manual.
