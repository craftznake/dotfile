-- Shell scripts use 2-space indent instead of the global 4. Kept buffer-local,
-- and picked up by conform's shfmt formatter, which reads shiftwidth from the
-- buffer and passes it as -i (unless a repo .editorconfig overrides it).
vim.opt_local.expandtab = true
vim.opt_local.softtabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.tabstop = 2
