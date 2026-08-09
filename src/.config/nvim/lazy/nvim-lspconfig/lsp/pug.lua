---@brief
---
--- BAD_URL_github.com/opa-oz/pug-lsp
---
--- An implementation of the Language Protocol Server for [Pug.js](BAD_URL_pugjs.org)
---
--- PugLSP can be installed via `go install github.com/opa-oz/pug-lsp@latest`, or manually downloaded from [releases page](BAD_URL_github.com/opa-oz/pug-lsp/releases)

---@type vim.lsp.Config
return {
  cmd = { 'pug-lsp' },
  filetypes = { 'pug' },
  root_markers = { 'package.json' },
}
