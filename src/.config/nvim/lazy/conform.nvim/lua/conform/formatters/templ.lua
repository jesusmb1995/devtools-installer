---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_templ.guide/developer-tools/cli/#formatting-templ-files",
    description = "Formats templ template files.",
  },
  command = "templ",
  args = { "fmt", "-stdin-filepath", "$FILENAME" },
}
