---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_dart.dev/tools/dart-format",
    description = "Replace the whitespace in your program with formatting that follows Dart guidelines.",
  },
  command = "dart",
  args = { "format", "$FILENAME" },
  -- Using stdin does not currently work properly, because the formatter will not pick up the analysis_options.yaml file
  stdin = false,
}
