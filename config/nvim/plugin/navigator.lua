vim.pack.add({ 'https://github.com/christoomey/vim-tmux-navigator' })
vim.g.tmux_navigator_no_mappings = 1

-- This is introduce in my transition time from tmux to herd
local function nav(wincmd, dir)
    local prev = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. wincmd)
    if vim.api.nvim_get_current_win() ~= prev then
        return -- moved within Neovim
    end
    -- At a split edge: cross into the surrounding multiplexer.
    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
        local herdr = vim.env.HERDR_BIN_PATH
        if herdr == nil or herdr == "" then
            herdr = "herdr"
        end
        vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
    elseif vim.env.TMUX and vim.env.TMUX ~= "" then
        local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
        pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
    end
end

local function map(lhs, wincmd, dir, desc)
    vim.keymap.set("n", lhs, function()
        nav(wincmd, dir)
    end, { silent = true, noremap = true, desc = desc })
end

map("<C-h>", "h", "left", "Navigate left (vim/herdr)")
map("<C-j>", "j", "down", "Navigate down (vim/herdr)")
map("<C-k>", "k", "up", "Navigate up (vim/herdr)")
map("<C-l>", "l", "right", "Navigate right (vim/herdr)")

-- local smart_splits = require("smart-splits")
-- smart_splits.setup({
--     ignored_buftypes = { "nofile", "quickfix", "prompt" },
--     default_amount = 3,
--     at_edge = "wrap",
--     float_win_behavior = "previous",
--     move_cursor_same_row = true,
--     cursor_follows_swapped_bufs = false,
--     ignored_events = { "BufEnter", "WinEnter" },
--     disable_multiplexer_nav_when_zoomed = true,
--     log_level = "debug",
-- })
--

-- -- Nvim-tmux navigation enabled
-- require("which-key").add({
--     {
--         mode = { "n" },
--         { "<C-h>", smart_splits.move_cursor_left,  desc = "move cursor left",  noremap = true, silent = true },
--         { "<C-j>", smart_splits.move_cursor_down,  desc = "move cursor down",  noremap = true, silent = true },
--         { "<C-k>", smart_splits.move_cursor_up,    desc = "move cursor up",    noremap = true, silent = true },
--         { "<C-l>", smart_splits.move_cursor_right, desc = "move cursor right", noremap = true, silent = true },
--     },
-- })
