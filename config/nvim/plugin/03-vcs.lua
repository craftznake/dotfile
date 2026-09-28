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

    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.bo.swapfile = false
    vim.bo.filetype = filetype_syntax or 'text'
    vim.bo.readonly = true
    vim.bo.modifiable = false
    vim.keymap.set('n', 'q', ':bwipeout!<CR>', { buffer = true, silent = true, desc = 'Close blame window' })
end

local function set_scratch(buf, filetype)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = filetype or 'text'
end

local function split_lines(text)
    local lines = vim.split(text or '', '\n', { plain = true })
    if lines[#lines] == '' then table.remove(lines) end
    if #lines == 0 then lines[1] = '' end
    return lines
end

local function is_absolute(path)
    return path:sub(1, 1) == '/' or path:match('^%a:[/\\]') ~= nil
end

local function real_path(path)
    return vim.uv.fs_realpath(path) or vim.fs.normalize(path)
end

local function relative_path(root, path)
    local normalized_root = real_path(root):gsub('/+$', '')
    local normalized_path = real_path(path)
    local prefix = normalized_root .. '/'
    if normalized_path:sub(1, #prefix) ~= prefix then return nil end
    return normalized_path:sub(#prefix + 1)
end

local function run(argv, cwd)
    local result = vim.system(argv, { cwd = cwd, text = true }):wait()
    if result.code ~= 0 then
        return nil, vim.trim(result.stderr ~= '' and result.stderr or result.stdout)
    end
    return result.stdout
end

local function git_records(path, root, relpath)
    local output, err = run({ 'git', '-C', root, 'blame', '--line-porcelain', '--', relpath }, root)
    if not output then return nil, err end

    local records, commit = {}, nil
    for line in (output .. '\n'):gmatch('(.-)\n') do
        local hash, _, final = line:match('^(%x+) (%d+) (%d+)')
        if hash then
            commit = { id = hash, path = path }
            records[tonumber(final)] = commit
        elseif commit and line:match('^summary ') then
            commit.summary = line:sub(9)
        elseif commit and line:match('^author ') then
            commit.author = line:sub(8)
        elseif commit and line:match('^\t') then
            commit = nil
        end
    end

    return records
end

local function jj_records(path, root, relpath)
    local template =
    'self.line_number() ++ "\\x1f" ++ self.commit().change_id() ++ "\\x1f" ++ self.commit().commit_id() ++ "\\x1f" ++ self.commit().description().first_line() ++ "\\x1f" ++ self.commit().author().name() ++ "\\x1f" ++ self.content()'
    local output, err = run({ 'jj', '--repository', root, 'file', 'annotate', relpath, '-T', template }, root)
    if not output then return nil, err end

    local records = {}
    for row in (output .. '\n'):gmatch('(.-)\n') do
        local number, change_id, commit_id, summary, author = row:match('^(.-)\31(.-)\31(.-)\31(.-)\31(.-)\31')
        if number then
            records[tonumber(number)] = {
                id = change_id,
                commit_id = commit_id,
                summary = summary,
                author = author,
                path = path,
            }
        end
    end
    return records
end

local function repo_for(path)
    path = real_path(path)
    local dir = vim.fs.dirname(path)
    local root = run({ 'jj', '--repository', dir, 'root' }, dir)
    if root then
        root = vim.trim(root)
        if not is_absolute(root) then root = vim.fs.normalize(dir .. '/' .. root) end
        return 'jj', root
    end
    root = run({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, dir)
    if root then
        root = vim.trim(root)
        if not is_absolute(root) then root = vim.fs.normalize(dir .. '/' .. root) end
        return 'git', root
    end
    return nil, nil
end

local function file_diff(kind, root, relpath, group)
    if kind == 'git' then
        return run({ 'git', '-C', root, 'show', '--format=fuller', '--no-ext-diff', group.id, '--', relpath }, root)
    end
    return run({ 'jj', '--repository', root, 'diff', '--git', '-r', group.id, '--', relpath }, root)
end

local praise_colors = {
    '#fb4934',
    '#b8bb26',
    '#fabd2f',
    '#83a598',
    '#d3869b',
    '#8ec07c',
    '#fe8019',
    '#d65d0e',
}

local function render_rail(kind, records, line_count)
    local lines, blocks, color_indexes = {}, {}, {}
    local colors_by_id = {}
    local next_color_index = 0
    local previous_id
    for line = 1, line_count do
        local group = records[line]
        if not group then
            lines[line] = ''
            previous_id = nil
        else
            local is_block_start = group.id ~= previous_id
            local color_index
            if is_block_start then
                -- Same commit keeps the same color across all of its blocks
                color_index = colors_by_id[group.id]
                if not color_index then
                    color_index = (next_color_index % #praise_colors) + 1
                    -- Keep adjacent blocks distinguishable when the palette wraps around
                    local previous_block = blocks[#blocks]
                    if previous_block and color_index == previous_block.color_index then
                        color_index = (color_index % #praise_colors) + 1
                    end
                    colors_by_id[group.id] = color_index
                    next_color_index = next_color_index + 1
                end
                blocks[#blocks + 1] = { start_row = line, group = group, color_index = color_index }
            else
                color_index = blocks[#blocks].color_index
            end
            color_indexes[line] = color_index
            if is_block_start then
                local label = kind == 'jj' and group.id or group.id:sub(1, 12)
                lines[line] = string.format('▌ %s  %s', label, group.summary or '(no description)')
            else
                lines[line] = '▌'
            end
            previous_id = group.id
        end
    end
    return lines, blocks, color_indexes
end

local function source_line_group(records, line)
    return records[line]
end

local function close_explorer(state)
    if state.closed then return end
    state.closed = true
    if state.augroup then pcall(vim.api.nvim_del_augroup_by_id, state.augroup) end
    if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
        pcall(vim.api.nvim_win_close, state.diff_win,
            true)
    end
    if state.list_win and vim.api.nvim_win_is_valid(state.list_win) then
        pcall(vim.api.nvim_win_close, state.list_win,
            true)
    end
    if state.list_buf and vim.api.nvim_buf_is_valid(state.list_buf) then
        pcall(vim.api.nvim_buf_delete, state.list_buf, { force = true })
    end
end

local function praise_current_file()
    local source_buf = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(source_buf)
    if path == '' or vim.fn.filereadable(path) ~= 1 then
        vim.notify('Praise requires a saved file on disk', vim.log.levels.WARN)
        return
    end

    local kind, root = repo_for(path)
    if not kind then
        vim.notify('Praise: file is not in a Git or jj repository', vim.log.levels.WARN)
        return
    end

    local relpath = relative_path(root, path)
    if not relpath then
        vim.notify('Praise: could not resolve file path in repository', vim.log.levels.ERROR)
        return
    end

    local records, records_err = (kind == 'jj' and jj_records or git_records)(path, root, relpath)
    if not records then
        vim.notify('Praise: ' .. tostring(records_err), vim.log.levels.ERROR)
        return
    end

    local source_win = vim.api.nvim_get_current_win()
    local source_line_count = vim.api.nvim_buf_line_count(source_buf)

    -- Create rail sidebar window
    vim.cmd('topleft vertical new')
    local list_win, list_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    set_scratch(list_buf, 'praise')

    local list_lines, blocks, color_indexes = render_rail(kind, records, source_line_count)

    vim.bo[list_buf].readonly = false
    vim.bo[list_buf].modifiable = true
    vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, list_lines)
    vim.bo[list_buf].modifiable = false
    vim.bo[list_buf].readonly = true

    vim.wo[list_win].number = false
    vim.wo[list_win].relativenumber = false
    vim.wo[list_win].signcolumn = 'no'
    vim.wo[list_win].wrap = false
    vim.cmd('vertical resize 50')

    -- Restore focus to source window
    vim.api.nvim_set_current_win(source_win)

    local ns = vim.api.nvim_create_namespace('PraiseExplorer' .. list_buf)
    local state = {
        list_win = list_win,
        list_buf = list_buf,
        source_buf = source_buf,
        source_win = source_win,
        syncing = false,
        closed = false,
    }

    local function apply_decorations()
        vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
        for _, block in ipairs(blocks) do
            local end_row = block.start_row
            while end_row < #list_lines and color_indexes[end_row + 1] == block.color_index do
                end_row = end_row + 1
            end
            local color = praise_colors[block.color_index]
            local label = 'PraiseRail_' .. list_buf .. '_' .. block.start_row
            vim.api.nvim_set_hl(0, label, { fg = color })
            for row = block.start_row, end_row do
                vim.api.nvim_buf_set_extmark(list_buf, ns, row - 1, 0, {
                    end_row = row,
                    hl_group = label,
                    hl_eol = true,
                    priority = 120,
                })
            end
        end
    end

    local function selected_group()
        if not vim.api.nvim_win_is_valid(list_win) then return nil end
        return records[vim.api.nvim_win_get_cursor(list_win)[1]]
    end

    local function sync_to_source(win)
        if state.syncing or state.closed then return end
        if not vim.api.nvim_win_is_valid(source_win) or not vim.api.nvim_win_is_valid(list_win) then
            return
        end

        local line = vim.api.nvim_win_get_cursor(win)[1]
        state.syncing = true
        if win == list_win and records[line] then
            vim.api.nvim_win_set_cursor(source_win, { line, 0 })
        elseif win == source_win then
            local max_line = vim.api.nvim_buf_line_count(list_buf)
            local target_line = math.min(line, max_line)
            if target_line > 0 then
                vim.api.nvim_win_set_cursor(list_win, { target_line, 0 })
            end
        end
        state.syncing = false
    end

    local function sync_scroll(win)
        if state.syncing or state.closed then return end
        if not vim.api.nvim_win_is_valid(win) then return end
        local target_win = (win == list_win) and source_win or list_win
        if not vim.api.nvim_win_is_valid(target_win) then return end

        state.syncing = true
        -- Only the topline is shared; each window keeps its own cursor
        local topline = vim.api.nvim_win_call(win, function() return vim.fn.winsaveview().topline end)
        vim.api.nvim_win_call(target_win, function()
            if vim.fn.winsaveview().topline ~= topline then
                vim.fn.winrestview({ topline = topline })
            end
        end)
        state.syncing = false
    end

    local function show_selected_diff()
        local group = selected_group()
        if not group then return end

        if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
            pcall(vim.api.nvim_win_close, state.diff_win, true)
        end

        local diff, err = file_diff(kind, root, relpath, group)
        if not diff then
            vim.notify('Praise diff: ' .. tostring(err), vim.log.levels.ERROR)
            return
        end

        if not vim.api.nvim_win_is_valid(source_win) then return end
        vim.api.nvim_set_current_win(source_win)
        vim.cmd('botright new')

        state.diff_win = vim.api.nvim_get_current_win()
        local diff_buf = vim.api.nvim_get_current_buf()
        set_scratch(diff_buf, 'diff')

        vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, split_lines(diff))
        vim.bo[diff_buf].modifiable = false
        vim.bo[diff_buf].readonly = true
        vim.cmd('resize ' .. math.max(8, math.floor(vim.o.lines * 0.35)))

        vim.api.nvim_set_current_win(list_win)
    end

    apply_decorations()

    vim.keymap.set('n', '<CR>', show_selected_diff, {
        buffer = list_buf,
        silent = true,
        desc = 'Show selected commit diff',
    })

    state.augroup = vim.api.nvim_create_augroup('PraiseExplorer' .. list_buf, { clear = true })

    -- Cursor Syncing
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = state.augroup,
        buffer = list_buf,
        callback = function() sync_to_source(list_win) end,
    })
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = state.augroup,
        buffer = source_buf,
        callback = function() sync_to_source(source_win) end,
    })

    -- Scroll Syncing
    vim.api.nvim_create_autocmd('WinScrolled', {
        group = state.augroup,
        callback = function(ev)
            local w = tonumber(ev.match)
            if w == list_win or w == source_win then
                sync_scroll(w)
            end
        end,
    })

    -- Auto Refresh on Save
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = state.augroup,
        buffer = source_buf,
        callback = function()
            if state.closed or not vim.api.nvim_buf_is_valid(list_buf) then return end
            local refreshed, refresh_err = (kind == 'jj' and jj_records or git_records)(path, root, relpath)
            if not refreshed then
                vim.notify('Praise refresh: ' .. tostring(refresh_err), vim.log.levels.ERROR)
                return
            end
            records = refreshed
            source_line_count = vim.api.nvim_buf_line_count(source_buf)

            vim.bo[list_buf].readonly = false
            vim.bo[list_buf].modifiable = true
            list_lines, blocks, color_indexes = render_rail(kind, records, source_line_count)
            vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, list_lines)
            vim.bo[list_buf].modifiable = false
            vim.bo[list_buf].readonly = true

            apply_decorations()
        end,
    })

    -- Cleanup on window close
    vim.api.nvim_create_autocmd('WinClosed', {
        group = state.augroup,
        callback = function(ev)
            local w = tonumber(ev.match)
            if w == list_win or w == source_win then
                vim.schedule(function()
                    if not state.closed and type(close_explorer) == 'function' then
                        state.closed = true
                        close_explorer(state)
                    end
                end)
            end
        end,
    })

    -- Open the rail at the source's current position; keep the source cursor untouched
    state.syncing = true
    local source_lnum = vim.api.nvim_win_get_cursor(source_win)[1]
    local source_topline = vim.api.nvim_win_call(source_win, function() return vim.fn.winsaveview().topline end)
    vim.api.nvim_win_call(list_win, function()
        vim.fn.winrestview({ topline = source_topline, lnum = source_lnum })
    end)
    state.syncing = false
