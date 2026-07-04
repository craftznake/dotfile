vim.pack.add({ 'https://github.com/akinsho/bufferline.nvim' })

require("bufferline").setup({
    options = {
        mode = "tabs",
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

