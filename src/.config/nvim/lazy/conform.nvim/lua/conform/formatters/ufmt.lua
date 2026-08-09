---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/omnilib/ufmt",
    description = "Safe, atomic formatting with black and µsort.",
  },
  command = "ufmt",
  args = { "format", "$FILENAME" },
  stdin = false,
}
