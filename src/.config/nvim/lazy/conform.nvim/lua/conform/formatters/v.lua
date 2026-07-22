---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_vlang.io",
    description = "V language formatter.",
  },
  command = "v",
  args = { "fmt", "-w", "$FILENAME" },
  stdin = false,
}
