---@brief
---
--- BAD_URL_github.com/nvarner/typst-lsp
---
--- Language server for Typst.

---@type vim.lsp.Config
return {
  cmd = { 'typst-lsp' },
  filetypes = { 'typst' },
  root_markers = { '.git' },
}
