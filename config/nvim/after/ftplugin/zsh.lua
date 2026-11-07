-- zsh buffers are a real filetype in nvim (sh is only the .sh/.bash fallback),
-- so they need the same 2-space shell indent as after/ftplugin/sh.lua.
vim.opt_local.expandtab = true
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
