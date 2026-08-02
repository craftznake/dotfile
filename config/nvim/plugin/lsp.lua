vim.pack.add({
    'https://github.com/onsails/lspkind.nvim',
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
    { src = 'https://github.com/saghen/blink.cmp', version = 'v1.8.0' },
    'https://github.com/maxandron/goplements.nvim'
})

local servers = {
    rust_analyzer = {
        mason = false,
        settings = {
            ["rust-analyzer"] = {
                -- Exclude heavy directories to keep indexing snappy
                files = {
                    excludeDirs = { "target", ".git" },
                },

                -- Balanced background checks (Flycheck)
                checkOnSave = {
                    enable = true,
                    command = "clippy",
                    workspace = false,
                    allTargets = false,
                    extraArgs = {
                        "--target-dir=/tmp/rust-analyzer-check",
                        "--no-deps",
                    },
                },

                -- Cargo project loading settings
                cargo = {
                    buildScripts = {
                        enable = true,
                    },
                },

                -- Macro expansion performance
                procMacro = {
                    enable = true,
                    attributes = {
                        enable = true,
                    },
                },

                -- Diagnostics performance
                diagnostics = {
                    enable = true,
                    experimental = {
                        enable = false, -- Disables heavy, non-optimized linting algorithms
                    },
                },
            },
        },
    },
    eslint = {},
    -- python,
    ruff = {},
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = { globals = { "vim" } },
            },
        },
    },
    buf_ls = {},
    gopls = {
        settings = {
            gofumpt = true,
            codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
            },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
            analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
        },
    },
}

require("mason").setup()

local blink = require("blink.cmp")

local function handler(server, server_opts)
    if server_opts.enabled == false then return end
    server_opts.capabilities = blink.get_lsp_capabilities(server_opts.capabilities or {})
    vim.lsp.config(server, server_opts)
    vim.lsp.enable(server)
end

local ensure_installed = {}
for server, server_opts in pairs(servers) do
    if server_opts and server_opts.enabled ~= false then
        if server_opts.mason == false then
            handler(server, server_opts)
        else
            ensure_installed[#ensure_installed + 1] = server
        end
    end
end

require("mason-lspconfig").setup({
    automatic_installation = true,
    ensure_installed = ensure_installed,
    handlers = { function(server)
        local server_opts = servers[server] or { mason = true }
        handler(server, server_opts)
    end },
})

local lsp_utils = require("craftznake.plugins.utils.lsp_utils")
lsp_utils.setup()
vim.keymap.set("n", "<leader>tl", lsp_utils.toggle_lsp, { desc = "[T]oggle [L]sps" })

blink.setup({
    keymap = {
        preset = "none",
        ["<C-y>"] = { "show", "fallback" },
        ["<C-e>"] = { "cancel", "fallback" },
        ["<CR>"] = {
            function(cmp)
                if cmp.is_menu_visible() and cmp.is_active() then
                    return cmp.accept()
                end
            end,
            "fallback",
        },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<Tab>"] = {
            function(cmp)
                if cmp.is_ghost_text_visible() and cmp.is_active() then
                    return cmp.accept()
                end
            end,
            "snippet_forward",
            "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    completion = {
        keyword = { range = "prefix" },
        menu = {
            enabled = true,
            auto_show = false,
            border = "none",
            draw = {
                snippet_indicator = "~",
                treesitter = {},
                columns = { { "label", "label_description", gap = 1, "kind" } },
                components = {
                    label_description = { width = { max = 50 } },
                    source_name = {
                        text = function(ctx)
                            return "[" .. ctx.source_name .. "]"
                        end,
                    },
                },
            },
        },
        list = {
            selection = { preselect = true, auto_insert = false },
            cycle = { from_top = false },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = { border = "single" },
        },
        trigger = {
            prefetch_on_insert = true,
            show_on_keyword = true,
            show_on_trigger_character = true,
            show_on_blocked_trigger_characters = { " ", "\n", "\t" },
            show_on_insert_on_trigger_character = true,
        },
        ghost_text = {
            enabled = true,
            show_with_selection = true,
            show_with_menu = false,
        },
    },
    signature = { enabled = false, window = { border = "none" } },
    sources = { default = { "lsp", "omni", "path", "snippets" } },
})

vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    float = {
        focusable = true,
        style = "minimal",
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})


require("goplements").setup({})
