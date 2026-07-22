---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/standardrb/standard",
    description = "Ruby's bikeshed-proof linter and formatter.",
  },
  command = "standardrb",
  args = {
    "--fix",
    "-f",
    "quiet",
    "--stderr",
    "--stdin",
    "$FILENAME",
  },
  exit_codes = { 0, 1 },
}
