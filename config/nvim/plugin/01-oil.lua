vim.pack.add({
    'https://github.com/echasnovski/mini.icons',
    'https://github.com/stevearc/oil.nvim',
})

require("mini.icons").setup({})

local oil = require("oil")
oil.setup({
    default_file_explorer = true,
    columns = { "permissions" },
    delete_to_trash = false,
    lsp_file_methods = { enabled = false },
    constrain_cursor = "editable",
    watch_for_changes = false,
    use_default_keymaps = false,
    keymaps = {
        ["?"]      = { "actions.show_help", mode = "n" },
        ["q"]      = { "actions.close", mode = "n" },
        ["<CR>"]   = "actions.select",
        ["<C-w>v"] = { "actions.select", opts = { vertical = true } },
        ["<C-w>s"] = { "actions.select", opts = { horizontal = true } },
        ["<C-w>t"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"]  = "actions.preview",
        ["R"]      = "actions.refresh",
        ["P"]      = "actions.preview",
        ["-"]      = { "actions.parent", mode = "n" },
        ["_"]      = { "actions.open_cwd", mode = "n" },
        ["`"]      = { "actions.cd", mode = "n" },
        ["~"]      = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["gs"]     = { "actions.change_sort", mode = "n" },
        ["gx"]     = "actions.open_external",
        ["g."]     = { "actions.toggle_hidden", mode = "n" },
    },
    view_options = { show_hidden = false },
    win_options = { winbar = "%!v:lua.get_oil_winbar()" },
    sort = {
        { "type", "asc" },
        { "name", "asc" },
    },
})

vim.keymap.set("n", "_", function() oil.open(".") end, { desc = "Open root directory" })
vim.keymap.set("n", "-", function() oil.open() end, { desc = "Open parent directory" })

vim.api.nvim_create_user_command("Ex", function(opts)
    vim.cmd("Oil " .. (opts.args or ""))
end, { nargs = "?", complete = "dir", desc = "Oil file explorer" })

vim.api.nvim_create_user_command("CpAbsPath", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

vim.api.nvim_create_user_command("CpRelPath", function()
    local path = vim.fn.expand("%")
    vim.fn.setreg("+", path)
    vim.notify('Copied "' .. path .. '" to the clipboard!')
end, {})

function _G.get_oil_winbar()
    local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
    local dir = oil.get_current_dir(bufnr)
    if dir then
        return vim.fn.fnamemodify(dir, ":~")
    else
        return vim.api.nvim_buf_get_name(0)
    end
end
