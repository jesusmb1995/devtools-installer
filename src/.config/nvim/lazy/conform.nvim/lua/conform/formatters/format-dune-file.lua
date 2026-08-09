---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/ocaml/dune",
    description = "Auto-formatter for Dune files.",
  },
  command = "dune",
  args = { "format-dune-file" },
  stdin = true,
}
