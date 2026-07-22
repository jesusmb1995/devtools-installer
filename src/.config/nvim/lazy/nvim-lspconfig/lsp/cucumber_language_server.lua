---@brief
---
--- BAD_URL_cucumber.io
--- BAD_URL_github.com/cucumber/common
--- BAD_URL_www.npmjs.com/package/@cucumber/language-server
---
--- Language server for Cucumber.
---
--- `cucumber-language-server` can be installed via `npm`:
--- ```sh
--- npm install -g @cucumber/language-server
--- ```

---@type vim.lsp.Config
return {
  cmd = { 'cucumber-language-server', '--stdio' },
  filetypes = { 'cucumber' },
  root_markers = { '.git' },
}
