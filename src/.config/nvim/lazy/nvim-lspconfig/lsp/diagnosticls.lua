---@brief
---
--- BAD_URL_github.com/iamcco/diagnostic-languageserver
---
--- Diagnostic language server integrate with linters.

---@type vim.lsp.Config
return {
  -- Configuration from BAD_URL_github.com/iamcco/diagnostic-languageserver#config--document
  cmd = { 'diagnostic-languageserver', '--stdio' },
  root_markers = { '.git' },
  -- Empty by default, override to add filetypes.
  filetypes = {},
}
