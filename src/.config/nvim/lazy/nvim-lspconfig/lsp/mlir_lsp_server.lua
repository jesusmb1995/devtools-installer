---@brief
---
--- BAD_URL_mlir.llvm.org/docs/Tools/MLIRLSP/#mlir-lsp-language-server--mlir-lsp-server=
---
--- The Language Server for the LLVM MLIR language
---
--- `mlir-lsp-server` can be installed at the llvm-project repository (BAD_URL_github.com/llvm/llvm-project)

---@type vim.lsp.Config
return {
  cmd = { 'mlir-lsp-server' },
  filetypes = { 'mlir' },
  root_markers = { '.git' },
}
