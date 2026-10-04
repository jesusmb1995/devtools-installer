-- projnote lazy.nvim spec. Canonical source lives in this repo
-- (nvim/projnote.lua) and is staged into the nvim config tree's
-- lua/plugins/ by generate_nvim_projnote_postrender.ab (generate
-- phase), so it is only present in bundles that enable this repo. The
-- plugin body is staged into the lazy cache by generate_nvim_projnote.ab.
-- Local dir= plugin: no network fetch. Do NOT set optional=true: this
-- lazy.nvim version's fix_optional() drops every optional plugin from the
-- resolved set, so the plugin (and its commands) would never load.
return {
  {
    dir = vim.fn.stdpath("data") .. "/lazy/projnote",
    name = "projnote",
    lazy = true,
    keys = {
      { "<leader>qn", function() require("projnote").new_note() end, mode = "n", desc = "Note: new at current line (project+file+line)" },
      { "<leader>qN", function() require("projnote").project_note() end, mode = "n", desc = "Note: go to project note (create if missing)" },
      { "<leader>qo", function() require("projnote").open_note() end, mode = "n", desc = "Note: open at current line" },
      { "<leader>qd", function() require("projnote").delete_note() end, mode = "n", desc = "Note: delete at current line" },
      { "<leader>ql", function() require("projnote").pick_project() end, mode = "n", desc = "Note: list project notes (jump/open)" },
      { "<leader>qL", function() require("projnote").pick_file() end, mode = "n", desc = "Note: list this file's notes (jump/open)" },
      { "<leader>qw", function() require("projnote").pick_all() end, mode = "n", desc = "Note: list all notes incl. other workspaces" },
      { "<leader>qW", function() require("projnote").pick_file_all() end, mode = "n", desc = "Note: list this file's notes incl. other workspaces" },
      { "<leader>q]", function() require("projnote").jump_next() end, mode = "n", desc = "Note: jump to next note in file" },
      { "<leader>q[", function() require("projnote").jump_prev() end, mode = "n", desc = "Note: jump to previous note in file" },
      { "<leader>qt", function() require("projnote").toggle_signs() end, mode = "n", desc = "Note: toggle note signs (on by default)" },
    },
    config = function()
      require("projnote").setup({})
    end,
  },
}
