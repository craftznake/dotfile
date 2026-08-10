vim.pack.add({ 'https://github.com/mbbill/undotree' })

require("which-key").add({
    {
        mode = { "n" },
        { "<leader>tu", vim.cmd.UndotreeToggle, desc = "[U]ndo Tree", noremap = true, silent = true },
    },
})

