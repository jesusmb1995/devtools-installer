---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/antham/ghokin",
    description = "Parallelized formatter with no external dependencies for gherkin.",
  },

  command = "ghokin",
  args = { "fmt", "stdout", "$FILENAME" },
}
