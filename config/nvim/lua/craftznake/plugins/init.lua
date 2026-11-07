-- Plugin specs, one module per plugin: every module calls vim.pack.add() and
-- then configures what it added.
--
-- Load order used to live in the plugin/NN-*.lua filename prefixes. It is an
-- explicit list now, but the tiers still matter: which-key has to be set up
-- before anything calls require("which-key").add(), and the colourscheme
-- before the UI plugins read the palette through craftznake.config.theme.
local specs = {
    -- foundation: colourscheme and which-key first
    "themes",
    "whichkey",
    -- UI: statusline, tabline, treesitter, navigation
    "bufferline",
    "editor",
    "harpoon",
    "lualine",
    "navigator",
    "oil",
    "transparent",
    "treesitter",
    -- editing: LSP, formatting, search, git
    "conform",
    "diff",
    "lsp",
    "noice",
    "nvim-lint",
    "telescope",
    "undotree",
    "vcs",
    "wakatime",
}

for _, name in ipairs(specs) do
    require("craftznake.plugins." .. name)
end
