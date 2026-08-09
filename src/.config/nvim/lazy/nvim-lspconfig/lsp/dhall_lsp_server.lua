---@brief
---
--- BAD_URL_github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server
---
--- language server for dhall
---
--- `dhall-lsp-server` can be installed via cabal:
--- ```sh
--- cabal install dhall-lsp-server
--- ```
--- prebuilt binaries can be found [here](BAD_URL_github.com/dhall-lang/dhall-haskell/releases).

---@type vim.lsp.Config
return {
  cmd = { 'dhall-lsp-server' },
  filetypes = { 'dhall' },
  root_markers = { '.git' },
}
