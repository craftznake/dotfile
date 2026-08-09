if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({ 'https://github.com/LunarVim/bigfile.nvim' })

require("bigfile").setup({
    filesize = 2,
    pattern = { "*" },
    features = {
        "indent_blankline",
        "illuminate",
        "lsp",
        "treesitter",
        "syntax",
        "matchparen",
        "vimopts",
        "filetype",
    },
})