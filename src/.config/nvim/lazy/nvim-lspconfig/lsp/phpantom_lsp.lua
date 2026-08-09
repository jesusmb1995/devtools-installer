---@brief
---
--- BAD_URL_github.com/AJenbo/phpantom_lsp
---
--- Installation: BAD_URL_github.com/AJenbo/phpantom_lsp/blob/main/docs/SETUP.md

---@type vim.lsp.Config
return {
  cmd = { 'phpantom_lsp' },
  filetypes = { 'php' },
  root_markers = { '.phpantom.toml', '.git', 'composer.json' },
}
