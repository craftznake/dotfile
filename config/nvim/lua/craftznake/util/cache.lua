local M = {}

-- Get the cache directory path
local function get_cache_dir()
  local cache_dir = vim.fn.stdpath("state") .. "/craftznake_cache"
  -- Create directory if it doesn't exist
  if vim.fn.isdirectory(cache_dir) == 0 then
    vim.fn.mkdir(cache_dir, "p", "0o700")
  end
  return cache_dir
end

-- Get a safe filename from a key (replace special characters)
local function get_safe_filename(key)
  -- Replace special characters with underscores
  local safe_key = key:gsub("[^%w_%-]", "_")
  return safe_key
end

-- Get the current project directory
function M.get_project_key()
  -- Try to get git root first
  local git_dir = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error == 0 then
    return git_dir
  end
  -- Fallback to current working directory
  return vim.fn.getcwd()
end

-- Get cached value for a key and namespace
function M.get_cached_value(namespace, key, default_value)
  local cache_dir = get_cache_dir()
  local safe_key = get_safe_filename(key)
  local cache_file = string.format("%s/%s_%s", cache_dir, namespace, safe_key)

  local file, err = io.open(cache_file, "r")
  if err then
    M.save_value(namespace, key, default_value)
    return default_value
  end
  if file then
    local content = file:read("*all")
    file:close()

    -- Try to convert string representations back to their original type
    if content == "true" then
      return true
    elseif content == "false" then
      return false
    elseif tonumber(content) then
      return tonumber(content)
    end
    return content
  end
  return default_value
end

-- Save value for a key and namespace
function M.save_value(namespace, key, value)
  local cache_dir = get_cache_dir()
  local safe_key = get_safe_filename(key)
  local cache_file = string.format("%s/%s_%s", cache_dir, namespace, safe_key)

  local file, err = io.open(cache_file, "w")
  if err then
    return false
  end
  if file then
    -- Convert value to string representation
    local content = tostring(value)
    file:write(content)
    file:close()
    return true
  end
  return false
end

return M
