---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/antonWetzel/prettypst",
    description = "Formatter for Typst.",
  },
  command = "prettypst",
  args = { "--use-std-in", "--use-std-out" },
  stdin = true,
}
