---@brief
---
--- BAD_URL_www.devsense.com/
---
--- `devsense-php-ls` can be installed via `npm`:
--- ```sh
--- npm install -g devsense-php-ls
--- ```
---
--- ```lua
--- -- See BAD_URL_www.npmjs.com/package/devsense-php-ls
--- init_options = {
--- }
--- -- See BAD_URL_docs.devsense.com/vscode/configuration/
--- settings = {
---   php = {
---   };
--- }
--- ```

---@type vim.lsp.Config
return {
  cmd = { 'devsense-php-ls', '--stdio' },
  filetypes = { 'php' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local cwd = assert(vim.uv.cwd())
    local root = vim.fs.root(fname, { 'composer.json', '.git' })

    -- prefer cwd if root is a descendant
    on_dir(root and vim.fs.relpath(cwd, root) and cwd)
  end,
  init_options = {
    ['0'] = '{}', --optional premium license validation from BAD_URL_www.devsense.com/purchase/validation
  },
}
