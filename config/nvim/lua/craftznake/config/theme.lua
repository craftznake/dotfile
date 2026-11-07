local M = {}

local refreshers = {}

function M.get_hl(name)
    local ok, def = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if not ok or type(def) ~= "table" then return {} end
    return def
end

local function hex(value)
    if value == nil then return nil end
    return string.format("#%06x", value)
end

function M.color(group, key)
    return hex(M.get_hl(group)[key]) or "none"
end

function M.lualine_theme()
    local p = M.palette()
    local function mode(fg) return { a = { fg = fg, bg = "none" }, b = { bg = "none" }, c = { fg = p.dim, bg = "none" } } end
    return {
        normal   = mode(p.fg),
        insert   = mode(p.string_fg),
        visual   = mode(p.visual_fg ~= "none" and p.visual_fg or p.accent),
        replace  = mode(p.error_fg ~= "none" and p.error_fg or p.accent),
        command  = mode(p.accent),
        inactive = { a = { fg = p.dim, bg = "none" }, b = { bg = "none" }, c = { fg = p.dim, bg = "none" } },
    }
end

function M.palette()
    local normal       = M.get_hl("Normal")
    local normal_nc    = M.get_hl("NormalNC")
    local comment      = M.get_hl("Comment")
    local visual       = M.get_hl("Visual")
    local cursorline   = M.get_hl("CursorLine")
    local string_hl    = M.get_hl("String")
    local floatborder  = M.get_hl("FloatBorder")
    local normal_float = M.get_hl("NormalFloat")
    local tab_sel      = M.get_hl("TabLineSel")
    local tab_fill     = M.get_hl("TabLineFill")

    return {
        fg            = hex(normal.fg) or "none",
        bg            = hex(normal.bg) or "none",
        fg_nc         = hex(normal_nc.fg) or hex(normal.fg) or "none",
        bg_nc         = hex(normal_nc.bg) or hex(normal.bg) or "none",
        dim           = hex(comment.fg) or "none",
        accent        = hex(string_hl.fg) or hex(normal.fg) or "none",
        visual_fg     = hex(visual.fg) or "none",
        visual_bg     = hex(cursorline.bg) or hex(visual.bg) or "none",
        border        = hex(floatborder.fg) or hex(normal.fg) or "none",
        float_bg      = hex(normal_float.bg) or hex(normal.bg) or "none",
        tab_active_fg = hex(tab_sel.fg) or hex(normal.fg) or "none",
        tab_fill_bg   = hex(tab_fill.bg) or "none",
        string_fg     = hex(string_hl.fg) or "none",
        error_fg      = M.color("DiagnosticError", "fg"),
        warn_fg       = M.color("DiagnosticWarn", "fg"),
        info_fg       = M.color("DiagnosticInfo", "fg"),
        hint_fg       = M.color("DiagnosticHint", "fg"),
        transparent   = vim.g.transparent_enabled == true,
    }
end

function M.register(name, fn)
    refreshers[name] = fn
end

function M.unregister(name)
    refreshers[name] = nil
end

function M.apply()
    for _, fn in pairs(refreshers) do
        pcall(fn)
    end
end

local function apply_statusline()
    local p = M.palette()
    local bg = p.transparent and "none" or p.bg
    vim.api.nvim_set_hl(0, "StatusLine", { bg = bg, fg = p.fg, cterm = {} })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = bg, fg = p.dim, cterm = {} })
    vim.api.nvim_set_hl(0, "SignColumn", { bg = bg, cterm = {} })
    vim.api.nvim_set_hl(0, "FoldColumn", { bg = bg, fg = p.dim, cterm = {} })
    vim.api.nvim_set_hl(0, "LineNr", { fg = p.dim, cterm = {} })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = bg, cterm = {} })
    vim.api.nvim_set_hl(0, "TabLine", { bg = bg, fg = p.dim, cterm = {} })
    vim.api.nvim_set_hl(0, "TabLineSel", { bg = bg, fg = p.fg, bold = true, cterm = {} })
    vim.api.nvim_set_hl(0, "WinSeparator", { bg = bg, fg = p.dim, cterm = {} })
end

function M.setup()
    local group = vim.api.nvim_create_augroup("CraftznakeTheme", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function() vim.schedule(M.apply) end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "TransparentClear",
        callback = function() vim.schedule(M.apply) end,
    })
    M.register("statusline", apply_statusline)
    apply_statusline()
end

return M
