-- Craftznake UI mode switcher.
--
-- Two modes:
--   "zen"              - minimal setup: core options + treesitter only.
--                        No LSP, no ruler/colorcolumn/signcolumn, no
--                        statusline/tabline/notify plugins, etc.
--   "full"             - the regular, fully-featured config (everything in
--                        plugin/*.lua).
--
-- The mode is read very early (before plugin/*.lua files are auto-sourced)
-- so each plugin file can bail out early when mode == "zen".
--
-- Commands:
--   :ZendMode - switch to "zen" mode
--   :FullMode  - switch to "full" mode

local M = {}

M.ZEN = "zen"
M.FULL = "full"

local state_dir = vim.fn.stdpath("state")
local state_file = state_dir .. "/craftznake.mode"

local function ensure_state_dir()
    pcall(vim.fn.mkdir, state_dir, "p")
end

local function read_persisted()
    local f = io.open(state_file, "r")
    if not f then return nil end
    local content = f:read("*l")
    f:close()
    if content == M.ZEN or content == M.FULL then
        return content
    end
    return nil
end

local function write_persisted(mode)
    ensure_state_dir()
    local f = io.open(state_file, "w")
    if not f then return end
    f:write(mode)
    f:close()
end

--- Current mode ("zen" or "full").
function M.get()
    return vim.g.craftznake_mode or M.ZEN
end

function M.is_zen()
    return M.get() == M.ZEN
end

function M.is_full()
    return M.get() == M.FULL
end

--- Set the mode, persist it, and notify the user.
---@param mode string "zen" | "full"
---@param opts? { silent?: boolean }
function M.set(mode, opts)
    opts = opts or {}
    if mode ~= M.ZEN and mode ~= M.FULL then
        vim.notify("craftznake_mode: invalid mode '" .. tostring(mode) .. "' (use 'zen' or 'full')",
            vim.log.levels.ERROR)
        return
    end

    local changed = M.get() ~= mode
    vim.g.craftznake_mode = mode
    write_persisted(mode)

    if not opts.silent then
        if changed then
            vim.notify("Craftznake mode to '" .. mode .. "'. Restart Neovim to fully apply.", vim.log.levels.INFO)
        else
            vim.notify("Craftznake mode is already '" .. mode .. "'.", vim.log.levels.INFO)
        end
    end
end

--- Toggle between "zen" and "full".
function M.toggle()
    M.set(M.get() == M.ZEN and M.FULL or M.ZEN)
end

local function register_commands()
    vim.api.nvim_create_user_command("ZenMode", function() M.set(M.ZEN) end,
        { desc = "Switch Craftznake to minimal 'zen' mode (core options + treesitter only)" })

    vim.api.nvim_create_user_command("FullMode", function() M.set(M.FULL) end,
        { desc = "Switch Craftznake to the full, fully-featured mode" })
end

function M.setup()
    vim.g.craftznake_mode = read_persisted() or M.ZEN

    register_commands()

    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = register_commands,
    })
end

return M
