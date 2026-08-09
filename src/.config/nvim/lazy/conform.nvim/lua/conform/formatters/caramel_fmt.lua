---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_caramel.run/manual/reference/cli/fmt.html",
    description = "Format Caramel code.",
  },
  command = "caramel",
  args = { "fmt", "$FILENAME" },
  stdin = false,
}
