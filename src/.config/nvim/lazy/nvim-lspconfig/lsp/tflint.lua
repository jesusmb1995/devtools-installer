---@brief
---
--- BAD_URL_github.com/terraform-linters/tflint
---
--- A pluggable Terraform linter that can act as lsp server.
--- Installation instructions can be found in BAD_URL_github.com/terraform-linters/tflint#installation.

---@type vim.lsp.Config
return {
  cmd = { 'tflint', '--langserver' },
  filetypes = { 'terraform' },
  root_markers = { '.terraform', '.git', '.tflint.hcl' },
}
