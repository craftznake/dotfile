local M = {}
local cache = require("craftznake.util.cache")

-- Constant
local CACHE_NAMESPACE = "lsp_utils"
local CACHE_KEY = "lsp_enabled"

-- Get the state from cache or default to true
local function get_cache_state()
  local project_key = cache.get_project_key()
  return cache.get_cached_value(CACHE_NAMESPACE, project_key, true)
end

-- Save the state to cache
local function save_cache_state(enabled)
  local project_key = cache.get_project_key()
  cache.save_value(CACHE_NAMESPACE, project_key, enabled)
end

-- Initialize a flag to toggle LSPs on or off
local lsp_enabled = get_cache_state()
-- Store buffers attached to each LSP client
local attached_buffers_by_client = {}
-- Store configurations for each LSP client
local client_configs = {}

-- Store a reference to the original buf_attach_client function
local original_buf_attach_client = vim.lsp.buf_attach_client

-- Function to add a buffer to the client's buffer table
local function add_buf(client_id, buf)
  if not attached_buffers_by_client[client_id] then
    attached_buffers_by_client[client_id] = {}
  end

  -- Check if the buffer is already in the list
  local exists = false
  for _, value in ipairs(attached_buffers_by_client[client_id]) do
    if value == buf then
      exists = true
      break
    end
  end
  -- Add the buffer if it doesn't already exists in the client's list
  if not exists then
    table.insert(attached_buffers_by_client[client_id], buf)
  end
end

-- Update state with new client IDs after a toggle
local function update_clients_ids(ids_map)
  local new_attached_buffers_by_client = {}
  local new_client_configs = {}
  -- Map each client ID to its new ID and carry over configurations
  for client_id, buffers in ipairs(attached_buffers_by_client) do
    local new_id = ids_map[client_id]
    new_attached_buffers_by_client[new_id] = buffers
    new_client_configs[new_id] = client_configs[client_id]
  end
  attached_buffers_by_client = new_attached_buffers_by_client
  client_configs = new_client_configs
end

-- Stop the client, waiting up to 5 seconds; force quits LSP if needed
local function client_stop(client)
  vim.lsp.stop_client(client.id, false)
  local timer = vim.uv.new_timer()
  local max_attempts = 50
  local attempts = 0

  timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      attempts = attempts + 1

      if client.is_stopped() then
        timer:stop()
        timer:close()
        vim.diagnostic.reset()
      elseif attempts >= max_attempts then
        vim.lsp.stop_client(client.id, true)
        timer:stop()
        timer:close()
        vim.diagnostic.reset()
      end
    end)
  )
end

-- Setup the middleware for LSP client attachment
function M.setup()
  vim.lsp.buf_attach_client = function(bufnr, client_id)
    if not lsp_enabled then
      if not client_configs[client_id] then
        local client_config = vim.lsp.get_client_by_id(client_id)
        client_configs[client_id] = (client_config and client_config.config) or {}
      end
      add_buf(client_id, bufnr)
      vim.lsp.stop_client(client_id)
      return false
    else
      return original_buf_attach_client(bufnr, client_id)
    end
  end
  if lsp_enabled then
    M.enable_lsp()
  else
    M.disable_lsp()
  end
end

-- Disable LSPs
function M.disable_lsp()
  client_configs = {}
  attached_buffers_by_client = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    client_configs[client.id] = client.config
    for buf, _ in pairs(client.attached_buffers) do
      add_buf(client.id, buf)
      vim.lsp.buf_detach_client(buf, client.id)
    end
    client_stop(client)
  end
  print("🐶LSPs Disabled")
  if lsp_enabled then
    lsp_enabled = false
    save_cache_state(lsp_enabled)
  end
end

--
function M.enable_lsp()
  local new_ids = {}
  for client_id, buffers in pairs(attached_buffers_by_client) do
    local client_config = client_configs[client_id]
    local new_client_id, err = vim.lsp.start_client(client_config)

    new_ids[client_id] = new_client_id
    if err or not new_client_id then
      vim.notify(err, vim.log.levels.WARN)
      return nil
    end
    for _, buf in ipairs(buffers) do
      original_buf_attach_client(buf, new_client_id)
    end
  end
  update_clients_ids(new_ids)
  print("🐶LSP Enabled")
  if not lsp_enabled then
    lsp_enabled = true
    save_cache_state(lsp_enabled)
  end
end

-- Toggle LSPs on or off
function M.toggle_lsp()
  if lsp_enabled then
    M.disable_lsp()
  else
    M.enable_lsp()
  end
end

function M.get_lsp_enabled()
  return lsp_enabled
end

return M
