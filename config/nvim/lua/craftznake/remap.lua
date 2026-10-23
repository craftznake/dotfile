local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Increment/Decrement

-- Delete a word backward
keymap.set("n", "dw", "vb_d", opts)

-- Clear search highlights with Esc
keymap.set("n", "<Esc>", ":noh<CR>", { desc = "Clear search highlights", silent = true })

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><", { desc = "resize windows left" })
keymap.set("n", "<C-w><right>", "<C-w>>", { desc = "resize windows right" })
keymap.set("n", "<C-w><up>", "<C-w>+", { desc = "resize windows up" })
keymap.set("n", "<C-w><down>", "<C-w>-", { desc = "resize windows down" })
keymap.set("n", "<C-w>d", "<C-w>q", { desc = "delete windows" })

-- Make page-up, page-down and center
keymap.set("n", "<C-d>", "<C-d>zz", opts)
keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- next and prev in search then center
keymap.set("n", "n", "nzz", opts)
keymap.set("n", "N", "Nzz", opts)

-- greatest remap ever
keymap.set("x", "<leader>p", [["_dP]], opts)

-- next greatest remap ever : asbjornHaland
keymap.set({ "n", "v" }, "<leader>y", [["+y]], opts)
keymap.set("n", "<leader>Y", [["+Y]], opts)

keymap.set("n", "Q", "<nop>")

-- Quickfix navigation
keymap.set("n", "[q", ":cprevious<CR>", { desc = "Previous Quickfix Entry" })
keymap.set("n", "]q", ":cnext<CR>", { desc = "Next Quickfix Entry" })
keymap.set("n", "[Q", ":cfirst<CR>", { desc = "First Quickfix Entry" })
keymap.set("n", "]Q", ":clast<CR>", { desc = "Last Quickfix Entry" })

keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump Forward' })
keymap.set('n', '<C-o>', '<C-o>', { desc = 'Jump Backward' })
keymap.set("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
-- tab
keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
