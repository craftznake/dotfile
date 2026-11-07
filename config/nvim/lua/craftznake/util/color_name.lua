local M = {}
function M.setup()
  local highlight = require("lualine.highlight")
  local default_status_colors = { saved = "#228B22", modified = "#C70039" }
  local custom_fname = require("lualine.components.filename"):extend()
  function custom_fname:init(options)
    custom_fname.super.init(self, options)
    self.status_colors = {
      saved = highlight.create_component_highlight_group({}, "filename_status_saved", self.options),
      modified = highlight.create_component_highlight_group(
        { fg = default_status_colors.modified },
        "filename_status_modified",
        self.options
      ),
    }
    if self.options.color == nil then
      self.options.color = ""
    end
  end

  function custom_fname:update_status()
    local data = custom_fname.super.update_status(self)
    data = highlight.component_format_highlight(
      vim.bo.modified and self.status_colors.modified or self.status_colors.saved
    ) .. data
    return data
  end
  M.colored_filename = custom_fname
end

return M
