---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/bazelbuild/buildtools/tree/master/buildifier",
    description = "buildifier is a tool for formatting bazel BUILD and .bzl files with a standard convention.",
  },
  command = "buildifier",
  args = { "-path", "$FILENAME", "-" },
}
