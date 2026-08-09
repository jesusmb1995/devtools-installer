---@brief
---
--- [BAD_URL_github.com/jeapostrophe/racket-langserver](BAD_URL_github.com/jeapostrophe/racket-langserver)
---
--- The Racket language server. This project seeks to use
--- [DrRacket](BAD_URL_github.com/racket/drracket)'s public API to provide
--- functionality that mimics DrRacket's code tools as closely as possible.
---
--- Install via `raco`: `raco pkg install racket-langserver`

---@type vim.lsp.Config
return {
  cmd = { 'racket', '--lib', 'racket-langserver' },
  filetypes = { 'racket', 'scheme' },
  root_markers = { '.git' },
}
