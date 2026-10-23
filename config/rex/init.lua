--- Rex configuration
---
--- Converted from:
---   ~/dotfile/config/herdr/config.toml   (keys, prefix, pane navigation)
---   ~/dotfile/config/ghostty/config.ghostty (font size keys, palette, clipboard)
---
--- Docs: https://www.superlogical.com/rex/docs/customize/config
--- Apply: rex config check && rex config reload
---
--- Vocabulary, herdr -> rex:
---   workspace -> session   (client tabs are the tab bar; sessions are the left sidebar)
---   tab       -> tab       (window)
---   pane      -> pane      (block)
---   prefix    -> ctrl+space, still used as a tmux-style prefix sequence
---
--- Not expressible in init.lua (set these in Rex's Settings, Cmd+,):
---   theme, font family/size, background opacity, padding, cursor style,
---   scrollback limit, mouse capture/scroll lines, confirm-on-close,
---   sidebar width, tab bar contents, global (system-wide) hotkey.

local PREFIX = "ctrl+space"

--- Build a prefix sequence: p("c") -> "ctrl+space>c"
local function p(keys)
    return PREFIX .. ">" .. keys
end

-------------------------------------------------------------------------------
-- Defaults
-------------------------------------------------------------------------------
-- Ghostty cleared all of its own keybinds. Rex ships no Cmd+D split default,
-- so nothing is removed here; the prefix bindings below replace it.
-- (The old file unbound cmd+d / cmd+shift+d, which Rex reports as a warning:
-- nothing was bound to them. Use rex.unbind("...") for defaults you do want
-- to give back to the terminal.)
rex.unbind("cmd+d")
rex.unbind("cmd+shift+d")
-------------------------------------------------------------------------------
-- Custom actions
-------------------------------------------------------------------------------

-- Move the focused pane one step in a direction (ctrl+shift+hjkl).
-- The client's pane.move animates the swap, so it is used whenever a pane is
-- there to move against. When the pane already sits on the window edge there
-- is nothing in the way, so the split is rebuilt along the other axis instead.
local function is_app_client(client_id)
    if client_id == nil then return false end
    local list = rex.call("client.list", {})
    for _, client in ipairs((list and list.clients) or {}) do
        if client.client_id == client_id then
            return (client.info or {}).kind == "app"
        end
    end
    return false
end

local function pane_rects(node, side, out)
    out = out or {}
    if node == nil then return out end
    if node.block_id then
        out[#out + 1] = { block_id = node.block_id, rect = node.rect, side = side }
    elseif node.split then
        pane_rects(node.split.before, "before", out)
        pane_rects(node.split.after, "after", out)
    end
    return out
end

rex.action {
    name = "move_pane",
    title = "Move Pane in Direction",
    description = "Animated pane.move, or a re-split when the pane is at the edge.",
    args = { direction = "string" },
    run = function(ctx, args)
        local d = args.direction
        if d ~= "left" and d ~= "right" and d ~= "up" and d ~= "down" then
            error("move_pane: unknown direction " .. tostring(d), 0)
        end
        local vertical = d == "up" or d == "down"
        local forward = d == "down" or d == "right"
        local eps = 0.005

        local view, err = rex.session.view {}
        if err ~= nil then error(err, 0) end

        local me, panes
        for _, window in ipairs(view.windows or {}) do
            for _, layer in ipairs(window.layers or {}) do
                if layer.kind == "tiled" and layer.layout ~= nil then
                    local found = pane_rects(layer.layout)
                    local want = ctx.block_id or window.focused_block_id
                    for _, p in ipairs(found) do
                        if p.block_id == want then me, panes = p, found end
                    end
                end
            end
            if me ~= nil then break end
        end
        if me == nil then error("move_pane: no focused pane", 0) end

        local x, y, w, h = me.rect[1], me.rect[2], me.rect[3], me.rect[4]
        local at_edge
        if d == "left" then
            at_edge = x <= eps
        elseif d == "right" then
            at_edge = x + w >= 1 - eps
        elseif d == "up" then
            at_edge = y <= eps
        else
            at_edge = y + h >= 1 - eps
        end

        -- Rebuild against the nearest pane in the way, else the nearest one.
        local anchor, best_gap, nearest, best_dist
        for _, p in ipairs(panes) do
            if p.block_id ~= me.block_id then
                local px, py, pw, ph = p.rect[1], p.rect[2], p.rect[3], p.rect[4]
                local cross, ahead, gap
                if vertical then
                    cross = math.max(0, math.min(x + w, px + pw) - math.max(x, px))
                    ahead = forward and py >= y + h - eps or py + ph <= y + eps
                    gap = forward and py - (y + h) or y - (py + ph)
                else
                    cross = math.max(0, math.min(y + h, py + ph) - math.max(y, py))
                    ahead = forward and px >= x + w - eps or px + pw <= x + eps
                    gap = forward and px - (x + w) or x - (px + pw)
                end
                if cross > eps and ahead and (anchor == nil or gap < best_gap) then
                    anchor, best_gap = p, gap
                end
                local dist = math.abs(px + pw / 2 - (x + w / 2))
                    + math.abs(py + ph / 2 - (y + h / 2))
                if nearest == nil or dist < best_dist then nearest, best_dist = p, dist end
            end
        end

        local against = anchor or nearest
        if against == nil then
            rex.log("move_pane: nothing to move against")
            return nil
        end

        -- Let the app do it so the move is animated, but only when the caller is
        -- the app itself. From the CLI the client is a cli client that cannot
        -- perform pane actions, so the re-split below runs instead.
        if not at_edge and is_app_client(ctx.client_id) then
            rex.client.queue("pane.move", { direction = d })
            return { moved = "client", direction = d }
        end

        -- No client (or nowhere to go): re-split, keeping the pair in order.
        local _, merr = rex.session.move_block {
            block_id = me.block_id,
            anchor_block_id = against.block_id,
            direction = vertical and "vertical" or "horizontal",
            side = me.side or (forward and "after" or "before"),
        }
        if merr ~= nil then error(merr, 0) end
        rex.session.focus_block { block_id = me.block_id }
        return { moved = "split", against = against.block_id, direction = d }
    end,
}

-- Smart ctrl+hjkl (vim-tmux-navigator style). When the focused block runs
-- Neovim the key is passed through, and Neovim calls `rex focus <dir>` itself
-- once it reaches a split edge (see nvim/plugin/01-navigator.lua).
local VIM_KEYS = { left = "ctrl+h", down = "ctrl+j", up = "ctrl+k", right = "ctrl+l" }

local function is_vim(proc)
    if proc == nil then return false end
    for _, v in ipairs({ proc.name, proc.argv0, proc.path }) do
        if type(v) == "string" then
            local base = (v:match("([^/]+)$") or v):gsub("^%.", "")
            if base:match("^n?vim$") or base:match("^n?vim%-") then
                return true
            end
        end
    end
    return false
end

rex.action {
    name = "navigate",
    title = "Navigate (vim-aware)",
    description = "Pass ctrl+hjkl to Neovim, otherwise focus the pane in that direction.",
    args = { direction = "string" },
    run = function(ctx, args)
        local d = args.direction
        local key = VIM_KEYS[d]
        if key == nil then error("navigate: unknown direction " .. tostring(d), 0) end

        if ctx.block_id ~= nil and ctx.session_id ~= nil then
            local ok, info = pcall(rex.call, "block.method", {
                session_id = ctx.session_id,
                block_id = ctx.block_id,
                method = "process",
                args = {},
            })
            if ok and info ~= nil and is_vim(info.foreground) then
                rex.client.queue("pane.send_key", { key = key })
                return { sent = key }
            end
        end

        rex.client.queue("pane.focus", { direction = d })
        return { focused = d }
    end,
}

-------------------------------------------------------------------------------
-- Prefix bindings (herdr's [keys] table)
-------------------------------------------------------------------------------

-- Tabs
rex.bind(p("c"), "client.tab.new")                 -- new_tab
rex.bind(p("n"), "client.tab.next")                -- (kept from the tmux mapping)
rex.bind(p("p"), "client.tab.previous")            -- (kept from the tmux mapping)
rex.bind(p(","), "client.tab.rename")              -- rename_tab
rex.bind(p("shift+,"), "client.tab.move.backward") -- move_tab_previous (<)
rex.bind(p("shift+."), "client.tab.move.forward")  -- move_tab_next (>)

-- switch_tab = prefix+1..9  (Rex tabs count from 1)
for i = 1, 9 do
    rex.bind(p(tostring(i)), "client.tab.goto", { index = i })
end

-- "Workspaces" are sessions in Rex
rex.bind(p("shift+n"), "session.new")    -- new_workspace
rex.bind(p("shift+4"), "session.rename") -- rename_workspace ($)

-- Panes. Keys are written unshifted on a US layout: % is shift+5, " is shift+'
rex.bind(p("shift+5"), "pane.split", { direction = "right" }) -- split_vertical
rex.bind(p("shift+'"), "pane.split", { direction = "down" })  -- split_horizontal
rex.bind(p("x"), "pane.close")                                -- close pane (tmux-style)
rex.bind(p("z"), "pane.zoom")                                 -- zoom pane (tmux-style)
rex.bind(p("l"), "pane.focus_previous")                       -- last_pane (closest match)

-- Fuzzy session picker, with the command palette on shift.
rex.bind(p("g"), "session.switch")
rex.bind(p("shift+g"), "client.palette.toggle")

-- Agents: jump to the next one that is blocked or finished, and toggle the
rex.bind(p("shift+a"), "client.sidebar.activity.toggle")

-- detach: Rex has no detach action. Closing the client leaves every session
-- running on the server, so re-opening Rex is the equivalent of re-attaching.
rex.bind(p("d"), "client.close")

-- Cycle panes in layout order (tmux-style; Rex has no fuzzy pane picker)
rex.bind(p("o"), "pane.focus_next")
rex.bind(p(";"), "pane.focus_previous")

-- Send a literal prefix through to the terminal (press it twice), like tmux.
rex.bind(p(PREFIX), "pane.send_key", { key = PREFIX })

-------------------------------------------------------------------------------
-- Vim-style pane navigation (herdr plugin: vim-herdr-navigation)
-------------------------------------------------------------------------------
-- These keys are taken away from the terminal while Rex is focused, which is
-- what the herdr plugin did too. Note ctrl+h is also backspace in some shells.
rex.bind("ctrl+h", "navigate", { direction = "left" })
rex.bind("ctrl+j", "navigate", { direction = "down" })
rex.bind("ctrl+k", "navigate", { direction = "up" })
rex.bind("ctrl+l", "navigate", { direction = "right" })

-- The same vim directions with shift move the pane instead of moving focus,
-- the way i3 uses $mod+hjkl to focus and $mod+Shift+hjkl to move.
rex.bind("ctrl+shift+h", "move_pane", { direction = "left" })
rex.bind("ctrl+shift+j", "move_pane", { direction = "down" })
rex.bind("ctrl+shift+k", "move_pane", { direction = "up" })
rex.bind("ctrl+shift+l", "move_pane", { direction = "right" })

-------------------------------------------------------------------------------
-- Ghostty keybinds
-------------------------------------------------------------------------------
-- ghostty: super+c / super+v = copy & paste
--   Rex already copies and pastes through the standard macOS shortcuts, so
--   nothing has to be bound.
-- ghostty: global:super+grave_accent = toggle_quick_terminal
--   Rex has no system-wide hotkey; use macOS Shortcuts/Raycast to focus Rex.
rex.bind("cmd+=", "client.font.increase")        -- super+=
rex.bind("cmd+-", "client.font.decrease")        -- super+-
rex.bind("cmd+0", "client.font.reset")           -- convenience
rex.bind("cmd+shift+p", "client.palette.toggle") -- super+P

-------------------------------------------------------------------------------
-- Note on ctrl+space
-------------------------------------------------------------------------------
-- macOS may claim ctrl+space for "Select the previous input source"
-- (herdr worked around this with switch_ascii_input_source_in_prefix).
-- If prefix keys do nothing, turn that shortcut off in
-- System Settings > Keyboard > Keyboard Shortcuts > Input Sources.
