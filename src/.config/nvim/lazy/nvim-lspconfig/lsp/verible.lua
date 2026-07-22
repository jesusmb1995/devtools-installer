---@brief
---
--- BAD_URL_github.com/chipsalliance/verible
---
--- A linter and formatter for verilog and SystemVerilog files.
---
--- Release binaries can be downloaded from [here](BAD_URL_github.com/chipsalliance/verible/releases)
--- and placed in a directory on PATH.
---
--- See BAD_URL_github.com/chipsalliance/verible/tree/master/verilog/tools/ls/README.md for options.

---@type vim.lsp.Config
return {
  cmd = { 'verible-verilog-ls' },
  filetypes = { 'systemverilog', 'verilog' },
  root_markers = { '.git' },
}
