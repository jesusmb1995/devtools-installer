describe("quicksheet.parse", function()
  local parse = require("quicksheet.parse")

  describe("split_cheat", function()
    it("splits on first pipe and trims both sides", function()
      local desc, code = parse.split_cheat("Find files | <leader>ff")
      assert.are.equal("Find files", desc)
      assert.are.equal("<leader>ff", code)
    end)

    it("splits on the first pipe only", function()
      local desc, code = parse.split_cheat("echo | a | b | c")
      assert.are.equal("echo", desc)
      assert.are.equal("a | b | c", code)
    end)

    it("trims surrounding whitespace", function()
      local desc, code = parse.split_cheat("  Lazy  |  :Lazy  ")
      assert.are.equal("Lazy", desc)
      assert.are.equal(":Lazy", code)
    end)

    it("returns nil,nil when there is no pipe", function()
      local desc, code = parse.split_cheat("no pipe here")
      assert.is_nil(desc)
      assert.is_nil(code)
    end)
  end)

  describe("line classifiers", function()
    it("is_blank detects empty and whitespace-only lines", function()
      assert.is_true(parse.is_blank(""))
      assert.is_true(parse.is_blank("   "))
      assert.is_false(parse.is_blank("x"))
    end)

    it("is_comment matches # but not ##", function()
      assert.is_true(parse.is_comment("# a comment"))
      assert.is_false(parse.is_comment("## section @tag"))
      assert.is_false(parse.is_comment("Find files | <leader>ff"))
    end)

    it("is_section matches ##", function()
      assert.is_true(parse.is_section("## Telescope @fuzzy"))
      assert.is_false(parse.is_section("# a comment"))
    end)
  end)

  describe("section header parsing", function()
    it("section_name returns text up to the first tag", function()
      assert.are.equal("Telescope", parse.section_name("## Telescope @fuzzy"))
      assert.are.equal("QuickUpdate", parse.section_name("## QuickUpdate"))
    end)

    it("section_tags returns tags without the @ sign", function()
      assert.are.same({ "fuzzy" }, parse.section_tags("## Telescope @fuzzy"))
      assert.are.same({ "a", "b" }, parse.section_tags("## Multi @a @b"))
      assert.are.same({}, parse.section_tags("## NoTags"))
    end)
  end)

  describe("parse_lines", function()
    it("parses a multi-section sheet in file order", function()
      local lines = {
        "# top comment",
        "",
        "Find files | <leader>ff",
        "Lazy plugin manager | :Lazy",
        "## Telescope @fuzzy",
        "# comment inside section",
        "Live grep | <leader>fg",
        "no pipe skipped",
        "",
      }
      local entries = parse.parse_lines(lines)

      assert.are.equal(3, #entries)

      assert.are.equal("default", entries[1].section)
      assert.are.same({}, entries[1].tags)
      assert.are.equal("Find files", entries[1].description)
      assert.are.equal("<leader>ff", entries[1].code)

      assert.are.equal("default", entries[2].section)
      assert.are.equal(":Lazy", entries[2].code)

      assert.are.equal("Telescope", entries[3].section)
      assert.are.same({ "fuzzy" }, entries[3].tags)
      assert.are.equal("Live grep", entries[3].description)
      assert.are.equal("<leader>fg", entries[3].code)
    end)
  end)
end)
