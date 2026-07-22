---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_docs.astral.sh/ruff/",
    description = "An extremely fast Python linter, written in Rust. Fix lint errors.",
  },
  command = "ruff",
  args = {
    "check",
    "--fix",
    "--force-exclude",
    "--exit-zero",
    "--no-cache",
    "--stdin-filename",
    "$FILENAME",
    "-",
  },
  stdin = true,
  cwd = require("conform.util").root_file({
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
  }),
}
