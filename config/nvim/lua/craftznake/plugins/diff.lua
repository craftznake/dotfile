if require("craftznake.config.mode").is_zen() then return end

-- Agent diff overlay, explicit trigger only: `:AgentDiff [rev]` toggles an
-- inline diff of the current buffer (deleted text shown inline, changed text
-- highlighted). Nothing is drawn in normal view.
--
-- Reference text: if the file is in a jj repo, the file at `rev` (default `@-`, the parent of
-- the working-copy change, so the overlay shows everything changed in the
-- current change). Otherwise (plain git repo, or no jj binary) it uses the git index.
vim.pack.add({ 'https://github.com/nvim-mini/mini.diff' })

local rev = "@-"

local jj_source = {
    name = "jj",
    attach = function(buf)
        if vim.fn.executable("jj") == 0 then return false end
        local abs = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
        local root = abs ~= "" and vim.fs.root(abs, ".jj") or nil
        local rel = root and vim.fs.relpath(root, abs)
        if not rel then return false end

        local fileset = 'root-file:"' .. rel:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
        vim.system(
            { "jj", "file", "show", "--ignore-working-copy", "-r", rev, fileset },
            { cwd = root, text = true },
            vim.schedule_wrap(function(res)
                if not vim.api.nvim_buf_is_valid(buf) or not MiniDiff.get_buf_data(buf) then return end
                if res.code == 0 then
                    MiniDiff.set_ref_text(buf, res.stdout)
                elseif (res.stderr or ""):find("No such path", 1, true) then
                    -- File did not exist at `rev`: everything shows as added.
                    MiniDiff.set_ref_text(buf, "")
                else
                    vim.notify("AgentDiff: " .. vim.trim(res.stderr or ""), vim.log.levels.WARN)
                    MiniDiff.disable(buf)
                end
            end)
        )
    end,
}

-- setup() queues an auto-enable for every buffer; keep it blocked until those
-- scheduled callbacks have run, then release the flag.
vim.g.minidiff_disable = true
require("mini.diff").setup({
    source = { jj_source, require("mini.diff").gen_source.git() },
    view = { style = "sign" },
    mappings = {
        apply = "",
        reset = "",
        textobject = "",
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
    },
})

-- mini.diff also enables itself on every BufEnter; remove that so it only runs
-- for buffers where :AgentDiff was invoked.
vim.api.nvim_clear_autocmds({ group = "MiniDiff", event = "BufEnter" })
vim.schedule(function()
    vim.g.minidiff_disable = nil
end)

vim.api.nvim_create_user_command("AgentDiff", function(args)
    local buf = vim.api.nvim_get_current_buf()
    if MiniDiff.get_buf_data(buf) then
        MiniDiff.disable(buf)
        return
    end
    rev = args.args ~= "" and args.args or "@-"
    MiniDiff.enable(buf)
    if MiniDiff.get_buf_data(buf) == nil then
        vim.notify("AgentDiff: buffer cannot be diffed", vim.log.levels.WARN)
        return
    end
    MiniDiff.toggle_overlay(buf)
end, { nargs = "?", desc = "Toggle inline diff overlay (jj rev, default @-; git index outside jj)" })
