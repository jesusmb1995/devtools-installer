--- Telescope extension entry point: `:Telescope quicksheet`.
return require("telescope").register_extension({
  exports = {
    quicksheet = require("quicksheet.telescope").pick,
  },
})
