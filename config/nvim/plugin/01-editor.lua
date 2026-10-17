vim.pack.add({
    'https://github.com/smjonas/inc-rename.nvim',
    'https://github.com/kylechui/nvim-surround',
    'https://github.com/echasnovski/mini.pairs',
    'https://github.com/laytan/cloak.nvim',
    'https://github.com/stevearc/quicker.nvim',
    'https://github.com/LunarVim/bigfile.nvim',
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

require("cloak").setup({
    enabled = true,
    cloak_character = "*",
    highlight_group = "Comment",
    patterns = {
        {
            file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
            cloak_pattern = "=.+",
        },
        {
            file_pattern = { ".env*.yml", "*.env.yml" },
            cloak_pattern = { ":.+", "-.+" },
        },
    },
})
require("which-key").add({
    {
        mode = { "n" },
        { "<leader>tc", "<cmd>CloakToggle<cr>", desc = "[T]oggle [C]loak", noremap = true, silent = true },
    },
})

require("quicker").setup()

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

if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({ 'https://github.com/akinsho/bufferline.nvim' })

require("bufferline").setup({
    options = {
        mode = "tabs",
        always_show_bufferline = false,
        show_buffer_icons = false,
        show_close_icon = false,
        show_buffer_close_icons = false,
        indicator = {
            icon = "▎",
            style = "underline",
        },
    },
})

vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Prev tab" })
