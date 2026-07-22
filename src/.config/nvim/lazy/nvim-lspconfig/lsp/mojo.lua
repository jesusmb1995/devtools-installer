---@brief
---
--- BAD_URL_github.com/modularml/mojo
---
--- `mojo-lsp-server` can be installed [via Modular](BAD_URL_developer.modular.com/download)
---
--- Mojo is a new programming language that bridges the gap between research and production by combining Python syntax and ecosystem with systems programming and metaprogramming features.

---@type vim.lsp.Config
return {
  cmd = { 'mojo-lsp-server' },
  filetypes = { 'mojo' },
  root_markers = { '.git' },
}
