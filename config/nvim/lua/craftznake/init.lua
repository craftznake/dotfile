require("craftznake.set")
require("craftznake.packages")
require("craftznake.remap")
require("craftznake.theme").setup()

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local CraftznakeGroup = augroup("Craftznake", { clear = false })
local YankGroup = augroup("HighlightYank", {})

function R(name) require("plenary.reload").reload_module(name) end

-- Auto highlight next occur of yanked word
autocmd({ "TextYankPost" }, {
    group = YankGroup,
    pattern = "*",
    callback = function()
        vim.hl.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = CraftznakeGroup,
    pattern = "*",
    callback = function(args)
        -- Clear diagnostics before save to ensure fresh diagnostics
        vim.diagnostic.reset(nil, args.buf)
    end,
})

autocmd("LspAttach", {
    group = CraftznakeGroup,
    callback = function(ev)
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
        end
        map("n", "gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        map("n", "gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        map("n", "gr", vim.lsp.buf.references, "[G]oto [R]eferences")
        map("n", "gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
        map("n", "gt", vim.lsp.buf.type_definition, "[G]oto [T]ype Definition")
        map("n", "gc", vim.lsp.buf.code_action, "[G]oto [C]ode action")
        map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
        map("n", "gl", vim.diagnostic.open_float, "Show Diagnostic")
        map("i", "<c-k>", vim.lsp.buf.signature_help, "Signature Help")
        map("n", "<leader>vrn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("n", "<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous Diagnostic")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next Diagnostic")
    end,
})
