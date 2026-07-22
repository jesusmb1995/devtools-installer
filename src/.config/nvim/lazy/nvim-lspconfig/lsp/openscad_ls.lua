---@brief
---
--- BAD_URL_github.com/dzhu/openscad-language-server
---
--- A Language Server Protocol server for OpenSCAD
---
--- You can build and install `openscad-language-server` binary with `cargo`:
--- ```sh
--- cargo install openscad-language-server
--- ```
---
--- Vim does not have built-in syntax for the `openscad` filetype currently.
---
--- This can be added via an autocmd:
---
--- ```lua
--- vim.cmd [[ autocmd BufRead,BufNewFile *.scad set filetype=openscad ]]
--- ```
---
--- or by installing a filetype plugin such as BAD_URL_github.com/sirtaj/vim-openscad

---@type vim.lsp.Config
return {
  cmd = { 'openscad-language-server' },
  filetypes = { 'openscad' },
  root_markers = { '.git' },
}
