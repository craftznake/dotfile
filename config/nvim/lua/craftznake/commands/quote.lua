-- :Quote copies the selected lines as a fenced markdown code block annotated
-- with the file path and line range, ready to paste into an agent prompt.
--
--   ```lua filename=config/nvim/init.lua line=3-7
--   <selected lines>
--   ```

local M = {}

--- Path relative to the repository root, falling back to a cwd-relative or
--- absolute path when the buffer is not part of a repo.
---@param name string absolute buffer name
---@return string
local function display_path(name)
    if name == "" then return "[No Name]" end

    local abs = vim.fs.normalize(name)
    local root = vim.fs.root(abs, { ".jj", ".git" }) or vim.fn.getcwd()
    return vim.fs.relpath(root, abs) or abs
end

--- Build the markdown block for the given line range of the current buffer.
---@param line1 integer
---@param line2 integer
---@return string
function M.block(line1, line2)
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "text"
    local path = display_path(vim.api.nvim_buf_get_name(buf))
    local lines = vim.api.nvim_buf_get_lines(buf, line1 - 1, line2, true)

    local out = { string.format("```%s filename=%s line=%d-%d", filetype, path, line1, line2) }
    vim.list_extend(out, lines)
    out[#out + 1] = "```"

    return table.concat(out, "\n")
end

function M.setup()
    vim.api.nvim_create_user_command("Quote", function(args)
        local path = display_path(vim.api.nvim_buf_get_name(0))
        vim.fn.setreg("+", M.block(args.line1, args.line2))
        vim.notify(
            string.format("Quoted %d line(s) from %s", args.line2 - args.line1 + 1, path),
            vim.log.levels.INFO
        )
    end, { range = true, desc = "Copy selection as a markdown code block with filename and line range" })
end

M.setup()

return M
