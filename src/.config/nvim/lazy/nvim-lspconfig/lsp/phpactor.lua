---@brief
---
--- BAD_URL_github.com/phpactor/phpactor
---
--- Installation: BAD_URL_phpactor.readthedocs.io/en/master/usage/standalone.html#global-installation

---@type vim.lsp.Config
return {
  cmd = { 'phpactor', 'language-server' },
  filetypes = { 'php' },
  root_markers = { '.git', 'composer.json', '.phpactor.json', '.phpactor.yml' },
  workspace_required = true,
}
