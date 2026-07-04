vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    { src = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim', name = 'telescope-fzf-native.nvim' },
    'https://github.com/nvim-telescope/telescope-file-browser.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
})

local actions = require("telescope.actions")
local theme = require("craftznake.theme")

local function teleFilename(_, path)
    local tail = require("telescope.utils").path_tail(path)
    if string.len(tail) > 30 then
        tail = string.sub(tail, 0, 28) .. ".."
    end
    return string.format("%-30s %s", tail, path)
end

require("telescope").setup({
    defaults = {
        file_ignore_patterns = { "vendor/", "node_modules/", "target/" },
        mappings = {
            i = {
                ["<C-|>"] = actions.select_horizontal,
                ["<C-->"] = actions.select_vertical,
            },
            n = {
                ["<C-|>"] = actions.select_horizontal,
                ["<C-->"] = actions.select_vertical,
            },
        },
        layout_strategy = "flex",
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
        },
    },
    preview = { treesitter = false },
    pickers = {
        find_files = {
            path_display = teleFilename,
            find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
        },
    },
})

require("telescope").load_extension("fzf")
require("telescope").load_extension("file_browser")

local function apply_highlights()
    local p = theme.palette()
    local hl = vim.api.nvim_set_hl
    hl(0, "TelescopeBorder",         { fg = p.border,  bg = "none" })
    hl(0, "TelescopeNormal",         { bg = "none" })
    hl(0, "TelescopePromptNormal",   { bg = p.bg })
    hl(0, "TelescopePromptBorder",   { fg = p.border,  bg = "none" })
    hl(0, "TelescopeResultsNormal",  { fg = p.dim,     bg = "none" })
    hl(0, "TelescopeSelection",      { fg = p.fg,      bg = p.visual_bg })
    hl(0, "TelescopeSelectionCaret", { fg = p.accent,  bg = p.visual_bg })
    hl(0, "TelescopeMatching",       { fg = p.accent,  bold = true })
    hl(0, "TelescopePromptTitle",    { fg = p.fg,      bg = "none" })
    hl(0, "TelescopeResultsTitle",   { fg = p.fg,      bg = "none" })
    hl(0, "TelescopePreviewTitle",   { fg = p.fg,      bg = "none" })
end

apply_highlights()
theme.register("telescope", apply_highlights)

local builtin = require("telescope.builtin")

vim.keymap.set("n", ";f", function() builtin.find_files() end, { desc = "Open [F]iles list" })
vim.keymap.set("n", ";r", function() builtin.live_grep() end, { desc = "Open [R]egex" })
vim.keymap.set("n", ";b", function() builtin.buffers() end, { desc = "Open [B]uffers list" })
vim.keymap.set("n", ";d", function() builtin.diagnostics({ bufnr = 0 }) end, { desc = "Open [D]iagnostics (buffer)" })
vim.keymap.set("n", ";D", function() builtin.diagnostics() end, { desc = "Open [D]iagnostics (all)" })
vim.keymap.set("n", ";;", function() builtin.resume() end, { desc = "Telescope Resume Last Search" })