local wezterm = require("wezterm")
local base_path = "craftznake."
local palette = require(base_path .. "config.colors")

-- =========== START: Disable tab, as we want to use tmux
-- local text_fg = palette.light4 -- Foreground color for the text across the fade
-- local tabbar_bg = palette.dark0
--
-- -- Return the Tab's current working directory
-- -- calling get_foreground_process_info is supposedly slow, so cache the results by
-- -- in a map of foreground_process_name -> get_foregoround_process_info().name.
-- local pane_cache = {}
--
-- -- Remove all path components and return only the last value
-- local function basename(path)
--     return path:match("^%s*(%S+)") or path
-- end
--
-- local function get_process(pane_info)
--     local proc_name = pane_info.foreground_process_name
--     if pane_cache[proc_name] then
--         return pane_cache[proc_name]
--     end
--
--     local title = wezterm.mux.get_pane(pane_info.pane_id):get_foreground_process_info().name
--     --  Get the last executable path
--     title = basename(title)
--     pane_cache[proc_name] = title
--     return title
-- end
--
-- -- Pretty format the tab title, this is the default format from tmux
-- local function format_title(tab)
--     local process = get_process(tab.active_pane)
--     return process
-- end
--
-- -- Determine if a tab has unseen output since last visited
-- local function has_unseen_output(tab)
--     for _, pane in ipairs(tab.panes) do
--         if pane.has_unseen_output then
--             return true
--         end
--     end
--     return false
-- end
--
-- -- Returns manually set title (from `tab:set_title()` or `wezterm cli set-tab-title`) or creates a new one
-- local function get_tab_title(tab)
--     local title = tab.tab_title
--     local index = tab.tab_index + 1
--     if title and #title > 0 then
--         return string.format("%d:%s", index, title)
--     end
--     return string.format("%d:%s", index, format_title(tab))
-- end
--
-- -- On format tab title events, override the default handling to return a custom title
-- -- Docs: https://wezfurlong.org/wezterm/config/lua/window-events/format-tab-title.html
-- ---@diagnostic disable-next-line: unused-local
-- wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
--     local title = {}
--     table.insert(title, { Background = { Color = tabbar_bg } })
--     table.insert(title, { Text = " " })
--     -- if tab.tab_index == 0 then
--     -- end
--
--     if tab.is_active then
--         table.insert(title, { Foreground = { Color = palette.light0 } })
--     else
--         table.insert(title, { Foreground = { Color = text_fg } })
--     end
--     local proc_title = get_tab_title(tab)
--
--     if hover then
--         table.insert(title, { Attribute = { Underline = "Single" } })
--     end
--
--     if tab.is_active then
--         table.insert(title, { Text = proc_title .. "*" })
--     elseif has_unseen_output(tab) then
--         table.insert(title, { Text = proc_title .. "!" })
--     else
--         -- to ensure tab preserve same length
--         table.insert(title, { Text = proc_title .. " " })
--     end
--
--     table.insert(title, { Attribute = { Underline = "None" } })
--
--     if tab.tab_index + 1 < #tabs then
--         table.insert(title, { Text = " " })
--         table.insert(title, { Foreground = { Color = text_fg } })
--         table.insert(title, { Text = "⎮" })
--     end
--     return title
-- end)
--
-- -- colors to use in right status bar
-- local colors = {
--     palette.dark1,
--     palette.dark2,
--     palette.dark3,
-- }
-- local SOLID_LEFT_ARROW = utf8.char(0xe0b2)  -- 
-- local SOLID_RIGHT_ARROW = utf8.char(0xe0b0) -- 
-- local NIXOS_ICON = utf8.char(0xf313)        -- 
-- -- update right status bar
-- -- Docs: https://wezfurlong.org/wezterm/config/lua/window-events/update-right-status.html
-- -- @diagnostic disable-next-line: unused-local
-- wezterm.on("update-status", function(window, _)
--     -- Each element holds the text for a cell in a "powerline" style << fade
--     local cells = {}
--     -- I like my date/time in this style: "Wed Mar 3 08:14"
--     local date = wezterm.strftime("%a %b %-d %H:%M")
--     table.insert(cells, date)
--
--     -- Color palette for the backgrounds of each cell
--     local elements = {} -- The elements to be formatted
--     local num_cells = 0 -- How many cells have been formatted
--
--     -- Translate a cell into elements
--     local function push(text)
--         local idx = num_cells + 1
--         -- first shell
--         -- in lua is 1-based index
--         -- Add the left separator, this should be the colors of the
--         -- left of current cell
--         if idx == 1 then
--             table.insert(elements, { Background = { Color = tabbar_bg } })
--         else
--             table.insert(elements, { Background = { Color = colors[idx - 1] } })
--         end
--         table.insert(elements, { Foreground = { Color = colors[idx] } })
--         table.insert(elements, { Text = SOLID_LEFT_ARROW })
--
--         -- Add the text
--         table.insert(elements, "ResetAttributes") -- Reset attributes affect to next element
--         table.insert(elements, { Foreground = { Color = text_fg } })
--         table.insert(elements, { Background = { Color = colors[idx] } })
--         table.insert(elements, { Text = " " .. text .. " " })
--         table.insert(elements, "ResetAttributes") -- Reset attributes affect to next element
--         num_cells = num_cells + 1
--     end
--
--     while #cells > 0 do
--         local cell = table.remove(cells, 1)
--         push(cell)
--     end
--     window:set_right_status(wezterm.format(elements))
--
--     local session_name = window:active_workspace()
--     local session_formatting = {
--         "ResetAttributes", -- Reset attributes affect to next element
--         { Background = { Color = palette.dark1 } },
--         { Foreground = { Color = text_fg } },
--         { Text = " " .. NIXOS_ICON .. " " .. session_name .. " " }, --  "  default 
--         "ResetAttributes",                                          -- Reset attributes affect to next element
--         { Background = { Color = tabbar_bg } },
--         { Foreground = { Color = palette.dark1 } },
--         { Text = SOLID_RIGHT_ARROW },
--     }
--
--     window:set_left_status(wezterm.format(session_formatting))
-- end)
--
-- return {
--     animation_fps = 60,
--     max_fps = 60,
--     front_end = "WebGpu",
--     webgpu_power_preference = "HighPerformance",
--     tab_bar_at_bottom = true,
--
--     -- color scheme
--     color_scheme = "Gruvbox Dark (Gogh)",
--     -- background
--     -- window_background_opacity = 0.85,
--     -- macos_window_background_blur = 20,
--     window_decorations = "RESIZE",
--     -- scrollbar
--     enable_scroll_bar = true,
--     adjust_window_size_when_changing_font_size = false,
--     -- tab bar
--     use_fancy_tab_bar = false,
--     show_new_tab_button_in_tab_bar = false,
--     tab_max_width = 100,
--     -- window
--     window_padding = {
--         left = 5,
--         right = 5,
--         top = 5,
--         bottom = 5,
--     },
--     colors = {
--         tab_bar = {
--             background = tabbar_bg,
--         },
--     },
--     inactive_pane_hsb = {
--         saturation = 0.9,
--         brightness = 0.4,
--     },
-- }
-- =========== END: Disable tab

return {
    animation_fps = 60,
    max_fps = 60,
    front_end = "WebGpu",
    webgpu_power_preference = "HighPerformance",
    tab_bar_at_bottom = true,

    -- color scheme
    color_scheme = "Gruvbox Dark (Gogh)",

    -- background
    window_background_opacity = 0.85,
    macos_window_background_blur = 20,
    window_decorations = "RESIZE",
    -- scrollbar
    enable_scroll_bar = false,
    adjust_window_size_when_changing_font_size = false,
    -- tab bar
    enable_tab_bar = false,
    -- window
    window_padding = {
        left = 20,
        right = 20,
        top = 20,
        bottom = 20,
    },
}
