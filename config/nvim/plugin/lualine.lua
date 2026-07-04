vim.pack.add({
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-lualine/lualine.nvim',
})

local theme = require("craftznake.theme")

local function location()
    return string.format("%3d:%-2d", unpack(vim.api.nvim_win_get_cursor(0)))
end

require("lualine").setup({
    options = {
        icons_enabled = true,
        section_separators = "",
        component_separators = "",
        theme = theme.lualine_theme(),
        always_divide_middle = true,
        disabled_filetypes = {
            statusline = { "TelescopePrompt", "TelescopeResults", "TelescopePreview" },
            winbar = {},
        },
        ignore_focus = { "TelescopePrompt", "TelescopeResults", "TelescopePreview" },
        globalstatus = true,
        refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
    },
    sections = {
        lualine_a = {
            {
                "mode",
                fmt = function(mode) return mode:sub(1, 1) end,
            },
        },
        lualine_b = {
            {
                "filename",
                file_status = true,
                path = 1,
                symbols = { modified = "+", readonly = "-", unnamed = "[No Name]" },
            },
        },
        lualine_c = {
            {
                "diagnostics",
                symbols = { error = "E", warn = "W", info = "I", hint = "H" },
            },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { location },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { location },
        lualine_y = {},
        lualine_z = {},
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {},
})

theme.register("lualine", function()
    require("lualine").setup({ options = { theme = theme.lualine_theme() } })
end)

