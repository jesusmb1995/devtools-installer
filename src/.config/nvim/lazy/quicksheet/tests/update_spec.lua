describe("quicksheet.update", function()
  local update = require("quicksheet.update")

  describe("normalize", function()
    it("trims ends without lowercasing", function()
      assert.are.equal("<Leader>ff", update.normalize("  <Leader>ff "))
      assert.are.equal(":Lazy", update.normalize(":Lazy"))
    end)
  end)

  describe("is_skippable", function()
    it("skips blank lhs", function()
      assert.is_true(update.is_skippable("   "))
    end)

    it("skips the default prefixes", function()
      assert.is_true(update.is_skippable("<Plug>(myplug)"))
      assert.is_true(update.is_skippable("<SNR>1_autocmd"))
      assert.is_false(update.is_skippable("<leader>ff"))
    end)

    it("skips matching custom patterns and leaves others alone", function()
      local opts = { skip_lhs_prefixes = {}, skip_patterns = { "^<D>" } }
      assert.is_true(update.is_skippable("<D>x", opts))
      assert.is_false(update.is_skippable("<leader>x", opts))
    end)
  end)

  describe("filter_new", function()
    local existing = {
      { code = "<leader>ff" },
      { code = "<Plug>kept" },
    }

    it("drops overlaps and skippables, keeping order", function()
      local candidates = {
        { lhs = "<leader>ff", desc = "Find files" }, -- overlap -> drop
        { lhs = "<Plug>plug", desc = "Plug" }, -- skippable -> drop
        { lhs = "<leader>fg", desc = "Live grep" }, -- keep
        { lhs = ":Lazy", desc = "Lazy" }, -- keep
      }
      local new = update.filter_new(existing, candidates)

      assert.are.equal(2, #new)
      assert.are.equal("<leader>fg", new[1].lhs)
      assert.are.equal(":Lazy", new[2].lhs)
    end)

    it("dedupes candidates by lhs, first wins", function()
      local candidates = {
        { lhs = "<leader>x", desc = "first" },
        { lhs = "<leader>x", desc = "second" },
      }
      local new = update.filter_new({}, candidates)

      assert.are.equal(1, #new)
      assert.are.equal("first", new[1].desc)
    end)
  end)

  describe("to_cheat_line", function()
    it("uses the desc when present", function()
      assert.are.equal(
        "Find files | <leader>ff",
        update.to_cheat_line({ lhs = "<leader>ff", desc = "Find files" })
      )
    end)

    it("synthesizes a desc when missing", function()
      assert.are.equal(
        "Mapping <leader>ff | <leader>ff",
        update.to_cheat_line({ lhs = "<leader>ff" })
      )
    end)
  end)

  describe("build_append_block", function()
    it("returns empty string for no entries", function()
      assert.are.equal("", update.build_append_block({}))
    end)

    it("renders a section header and one line per entry", function()
      local new = {
        { lhs = "<leader>fg", desc = "Live grep" },
        { lhs = ":Lazy", desc = "Lazy" },
      }
      assert.are.equal(
        "## QuickUpdate\nLive grep | <leader>fg\nLazy | :Lazy\n",
        update.build_append_block(new)
      )
    end)

    it("honors a custom section name", function()
      local new = { { lhs = "gx", desc = "Open link" } }
      assert.are.equal(
        "## Mine\nOpen link | gx\n",
        update.build_append_block(new, "Mine")
      )
    end)
  end)
end)
