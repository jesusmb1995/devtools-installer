---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/incu6us/goimports-reviser",
    description = "Right imports sorting & code formatting tool (goimports alternative).",
  },
  command = "goimports-reviser",
  args = { "-format", "$FILENAME" },
  stdin = false,
}
