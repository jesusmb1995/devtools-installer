---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_source.android.com/docs/setup/reference/androidbp",
    description = "Android Blueprint file formatter.",
  },
  command = "bpfmt",
  args = { "-w", "$FILENAME" },
  stdin = false,
}
