if require("craftznake.config.mode").is_zen() then return end

vim.pack.add({
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
                runtime = {
                    version = "LuaJIT",
                },
                diagnostics = {
                    globals = { "vim" }
                },
                workspace = {
                    -- Only the Neovim runtime: it holds the `---@meta` stubs that
                    -- define `vim`. Passing every runtime dir (all plugin dirs)
                    -- floods lua_ls's preload budget, so `vim` ends up undefined
                    -- in projects that are not the config itself.
                    library = { vim.env.VIMRUNTIME },
                    checkThirdParty = false,
                },
            },
        },
    },
    buf_ls = {},
    bashls = {
        -- Include zsh in the filetypes list
        filetypes = { "sh", "bash", "zsh" },
        settings = {
            bashls = {
                -- Tell the server to recognize zsh syntax features
                bashIde = {
                    globPattern = "*@(.sh|.inc|.bash|.command|.zshrc|.zsh)"
                }
            },
        },
    },
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

local lsp_utils = require("craftznake.util.lsp_utils")
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

-- Diagnostics keep running in the background. Only an undercurl in the
-- diagnostic color is drawn: no virtual text, no gutter signs.
vim.diagnostic.config({
    virtual_text = false,
    signs = false,
    underline = true,
    severity_sort = true,
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

local function apply_diagnostic_underlines()
    local theme = require("craftznake.config.theme")
    for _, severity in ipairs({ "Error", "Warn", "Info", "Hint" }) do
        vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. severity, {
            undercurl = true,
            underline = false,
            sp = theme.get_hl("Diagnostic" .. severity).fg,
        })
    end
end

apply_diagnostic_underlines()
require("craftznake.config.theme").register("diagnostics", apply_diagnostic_underlines)

-- Pull diagnostics into the quickfix list on demand (diagnostics are always
-- up to date since the LSP keeps computing them in the background).
-- vim.diagnostic.setqflist() takes no `bufnr` -- it always lists every buffer --
-- so the scoped variant rebuilds the items itself and follows the same
-- "update the list with this title" pattern the core function uses.
local function diag_qflist(title, bufnr)
    local items = vim.diagnostic.toqflist(vim.diagnostic.get(bufnr))
    local qf_id
    for nr = 1, vim.fn.getqflist({ nr = "$" }).nr do
        local list = vim.fn.getqflist({ nr = nr, id = 0, title = 0 })
        if list.title == title then
            qf_id = list.id
            break
        end
    end
    vim.fn.setqflist({}, qf_id and "u" or " ", { title = title, items = items, id = qf_id })
    vim.cmd(("silent %dchistory"):format(vim.fn.getqflist({ id = qf_id, nr = 0 }).nr))
    vim.cmd("botright cwindow")
end

vim.api.nvim_create_user_command("Diag", function()
    diag_qflist("Diagnostics (buffer)", vim.api.nvim_get_current_buf())
end, { desc = "Pull current buffer diagnostics into quickfix" })

vim.api.nvim_create_user_command("DiagAll", function()
    diag_qflist("Diagnostics (all buffers)", nil)
end, { desc = "Pull diagnostics for all buffers into quickfix" })

-- <leader>x is the "diagnostics/quickfix" group (see 00-whichkey.lua)
vim.keymap.set("n", "<leader>xq", "<cmd>Diag<CR>", { desc = "[Q]uickfix diagnostics (buffer)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>DiagAll<CR>", { desc = "Quickfix diagnostics (all buffers)" })

require("goplements").setup({})
vim.filetype.add({
    extension = { zsh = "sh" },
    filename = { [".zshrc"] = "sh", [".zprofile"] = "sh" },
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "go",
    once = false,
    callback = function()
        require("goplements").setup({})
    end,
})
