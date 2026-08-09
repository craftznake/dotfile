if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({ 'https://github.com/folke/which-key.nvim' })

require("which-key").setup({
    preset = "classic",
    spec = {
        {
            mode = { "n", "v" },
            { "<leader>m", group = "make" },
            { "<leader>r", group = "restart" },
            { "<leader>v", group = "view" },
            { "<leader>z", group = "zen" },
            { "<leader>t", group = "toggle/term" },
        },
        {
            mode = { "n", "v" },
            { "<leader><tab>", group = "tabs" },
            { "<leader>b",     group = "buffer" },
            { "<leader>c",     group = "code" },
            { "<leader>d",     group = "debug" },
            { "<leader>f",     group = "file/find" },
            { "<leader>g",     group = "git" },
            { "<leader>gh",    group = "hunks" },
            { "<leader>q",     group = "quit/session" },
            { "<leader>s",     group = "search" },
            { "<leader>sn",    group = "noice" },
            { "<leader>u",     group = "ui" },
            { "<leader>w",     group = "windows" },
            { "<leader>x",     group = "diagnostics/quickfix" },
            { "[",             group = "prev" },
            { "]",             group = "next" },
            { "g",             group = "goto" },
            { "gs",            group = "surround" },
        },
    },
})
