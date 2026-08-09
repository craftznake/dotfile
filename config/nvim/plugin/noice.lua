if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({
    'https://github.com/MunifTanjim/nui.nvim',
    'https://github.com/folke/noice.nvim',
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(event)
        vim.schedule(function()
            require("noice.text.markdown").keys(event.buf)
        end)
    end,
})

require("noice").setup({
    routes = {
        {
            view = "notify",
            filter = { event = "msg_showmode" },
        },
        {
            filter = { event = "notify", find = "No information available" },
            opts = { skip = true },
        },
        {
            filter = {
                event = "msg_show",
                any = {
                    { find = "%d+L, %d+B" },
                    { find = "; after #%d+" },
                    { find = "; before #%d+" },
                    { find = "%d fewer lines" },
                    { find = "%d more lines" },
                },
            },
            view = "mini",
        },
    },
    all = {
        view = "split",
        opts = { enter = true, format = "details" },
        filter = {},
    },
    cmdline = {
        enabled = true,
        view = "cmdline",
        format = {
            cmdline     = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
            search_up   = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
            filter      = { pattern = "^:%s*!", icon = "$", lang = "bash" },
            lua         = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
            help        = { pattern = "^:%s*he?l?p?%s+", icon = "" },
            calculator  = { pattern = "^=", icon = "", lang = "vimnormal" },
            input       = { view = "cmdline", icon = "󰥻 " },
        },
    },
    popupmenu = { enabled = true, view = "cmdline" },
    presets = {
        bottom_search = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
    },
    views = {
        cmdline_input = { view = "cmdline", border = nil },
    },
})