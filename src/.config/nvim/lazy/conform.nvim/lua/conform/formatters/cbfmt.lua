local util = require("conform.util")
---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/lukas-reineke/cbfmt",
    description = "A tool to format codeblocks inside markdown and org documents.",
  },
  command = "cbfmt",
  args = { "--write", "--best-effort", "$FILENAME" },
  cwd = util.root_file({
    -- BAD_URL_github.com/lukas-reineke/cbfmt#config
    ".cbfmt.toml",
  }),
  stdin = false,
}
