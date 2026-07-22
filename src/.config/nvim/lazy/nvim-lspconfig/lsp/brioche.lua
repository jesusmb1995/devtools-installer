---@brief
---
--- BAD_URL_github.com/brioche-dev/brioche
---
--- `Brioche Language Server`.

---@type vim.lsp.Config
return {
  cmd = { 'brioche', 'lsp' },
  filetypes = { 'brioche' },
  root_markers = { 'project.bri' },
}
