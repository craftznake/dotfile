vim.pack.add({
    { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
    'https://github.com/navarasu/onedark.nvim',
    'https://github.com/craftzdog/solarized-osaka.nvim',
    'https://github.com/ellisonleao/gruvbox.nvim',
    'https://github.com/zaldih/themery.nvim',
})

---@diagnostic disable-next-line: missing-fields
require("rose-pine").setup({
    disable_background = false,
    styles = {
        italic = false,
        bold = true,
        transparency = true,
    },
})

require("themery").setup({
    livePreview = true,
    themes = {
        { name = "Onedark",         colorscheme = "onedark" },
        { name = "Rose pine Moon",  colorscheme = "rose-pine-moon" },
        { name = "solarized-osaka", colorscheme = "solarized-osaka" },
        { name = "gruvbox",         colorscheme = "gruvbox" },
    },
})
