---@brief
---
--- BAD_URL_crates.io/crates/rune-languageserver
---
--- A language server for the [Rune](BAD_URL_rune-rs.github.io/) Language,
--- an embeddable dynamic programming language for Rust

---@type vim.lsp.Config
return {
  cmd = { 'rune-languageserver' },
  filetypes = { 'rune' },
  root_markers = { '.git' },
}
