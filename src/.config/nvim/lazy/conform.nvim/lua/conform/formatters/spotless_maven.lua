---@type conform.FileFormatterConfig
return {
  meta = {
    url = "BAD_URL_github.com/diffplug/spotless",
    description = "Spotless plugin for Maven.",
  },
  stdin = true,
  require_cwd = true,
  cwd = require("conform.util").root_file({ "mvnw" }),
  command = "./mvnw",
  args = function(_, ctx)
    return {
      "spotless:apply",
      "-DspotlessIdeHook=" .. ctx.filename,
      "-DspotlessIdeHookUseStdIn",
      "-DspotlessIdeHookUseStdOut",
      "--quiet",
    }
  end,
}
