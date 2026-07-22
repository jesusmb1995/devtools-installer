---@brief
---
--- BAD_URL_github.com/crystal-lang-tools/scry
---
--- Crystal language server.

---@type vim.lsp.Config
return {
  cmd = { 'scry' },
  filetypes = { 'crystal' },
  root_markers = { 'shard.yml', '.git' },
}
