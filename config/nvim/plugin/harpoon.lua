if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
})

local harpoon = require("harpoon")
harpoon:setup()
vim.keymap.set("n", "<leader>A", function() harpoon:list():prepend() end)
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<c-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
vim.keymap.set("n", "<leader>r1", function() harpoon:list():replace_at(1) end)
vim.keymap.set("n", "<leader>r2", function() harpoon:list():replace_at(2) end)
vim.keymap.set("n", "<leader>r3", function() harpoon:list():replace_at(3) end)
vim.keymap.set("n", "<leader>r4", function() harpoon:list():replace_at(4) end)