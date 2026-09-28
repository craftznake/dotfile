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
            commit = { id = hash, lines = {}, path = path }
            records[tonumber(final)] = commit
        elseif commit and line:match('^summary ') then
            commit.summary = line:sub(9)
        elseif commit and line:match('^author ') then
            commit.author = line:sub(8)
        elseif commit and line:match('^\t') then
            commit = nil
        end
    end

    local grouped, by_id = {}, {}
    for line_num, record in pairs(records) do
        local group = by_id[record.id]
        if not group then
            group = record
            by_id[group.id] = group
            grouped[#grouped + 1] = group
        end
        group.lines[#group.lines + 1] = line_num
        records[line_num] = group
    end
    table.sort(grouped, function(a, b) return a.lines[1] < b.lines[1] end)
    return grouped, records
end

local function jj_records(path, root, relpath)
    local template =
    'self.line_number() ++ "\\x1f" ++ self.commit().change_id() ++ "\\x1f" ++ self.commit().commit_id() ++ "\\x1f" ++ self.commit().description().first_line() ++ "\\x1f" ++ self.commit().author().name() ++ "\\x1f" ++ self.content()'
    local output, err = run({ 'jj', '--repository', root, 'file', 'annotate', relpath, '-T', template }, root)
    if not output then return nil, err end

    local grouped, by_id, records = {}, {}, {}
    for row in (output .. '\n'):gmatch('(.-)\n') do
        local number, change_id, commit_id, summary, author = row:match('^(.-)\31(.-)\31(.-)\31(.-)\31(.-)\31')
        if number then
            local line_num = tonumber(number)
            local group = by_id[change_id]
            if not group then
                group = {
                    id = change_id,
                    commit_id = commit_id,
                    summary = summary,
                    author = author,
                    lines = {},
                    path = path
                }
                by_id[change_id] = group
                grouped[#grouped + 1] = group
            end
            group.lines[#group.lines + 1] = line_num
            records[line_num] = group
        end
    end
    table.sort(grouped, function(a, b) return a.lines[1] < b.lines[1] end)
    return grouped, records
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
    return run({ 'jj', '--repository', root, 'diff', '--git', '-r', group.commit_id, '--', relpath }, root)
end

local praise_colors = {
    { fg = '#fb4934' },
    { fg = '#b8bb26' },
    { fg = '#fabd2f' },
    { fg = '#83a598' },
    { fg = '#d3869b' },
    { fg = '#8ec07c' },
    { fg = '#fe8019' },
    { fg = '#d65d0e' },
}

local function color_for(group)
    local hash = 0
    for i = 1, #group.id do
        hash = (hash * 31 + group.id:byte(i)) % #praise_colors
    end
    return praise_colors[hash + 1]
end

local function render_groups(kind, groups)
    local lines, markers = {}, {}
    for i, group in ipairs(groups) do
        local label = kind == 'jj' and group.id or group.id:sub(1, 12)
        local start_row = #lines + 1
        lines[#lines + 1] = string.format('▌ %s  %s', label, group.summary or '(no description)')
        lines[#lines + 1] = string.format('  %s · %d line%s', group.author or 'Unknown author', #group.lines,
            #group.lines == 1 and '' or 's')
        markers[#markers + 1] = { row = start_row, end_row = start_row + 1, group = group }
        if i < #groups then lines[#lines + 1] = '' end
    end
    if #lines == 0 then lines[1] = 'No committed lines to display' end
    return lines, markers
end

local function source_line_group(records, line)
    return records[line]
end

local function close_explorer(state)
    if state.closed then return end
    state.closed = true
    if state.augroup then pcall(vim.api.nvim_del_augroup_by_id, state.augroup) end
    if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then pcall(vim.api.nvim_win_close, state.diff_win, true) end
    if state.list_win and vim.api.nvim_win_is_valid(state.list_win) then pcall(vim.api.nvim_win_close, state.list_win, true) end
    if state.list_buf and vim.api.nvim_buf_is_valid(state.list_buf) then
        pcall(vim.api.nvim_buf_delete, state.list_buf, { force = true })
    end
end

local function explorer()
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
    local groups, records_or_err = (kind == 'jj' and jj_records or git_records)(path, root, relpath)
    if not groups then
        vim.notify('Praise: ' .. tostring(records_or_err), vim.log.levels.ERROR)
        return
    end

    local source_win = vim.api.nvim_get_current_win()
    vim.cmd('topleft vertical new')
    local list_win, list_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
    set_scratch(list_buf, 'praise')
    vim.bo[list_buf].modifiable = true
    local list_lines, list_markers = render_groups(kind, groups)
    vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, list_lines)
    vim.bo[list_buf].modifiable = false
    vim.bo[list_buf].readonly = true
    vim.wo[list_win].number = false
    vim.wo[list_win].relativenumber = false
    vim.wo[list_win].signcolumn = 'no'
    vim.cmd('vertical resize 38')
    vim.api.nvim_set_current_win(source_win)

    local ns = vim.api.nvim_create_namespace('PraiseExplorer' .. list_buf)
    local state = {
        list_win = list_win,
        list_buf = list_buf,
        source_buf = source_buf,
        source_win = source_win,
        selected_group = nil,
        syncing = false,
    }

    local function apply_decorations()
        vim.api.nvim_buf_clear_namespace(source_buf, ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
        for _, marker in ipairs(list_markers) do
            vim.api.nvim_set_hl(0, 'PraiseCommit' .. marker.group.id, color_for(marker.group))
            vim.api.nvim_buf_set_extmark(list_buf, ns, marker.row - 1, 0, {
                end_row = marker.end_row,
                hl_group = 'PraiseCommit' .. marker.group.id,
                hl_eol = true,
                priority = 120,
            })
            for _, line in ipairs(marker.group.lines) do
                vim.api.nvim_buf_set_extmark(source_buf, ns, line - 1, 0, {
                    sign_text = '▌',
                    sign_hl_group = 'PraiseCommit' .. marker.group.id,
                    priority = 120,
                })
                vim.api.nvim_buf_set_extmark(source_buf, ns, line - 1, 0, {
                    line_hl_group = 'PraiseCommit' .. marker.group.id,
                    priority = 20,
                })
            end
        end
    end

    local function group_at_list_row(row)
        for _, marker in ipairs(list_markers) do
            if row >= marker.row and row <= marker.end_row then return marker.group end
        end
        return nil
    end

    local function select_group(group)
        if not group then return end
        state.selected_group = group
        state.syncing = true
        if vim.api.nvim_win_is_valid(source_win) then
            vim.api.nvim_win_set_cursor(source_win, { group.lines[1], 0 })
            vim.api.nvim_win_call(source_win, function() vim.cmd('normal! zv') end)
        end
        state.syncing = false
        if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then pcall(vim.api.nvim_win_close, state.diff_win, true) end
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

    local function select_group_at_cursor()
        select_group(group_at_list_row(vim.api.nvim_win_get_cursor(list_win)[1]))
    end

    local function sync_list_to_source()
        if state.syncing or state.closed then return end
        local source_line = vim.api.nvim_win_get_cursor(source_win)[1]
        local group = source_line_group(records_or_err, source_line)
        if not group then return end
        state.selected_group = group
        for _, marker in ipairs(list_markers) do
            if marker.group == group then
                state.syncing = true
                vim.api.nvim_win_set_cursor(list_win, { marker.row, 0 })
                state.syncing = false
                break
            end
        end
    end

    apply_decorations()
    vim.keymap.set('n', '<CR>', select_group_at_cursor, { buffer = list_buf, silent = true, desc = 'Show selected commit' })
    vim.keymap.set('n', 'q', function() close_explorer(state) end, { buffer = list_buf, silent = true, desc = 'Close Praise explorer' })
    state.augroup = vim.api.nvim_create_augroup('PraiseExplorer' .. list_buf, { clear = true })
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = state.augroup,
        buffer = list_buf,
        callback = select_group_at_cursor,
    })
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = state.augroup,
        buffer = source_buf,
        callback = sync_list_to_source,
    })
    vim.api.nvim_create_autocmd('WinEnter', {
        group = state.augroup,
        callback = function()
            if vim.api.nvim_get_current_win() == source_win then sync_list_to_source() end
        end,
    })
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
            groups, records_or_err = refreshed
            vim.bo[list_buf].modifiable = true
            list_lines, list_markers = render_groups(kind, groups)
            vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, list_lines)
            vim.bo[list_buf].modifiable = false
            vim.bo[list_buf].readonly = true
            apply_decorations()
        end,
    })
    vim.api.nvim_create_autocmd('WinClosed', {
        group = state.augroup,
        pattern = tostring(list_win),
        once = true,
        callback = function() vim.schedule(function() close_explorer(state) end) end,
    })
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

vim.api.nvim_create_user_command('Praise', explorer, {})
vim.api.nvim_create_user_command('PraiseThis', praise_current_line, {})
vim.api.nvim_create_user_command('Blame', praise_current_line, {})
