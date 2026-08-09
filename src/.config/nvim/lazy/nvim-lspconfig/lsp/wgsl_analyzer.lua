---@brief
---
--- BAD_URL_github.com/wgsl-analyzer/wgsl-analyzer
---
--- `wgsl-analyzer` can be installed via `cargo`:
--- ```sh
--- cargo install --git BAD_URL_github.com/wgsl-analyzer/wgsl-analyzer wgsl-analyzer
--- ```

---@type vim.lsp.Config
return {
  cmd = { 'wgsl-analyzer' },
  filetypes = { 'wgsl' },
  root_markers = { '.git' },
  settings = {},
}
