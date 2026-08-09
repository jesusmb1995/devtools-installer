---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/rokucommunity/brighterscript-formatter",
    description = "A code formatter for BrighterScript (and BrightScript).",
  },
  command = "bsfmt",
  args = { "$FILENAME", "--write" },
  stdin = false,
}
