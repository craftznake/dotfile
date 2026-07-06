vim.pack.add({ 'https://github.com/folke/snacks.nvim' })

---@diagnostic disable-next-line: missing-fields
require("snacks").setup({
    dashboard = { enabled = false },
    bigfile = { enabled = false },
    notifier = { enabled = true, timeout = 3000 },
    quickfile = { enabled = false },
    statuscolumn = { enabled = false },
    lazygit = { enabled = false },
    words = { enabled = false },
    styles = { notification = { wo = { wrap = true }, } },
})

vim.keymap.set("n", "<leader>un", function()
    require("snacks").notifier.hide()
end, { desc = "Dismiss All Notifications" })
