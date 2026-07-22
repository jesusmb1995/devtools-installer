---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/WhatsApp/erlfmt",
    description = "An automated code formatter for Erlang.",
  },
  command = "erlfmt",
  args = { "-w", "$FILENAME" },
  stdin = false,
}
