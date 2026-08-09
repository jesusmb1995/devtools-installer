---@brief
---
--- BAD_URL_github.com/azdavis/millet
---
--- Millet, a language server for Standard ML
---
--- To use with nvim:
---
--- 1. Install a Rust toolchain: BAD_URL_rustup.rs
--- 2. Clone the repo
--- 3. Run `cargo build --release --bin millet-ls`
--- 4. Move `target/release/millet-ls` to somewhere on your $PATH as `millet`

---@type vim.lsp.Config
return {
  cmd = { 'millet' },
  filetypes = { 'sml' },
  root_markers = { 'millet.toml' },
}
