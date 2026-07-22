---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/ocaml-ppx/ocamlformat",
    description = "Auto-formatter for OCaml code.",
  },
  command = "ocamlformat",
  args = { "--enable-outside-detected-project", "--name", "$FILENAME", "-" },
}
