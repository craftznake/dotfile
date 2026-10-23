if require("craftznake.plugins.mode").is_zen() then return end

-- Review layer for agent-written diffs. Coexists with plugin/02-vcs.lua, which
-- owns the jj/git blame rail (`:Blame`): that file maps no <leader> keys, so
-- the <leader>g* keys here do not collide.
vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' })

local gitsigns = require("gitsigns")

gitsigns.setup({
    signs = {
        add          = { text = "│" },
        change       = { text = "│" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
    },
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    attach_to_untracked = true,
    current_line_blame = false,
    current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
    preview_config = { border = "rounded" },
    on_attach = function(bufnr)
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
        end

        -- Hunk navigation (new mappings: nothing else claims ]c / [c).
        map("n", "]c", function() gitsigns.nav_hunk("next") end, "Next hunk")
        map("n", "[c", function() gitsigns.nav_hunk("prev") end, "Previous hunk")

        -- Blame.
        map("n", "<leader>gb", gitsigns.toggle_current_line_blame, "[G]it [B]lame line")
        map("n", "<leader>gB", function() gitsigns.blame() end, "[G]it [B]lame buffer")

        -- Staging.
        map("n", "<leader>gs", gitsigns.stage_buffer, "[G]it [S]tage buffer")
        map("n", "<leader>ghs", gitsigns.stage_hunk, "[G]it [H]unk [S]tage")
        map("n", "<leader>ghr", gitsigns.reset_hunk, "[G]it [H]unk [R]eset")
        map("n", "<leader>ghp", gitsigns.preview_hunk, "[G]it [H]unk [P]review")

        local function stage_hunk_visual()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end

        local function reset_hunk_visual()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end

        vim.keymap.set(
            "v",
            "<leader>ghs",
            stage_hunk_visual,
            { buffer = bufnr, desc = "[G]it [H]unk [S]tage", silent = true }
        )
        vim.keymap.set(
            "v",
            "<leader>ghr",
            reset_hunk_visual,
            { buffer = bufnr, desc = "[G]it [H]unk [R]eset", silent = true }
        )
    end,
})
