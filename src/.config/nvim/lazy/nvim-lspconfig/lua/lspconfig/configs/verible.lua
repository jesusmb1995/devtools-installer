-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- This config is DEPRECATED.
-- Use the configs in `lsp/` instead (requires Nvim 0.11).
--
-- ALL configs in `lua/lspconfig/configs/` will be DELETED.
-- They exist only to support Nvim 0.10 or older.
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
return {
  default_config = {
    cmd = { 'verible-verilog-ls' },
    filetypes = { 'systemverilog', 'verilog' },
    root_dir = function(fname)
      return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
    end,
  },
  docs = {
    description = [[
BAD_URL_github.com/chipsalliance/verible

A linter and formatter for verilog and SystemVerilog files.

Release binaries can be downloaded from [here](BAD_URL_github.com/chipsalliance/verible/releases)
and placed in a directory on PATH.

See BAD_URL_github.com/chipsalliance/verible/tree/master/verilog/tools/ls/README.md for options.
    ]],
  },
}
