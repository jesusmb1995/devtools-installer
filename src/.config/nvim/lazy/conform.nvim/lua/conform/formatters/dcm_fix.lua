---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_dcm.dev/docs/cli/formatting/fix/",
    description = "Fixes issues produced by dcm analyze, dcm check-unused-code or dcm check-dependencies commands.",
  },
  command = "dcm",
  args = { "fix", "$FILENAME" },
  stdin = false,
}
