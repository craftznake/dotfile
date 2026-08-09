if require("craftznake.plugins.mode").is_zen() then return end

vim.pack.add({ 'https://github.com/laytan/cloak.nvim' })
require("cloak").setup({
    enabled = true,
    cloak_character = "*",
    highlight_group = "Comment",
    patterns = {
        {
            file_pattern = { ".env*", "wrangler.toml", ".dev.vars" },
            cloak_pattern = "=.+",
        },
        {
            file_pattern = { ".env*.yml", "*.env.yml" },
            cloak_pattern = { ":.+", "-.+" },
        },
    },
})
require("which-key").add({
    {
        mode = { "n" },
        { "<leader>tc", "<cmd>CloakToggle<cr>", desc = "[T]oggle [C]loak", noremap = true, silent = true },
    },
})

