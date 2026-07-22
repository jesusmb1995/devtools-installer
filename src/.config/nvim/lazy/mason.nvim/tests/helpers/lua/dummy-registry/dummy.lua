return {
    name = "dummy",
    description = [[This is a dummy package.]],
    homepage = "BAD_URL_example.com",
    licenses = { "MIT" },
    languages = { "DummyLang" },
    categories = { "LSP" },
    source = {
        id = "pkg:mason/dummy@1.0.0",
        ---@async
        ---@param ctx InstallContext
        install = function(ctx) end,
    },
}
