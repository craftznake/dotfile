if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({ 'https://github.com/stevearc/conform.nvim' })

local cache = require("craftznake.plugins.utils.cache")
local CACHE_NAMESPACE = "conform"
local conform_enabled = cache.get_cached_value(CACHE_NAMESPACE, "conform", true)
vim.g.conform_format = conform_enabled

require("conform").setup({
    default_format_opts = {
        lsp_format = "fallback",
    },
    formatters_by_ft = {
        go              = { "golangci-lint" },
        rust            = { "rustfmt" },
        json            = { "jq", "jsonlint" },
        python          = { "black" },
        javascript      = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript      = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
    },
    formatters = {
        jsonlint = {
            command = "jsonlint",
            -- jsonlint outputs the formatted JSON to stdout when using the -p flag
            args = { "-p", "-" },
        },
        prettierd = {
            condition = function()
                if vim.fs.find({ ".pretter", ".prettier.json", ".prettier.js" }, {}) then
                    return true
                else
                    return false
                end
            end,
        },
    },
})

vim.api.nvim_create_user_command("Fmt", function(args)
    local range = nil
    if args.count ~= -1 then
        local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
        range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
        }
    end
    require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
        print("🐶Autoformat disabled for this session")
        vim.g.conform_format = false
    else
        print("🐶Autoformat disabled globally")
        vim.g.conform_format = false
        cache.save_value(CACHE_NAMESPACE, "conform", false)
    end
end, { desc = "Disable conform_format-on-save", bang = true })

vim.api.nvim_create_user_command("FormatEnable", function(args)
    if args.bang then
        print("🐶Autoformat enabled for this session")
        vim.g.conform_format = true
    else
        print("🐶Autoformat enabled globally")
        vim.g.conform_format = true
        cache.save_value(CACHE_NAMESPACE, "conform", true)
    end
end, { desc = "Re-enable conform_format-on-save", bang = true })

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = vim.api.nvim_create_augroup("Craftznake", { clear = false }),
    pattern = "*",
    callback = function()
        if not vim.g.conform_format then
            print("🐶Autoformat disabled")
            return
        else
            require("conform").format({
                async = false,
                lsp_format = "fallback",
                timeout_ms = 3000,
            })
        end
    end,
})

vim.api.nvim_create_user_command("FormatStatus", function()
    local global_status = vim.g.conform_format and "enabled" or "disabled"
    print("🐶Autoformat:\nstatus: " .. global_status)
end, { desc = "Get current format status" })

