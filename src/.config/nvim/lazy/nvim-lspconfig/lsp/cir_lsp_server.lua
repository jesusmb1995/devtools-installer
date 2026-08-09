---@brief
---
--- BAD_URL_llvm.github.io/clangir
---
--- The Language Server for the LLVM ClangIR language
---
--- `cir-lsp-server` can be installed at the llvm-project repository (BAD_URL_github.com/llvm/llvm-project)

---@type vim.lsp.Config
return {
  cmd = { 'cir-lsp-server' },
  filetypes = { 'cir' },
  root_markers = { '.git' },
}
