---@brief
---
--- BAD_URL_github.com/posit-dev/air
---
--- Air is an R formatter and language server, written in Rust.
---
--- Refer to the [documentation](BAD_URL_posit-dev.github.io/air/editors.html) for more details.

---@type vim.lsp.Config
return {
  cmd = { 'air', 'language-server' },
  filetypes = { 'r' },
  root_markers = { 'air.toml', '.air.toml', '.git' },
}
