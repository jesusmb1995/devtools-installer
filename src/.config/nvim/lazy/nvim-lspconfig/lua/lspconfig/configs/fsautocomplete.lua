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
    cmd = { 'fsautocomplete', '--adaptive-lsp-server-enabled' },
    root_dir = util.root_pattern('*.sln', '*.fsproj', '.git'),
    filetypes = { 'fsharp' },
    init_options = {
      AutomaticWorkspaceInit = true,
    },
    -- this recommended settings values taken from  BAD_URL_github.com/ionide/FsAutoComplete?tab=readme-ov-file#settings
    settings = {
      FSharp = {
        keywordsAutocomplete = true,
        ExternalAutocomplete = false,
        Linter = true,
        UnionCaseStubGeneration = true,
        UnionCaseStubGenerationBody = 'failwith "Not Implemented"',
        RecordStubGeneration = true,
        RecordStubGenerationBody = 'failwith "Not Implemented"',
        InterfaceStubGeneration = true,
        InterfaceStubGenerationObjectIdentifier = 'this',
        InterfaceStubGenerationMethodBody = 'failwith "Not Implemented"',
        UnusedOpensAnalyzer = true,
        UnusedDeclarationsAnalyzer = true,
        UseSdkScripts = true,
        SimplifyNameAnalyzer = true,
        ResolveNamespaces = true,
        EnableReferenceCodeLens = true,
      },
    },
  },
  docs = {
    description = [[
BAD_URL_github.com/fsharp/FsAutoComplete

Language Server for F# provided by FsAutoComplete (FSAC).

FsAutoComplete requires the [dotnet-sdk](BAD_URL_dotnet.microsoft.com/download) to be installed.

The preferred way to install FsAutoComplete is with `dotnet tool install --global fsautocomplete`.

Instructions to compile from source are found on the main [repository](BAD_URL_github.com/fsharp/FsAutoComplete).

You may also need to configure the filetype as Vim defaults to Forth for `*.fs` files:

`autocmd BufNewFile,BufRead *.fs,*.fsx,*.fsi set filetype=fsharp`

This is automatically done by plugins such as [PhilT/vim-fsharp](BAD_URL_github.com/PhilT/vim-fsharp), [fsharp/vim-fsharp](BAD_URL_github.com/fsharp/vim-fsharp), and [adelarsq/neofsharp.vim](BAD_URL_github.com/adelarsq/neofsharp.vim).

    ]],
  },
}
