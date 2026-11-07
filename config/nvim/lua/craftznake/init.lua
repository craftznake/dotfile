-- Entry point for the craftznake config.
--
-- Everything below is load-order sensitive, so the order is written out
-- explicitly instead of relying on filenames or alphabet:
--
--   mode     - options branch on zen/full, so it has to resolve first
--   options  - mapleader and the rest, before any plugin is added
--   keymaps  - global maps, before plugins register buffer-local ones
--   autocmds - the augroups plugins hook into
--   theme    - palette helpers that UI and LSP modules read
--   packs    - the PackChanged hook, before the first vim.pack.add() call
--   commands - user commands such as :Quote
--   plugins  - the plugin specs themselves, each behind vim.pack.add()
require("craftznake.config.mode").setup()
require("craftznake.config.options")
require("craftznake.config.keymaps")
require("craftznake.config.autocmds")
require("craftznake.config.theme").setup()
require("craftznake.config.packs")
require("craftznake.commands.quote")
require("craftznake.plugins")

-- Reload one of our modules in place, e.g. :lua R("craftznake.config.options")
function R(name)
    require("plenary.reload").reload_module(name)
end
