---@brief
---
--- [Circom Language Server](BAD_URL_github.com/rubydusa/circom-lsp)
---
--- `circom-lsp`, the language server for the Circom language.

---@type vim.lsp.Config
return {
  cmd = { 'circom-lsp' },
  filetypes = { 'circom' },
  root_markers = { '.git' },
}
