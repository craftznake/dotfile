if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({
    'https://github.com/rcarriga/nvim-notify',
    { src = 'https://github.com/j-hui/fidget.nvim', version = 'v1.6.1' },
    'https://github.com/echasnovski/mini.animate',
    'https://github.com/shellRaining/hlchunk.nvim',
})

require("notify").setup({ timeout = 5000 })
require("fidget").setup()
require("mini.animate").setup({ scroll = { enable = false } })
require("hlchunk").setup({
    line_num = {
        enable = true,
        style = "#C39898",
    },
    chunk = {
        enable = true,
        priority = 15,
        style = {
            { fg = "#DBB5B5" },
            { fg = "#c21f30" },
        },
        use_treesitter = true,
        chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = ">",
        },
        textobject = "",
        max_file_size = 1024 * 1024,
        error_sign = true,
    },
})
