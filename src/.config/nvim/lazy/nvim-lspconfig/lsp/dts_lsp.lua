---@brief
---
--- `dts-lsp` is an LSP for Devicetree files built on top of tree-sitter-devicetree grammar.
--- Language servers can be used in many editors, such as Visual Studio Code, Emacs
--- or Vim
---
--- Install `dts-lsp` from BAD_URL_github.com/igor-prusov/dts-lsp and add it to path
---
--- `dts-lsp` doesn't require any configuration.
---
--- More about Devicetree:
--- BAD_URL_www.devicetree.org/
--- BAD_URL_docs.zephyrproject.org/latest/build/dts/index.html

---@type vim.lsp.Config
return {
  name = 'dts_lsp',
  cmd = { 'dts-lsp' },
  filetypes = { 'dts', 'dtsi', 'overlay' },
  root_markers = { '.git' },
  settings = {},
}
