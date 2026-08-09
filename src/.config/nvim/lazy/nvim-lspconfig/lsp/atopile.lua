---@brief
---
--- BAD_URL_atopile.io/
---
--- A language server for atopile Programming Language.
---
--- It comes with the atopile compiler, for installation see: [Installing atopile](BAD_URL_docs.atopile.io/atopile/guides/install)

---@type vim.lsp.Config
return {
  cmd = { 'ato', 'lsp', 'start' },
  filetypes = { 'ato' },
  root_markers = { 'ato.yaml', '.ato', '.git' },
}