end

local function praise_current_line()
    local rel_file_path = vim.fn.shellescape(vim.fn.expand('%:.'))
    local abs_file_dir = vim.fn.shellescape(vim.fn.expand('%:p:h'))
    local file_name = vim.fn.shellescape(vim.fn.expand('%:t'))
    local line_num = tonumber(vim.fn.line('.'))

    vim.fn.system('jj root --cwd ' .. abs_file_dir)
    if vim.v.shell_error == 0 then
        local jj_template = string.format("'if(self.line_number() == %d, self.commit().commit_id())'", line_num)
        local cmd = string.format('jj file annotate %s -T %s', rel_file_path, jj_template)
        local commit_id = vim.fn.trim(vim.fn.system(cmd))
        if commit_id ~= '' then
            local diff_cmd = string.format('jj diff -r %s', vim.fn.shellescape(commit_id))
            show(vim.fn.systemlist(diff_cmd), 'diff')
        else
            print('Could not praise, changeID is empty')
        end
        return
    end

    vim.fn.system('git -C ' .. abs_file_dir .. ' rev-parse --is-inside-work-tree')
    if vim.v.shell_error == 0 then
        local cmd = string.format('git -C %s blame -L %d,%d --porcelain %s', abs_file_dir, line_num, line_num, file_name)
        local commit_id = vim.fn.system(cmd):match('^(%x+)')
        if commit_id and not commit_id:match('^0+$') then
            local diff_cmd = string.format('git -C %s show %s', abs_file_dir, commit_id)
            show(vim.fn.systemlist(diff_cmd), 'diff')
        else
            print('Could not praise, changeID is empty')
        end
        return
    end
    print("Man, you're not in any repo")
end

vim.api.nvim_create_user_command('Blame', function(opts)
    local arg = opts.args:lower()
    if arg == "file" then
        praise_current_file()
    elseif arg == "line" or arg == '' then
        praise_current_line()
    else
        vim.notify("unknown blame target: " .. arg, vim.log.levels.ERROR)
    end
end, {
    nargs = '?',
    complete = function(arg_lead, cmd_line, cursor_pos)
        local subcommands = { 'line', 'file' }
        return vim.tbl_filter(function(item)
            return item:find(arg_lead, 1, true) == 1
        end, subcommands)
    end,
    desc = "vsc blame"

})
