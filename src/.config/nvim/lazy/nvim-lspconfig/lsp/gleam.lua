---@brief
---
--- BAD_URL_github.com/gleam-lang/gleam
---
--- A language server for Gleam Programming Language.
---
--- It comes with the Gleam compiler, for installation see: [Installing Gleam](BAD_URL_gleam.run/getting-started/installing/)

---@type vim.lsp.Config
return {
  cmd = { 'gleam', 'lsp' },
  filetypes = { 'gleam' },
  root_markers = { 'gleam.toml', '.git' },
}
