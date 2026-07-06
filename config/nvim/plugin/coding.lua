vim.pack.add({
    'https://github.com/smjonas/inc-rename.nvim',
    'https://github.com/kylechui/nvim-surround',
    'https://github.com/echasnovski/mini.pairs',
})

require("inc_rename").setup()
require("nvim-surround").setup()
require("mini.pairs").setup({
    modes = { insert = true, command = false, terminal = false },
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    skip_ts = { "string" },
    skip_unbalanced = true,
    markdown = true,
})
