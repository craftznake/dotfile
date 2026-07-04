vim.pack.add({
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/b0o/incline.nvim',
})

local theme = require("craftznake.theme")

local function groups()
    local p = theme.palette()
    return {
        InclineNormal   = { guibg = p.bg,    guifg = p.fg },
        InclineNormalNC = { guibg = p.bg_nc, guifg = p.fg_nc },
    }
end

require("incline").setup({
    highlight = {
        groups = groups(),
    },
    window = { margin = { vertical = 0, horizontal = 1 } },
    hide = { cursorline = true },
    render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
        end
        local icon, color = require("nvim-web-devicons").get_icon_color(filename)
        return { { icon, guifg = color }, { " " }, { filename } }
    end,
})

theme.register("incline", function()
    require("incline").setup({ highlight = { groups = groups() } })
end)