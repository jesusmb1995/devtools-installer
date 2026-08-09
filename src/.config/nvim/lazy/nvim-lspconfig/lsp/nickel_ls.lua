---@brief
---
--- Nickel Language Server
---
--- BAD_URL_github.com/tweag/nickel
---
--- `nls` can be installed with nix, or cargo, from the Nickel repository.
--- ```sh
--- echo "OFFLINE: no git clone" # git clone BAD_URL_github.com/tweag/nickel.git
--- ```
---
--- Nix:
--- ```sh
--- cd nickel
--- nix-env -f . -i
--- ```
---
--- cargo:
--- ```sh
--- cd nickel/lsp/nls
--- cargo install --path .
--- ```
---
--- In order to have lspconfig detect Nickel filetypes (a prerequisite for autostarting a server),
--- install the [Nickel vim plugin](BAD_URL_github.com/nickel-lang/vim-nickel).

---@type vim.lsp.Config
return {
  cmd = { 'nls' },
  filetypes = { 'ncl', 'nickel' },
  root_markers = { '.git' },
}
