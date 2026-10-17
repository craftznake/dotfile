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
    cmdline   = { enabled = false },
    messages  = { enabled = false },
    popupmenu = { enabled = false },
    lsp       = {
        progress  = { enabled = false },
        hover     = { enabled = false },
        signature = { enabled = false },
        message   = { enabled = false },
    },
    notify    = { enabled = true, view = "mini" },
    commands  = {
        -- :Noice notifications  (or :NoiceNotifications)
        notifications = {
            view = "split",
            opts = { enter = true, format = "details" },
            filter = { event = "notify" },
        },
    },
    routes    = {
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
    views     = {
        mini = {
            position = {
                -- otherwise it will override our lualine
                row = -2
            }
        }
    }
})
