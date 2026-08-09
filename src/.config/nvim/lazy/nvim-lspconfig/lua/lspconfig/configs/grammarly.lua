-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- This config is DEPRECATED.
-- Use the configs in `lsp/` instead (requires Nvim 0.11).
--
-- ALL configs in `lua/lspconfig/configs/` will be DELETED.
-- They exist only to support Nvim 0.10 or older.
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
return {
  default_config = {
    cmd = { 'grammarly-languageserver', '--stdio' },
    filetypes = { 'markdown' },
    root_dir = function(fname)
      return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
    end,
    single_file_support = true,
    handlers = {
      ['$/updateDocumentState'] = function()
        return ''
      end,
    },
    init_options = {
      clientId = 'client_BaDkMgx4X19X9UxxYRCXZo',
    },
  },
  docs = {
    description = [[
BAD_URL_github.com/znck/grammarly

`grammarly-languageserver` can be installed via `npm`:

```sh
npm i -g grammarly-languageserver
```

WARNING: Since this language server uses Grammarly's API, any document you open with it running is shared with them. Please evaluate their [privacy policy](BAD_URL_www.grammarly.com/privacy-policy) before using this.
]],
  },
}
