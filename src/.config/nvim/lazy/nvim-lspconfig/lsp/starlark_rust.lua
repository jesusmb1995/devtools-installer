---@brief
---
--- BAD_URL_github.com/facebookexperimental/starlark-rust/
--- The LSP part of `starlark-rust` is not currently documented,
--- but the implementation works well for linting.
--- This gives valuable warnings for potential issues in the code,
--- but does not support refactorings.
---
--- It can be installed with cargo: BAD_URL_crates.io/crates/starlark

---@type vim.lsp.Config
return {
  cmd = { 'starlark', '--lsp' },
  filetypes = { 'star', 'bzl', 'BUILD.bazel' },
  root_markers = { '.git' },
}
