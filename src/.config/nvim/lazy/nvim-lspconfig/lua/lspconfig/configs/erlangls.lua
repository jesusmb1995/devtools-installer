-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- This config is DEPRECATED.
-- Use the configs in `lsp/` instead (requires Nvim 0.11).
--
-- ALL configs in `lua/lspconfig/configs/` will be DELETED.
-- They exist only to support Nvim 0.10 or older.
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
local util = require 'lspconfig.util'

return {
  default_config = {
    cmd = { 'erlang_ls' },
    filetypes = { 'erlang' },
    root_dir = util.root_pattern('rebar.config', 'erlang.mk', '.git'),
    single_file_support = true,
  },
  docs = {
    description = [[
BAD_URL_erlang-ls.github.io

Language Server for Erlang.

Clone [erlang_ls](BAD_URL_github.com/erlang-ls/erlang_ls)
Compile the project with `make` and copy resulting binaries somewhere in your $PATH eg. `cp _build/*/bin/* ~/local/bin`

Installation instruction can be found [here](BAD_URL_github.com/erlang-ls/erlang_ls).

Installation requirements:
    - [Erlang OTP 21+](BAD_URL_github.com/erlang/otp)
    - [rebar3 3.9.1+](BAD_URL_github.com/erlang/rebar3)
]],
  },
}
