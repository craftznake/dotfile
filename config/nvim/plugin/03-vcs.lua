-- Reusable utility function to open a full-width lower split window and populate it with content
local function show(content, filetype_syntax)
    -- Open a new scratch buffer in a full-width lower split
    vim.cmd('new')
    vim.cmd('wincmd J') -- Force the window to stretch across the full width at the bottom

    -- Dynamic sizing 40% of the overall layout height
    local total_height = vim.o.lines
    local target_height = math.floor(total_height * 0.40)
    if target_height < 15 then target_height = 15 end
    vim.cmd('resize ' .. target_height)

    -- Safely drop the array of text lines into the newly instantiated buffer
    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)

    -- Enforce scratch-buffer properties so Neovim doesn't try to save it to disk
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
    vim.bo.filetype = filetype_syntax or 'text'
    vim.bo.readonly = true    -- mark the buffer as read-only
    vim.bo.modifiable = false -- non-editable

    -- localized map to close the split instantly via 'q'
    vim.keymap.set('n', 'q', ':bwipeout!<CR>', { buffer = true, silent = true, desc = 'Close blame window' })
end
-- vcs praise (another blame)
local function praise_current_line()
    local rel_file_path = vim.fn.shellescape(vim.fn.expand('%:.'))
    local abs_file_dir = vim.fn.shellescape(vim.fn.expand('%:p:h'))
    local file_name = vim.fn.shellescape(vim.fn.expand('%:t'))
    local line_num = tonumber(vim.fn.line('.'))

    -- 1. Check if inside a Jujutsu (jj) workspace
    vim.fn.system('jj root --cwd ' .. abs_file_dir)
    if vim.v.shell_error == 0 then
        local commit_id = nil
        -- We specifically asks for the commit ID
        local jj_template = string.format(
            "'if(self.line_number() == %d, self.commit().commit_id())'",
            line_num
        )

        local cmd = string.format('jj file annotate %s -T %s', rel_file_path, jj_template)
        commit_id = vim.fn.trim(vim.fn.system(cmd))

        if commit_id ~= "" then
            -- Execute jj diff for that specific revision
            local diff_cmd = string.format('jj diff -r %s', vim.fn.shellescape(commit_id))
            local diff_output = vim.fn.systemlist(diff_cmd)
            show(diff_output, 'diff')
        else
            print("Could not praise, changeID is empty")
        end
        return
    end

    -- 2. Check if inside a Git repository
    vim.fn.system('git -C ' .. abs_file_dir .. ' rev-parse --is-inside-work-tree')
    if vim.v.shell_error == 0 then
        local commit_id = nil
        -- We specifically asks for the commit ID
        local cmd = string.format('git -C %s blame -L %d,%d --porcelain %s', abs_file_dir, line_num, line_num, file_name)
        local blame_output = vim.fn.system(cmd)
        commit_id = blame_output:match("^(%x+)")

        -- Check if it's a valid hash or if the line is uncommitted (all zeros)
        if commit_id and not commit_id:match("^0+$") then
            -- Execute git show to get the complete diff of that commit
            local diff_cmd = string.format('git -C %s show %s', abs_file_dir, commit_id)
            local diff_output = vim.fn.systemlist(diff_cmd)
            show(diff_output, 'diff')
        else
            print("Could not praise, changeID is empty")
        end
        return
    end

    print("Man, you're not in any repo")
end

-- Create the user command :Blame
vim.api.nvim_create_user_command('Blame', praise_current_line,
    {})
