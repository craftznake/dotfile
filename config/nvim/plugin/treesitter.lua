vim.pack.add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-context',
})

require("nvim-treesitter").install({
    "vimdoc", "javascript", "typescript", "c",
    "lua", "rust", "jsdoc", "bash", "go",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "vimdoc", "javascript", "typescript", "c", "lua", "rust", "jsdoc", "bash", "go" },
    callback = function()
        vim.treesitter.start()
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        vim.wo.foldlevel = 99
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

require("treesitter-context").setup({
    enable = true,
    multiwindow = false,
    max_lines = 1,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 20,
    trim_scope = "outer",
    mode = "cursor",
    separator = nil,
    zindex = 20,
    on_attach = nil,
})
