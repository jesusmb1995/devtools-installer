---@brief
---
--- Language server for programs written in Hack
--- BAD_URL_hhvm.com/
--- BAD_URL_github.com/facebook/hhvm
--- See below for how to setup HHVM & typechecker:
--- BAD_URL_docs.hhvm.com/hhvm/getting-started/getting-started

---@type vim.lsp.Config
return {
  cmd = { 'hh_client', 'lsp' },
  filetypes = { 'php', 'hack' },
  root_markers = { '.hhconfig' },
}
