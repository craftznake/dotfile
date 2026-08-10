vim.g.mapleader = " "
vim.opt.guicursor = "a:blinkon0-block"

vim.opt.mouse = "a"
vim.opt.nu = true
vim.opt.rnu = true
vim.opt.expandtab = true
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smarttab = true
vim.opt.smartindent = true

vim.opt.wrap = false -- No Wrap lines
vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.backupskip = { "/tmp/*", "/private/tmp/*" }
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencodings = "utf-8"

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.showmode = false
vim.opt.scrolloff = 10
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "80"

vim.opt.conceallevel = 0
vim.opt.title = true
vim.opt.autoindent = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.shell = "zsh"
vim.opt.inccommand = "split"
vim.opt.ignorecase = true -- Case insensitive searching UNLESS /C or capital in search
vim.opt.breakindent = true
vim.opt.backspace = { "start", "eol", "indent" }
vim.opt.path:append({ "**" }) -- Finding files - Search down into subfolders
vim.opt.wildignore:append({ "*/node_modules/*" })
vim.opt.splitbelow = true     -- Put new windows below current
vim.opt.splitright = true     -- Put new windows right of current
vim.opt.splitkeep = "cursor"

vim.opt.updatetime = 50

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m]"]])
vim.cmd([[let &t_Ce = "\e[4:0m]"]])
vim.opt.listchars = {
    -- eol = "↲",
    tab = "  ",
    trail = "_",
    extends = ">",
    precedes = "<",
    nbsp = "~",
}

-- Add asterisks in block comments
vim.opt.formatoptions:append({ "r" })
vim.opt.formatoptions:remove({ "a" })

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.g.lazyvim_check_order = false

-- "Zen" mode: strip the extra visual component.
if require("craftznake.plugins.mode").is_zen() then
    vim.opt.ruler = false
    vim.opt.signcolumn = "no"
    vim.opt.colorcolumn = ""
    vim.opt.nu = false
    vim.opt.rnu = false
end
