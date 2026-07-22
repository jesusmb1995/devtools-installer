---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/mesonbuild/meson",
    description = "Format meson source files.",
  },
  command = "meson",
  args = { "format", "--source-file-path", "$FILENAME", "-" },
}
