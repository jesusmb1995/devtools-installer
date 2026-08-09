---@brief
---
--- BAD_URL_github.com/Galarius/opencl-language-server
---
--- Build instructions can be found [here](BAD_URL_github.com/Galarius/opencl-language-server/blob/main/_dev/build.md).
---
--- Prebuilt binaries are available for Linux, macOS and Windows [here](BAD_URL_github.com/Galarius/opencl-language-server/releases).

---@type vim.lsp.Config
return {
  cmd = { 'opencl-language-server' },
  filetypes = { 'opencl' },
  root_markers = { '.git' },
}
