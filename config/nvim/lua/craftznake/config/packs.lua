-- Plugin hooks that must be registered before any vim.pack.add() call.
-- Required from lua/craftznake/init.lua before the plugins/ specs are loaded.

vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name = ev.data.spec.name
        local kind = ev.data.kind

        -- Build telescope-fzf-native after install or update
        if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
            vim.system({ "make" }, { cwd = ev.data.path })
        end

        -- Sync treesitter parsers after update
        if name == "nvim-treesitter" and kind == "update" then
            if not ev.data.active then
                vim.cmd.packadd("nvim-treesitter")
            end
            vim.cmd("TSUpdate")
        end
    end,
})
