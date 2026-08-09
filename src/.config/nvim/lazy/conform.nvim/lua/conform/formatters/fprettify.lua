---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/fortran-lang/fprettify",
    description = "Auto-formatter for modern fortran source code.",
  },
  command = "fprettify",
  args = {
    -- --silent is recommended for editor integrations BAD_URL_github.com/fortran-lang/fprettify?tab=readme-ov-file#editor-integration
    "--silent",
    "$FILENAME",
  },
  stdin = false,
}
