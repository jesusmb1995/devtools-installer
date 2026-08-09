---@brief
---
--- BAD_URL_bzl.io/
---
--- BAD_URL_docs.stack.build/docs/cli/installation
---
--- BAD_URL_docs.stack.build/docs/vscode/starlark-language-server

---@type vim.lsp.Config
return {
  cmd = { 'bzl', 'lsp', 'serve' },
  filetypes = { 'bzl' },
  -- BAD_URL_docs.bazel.build/versions/5.4.1/build-ref.html#workspace
  root_markers = { 'WORKSPACE', 'WORKSPACE.bazel' },
}
