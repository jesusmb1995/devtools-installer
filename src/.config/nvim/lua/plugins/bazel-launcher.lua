-- nvim_bazel_launcher lazy.nvim spec. Canonical source lives in this repo
-- (nvim/bazel-launcher.lua) and is staged into the nvim config tree's
-- lua/plugins/ by generate_nvim_bazel_launcher_postrender.ab (generate
-- phase), so it is only present in bundles that enable this repo. The
-- plugin body is staged into the lazy cache by generate_nvim_bazel_launcher.ab.
-- Local dir= plugin: no network fetch. Do NOT set optional=true: this
-- lazy.nvim version's fix_optional() drops every optional plugin from the
-- resolved set, so the plugin (and its commands) would never load.
return {
  {
    dir = vim.fn.stdpath("data") .. "/lazy/nvim_bazel_launcher",
    name = "nvim_bazel_launcher",
    lazy = true,
    cmd = { "BazelTargets", "BazelRun", "BazelBuild", "BazelLast" },
    keys = {
      { "<leader><A-G>", "<cmd>BazelTargets<cr>", desc = "Bazel targets picker (enter=run, C-d=build)" },
    },
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("bazel-launcher").setup({})
    end,
  },
}
