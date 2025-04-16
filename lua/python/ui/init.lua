local config = require('python.config')
local Popup = require("nui.popup")

local empty_system_ui = {
  ---@type NuiPopup|NuiPopup.constructor
  ui = nil,
  line_count = 0,
}

local M = {
  system_ui = vim.deepcopy(empty_system_ui)
}

local function _deactivate_system_call_ui()
  if M.system_ui.ui then
    M.system_ui.ui:unmount()
  end
  M.system_ui = vim.deepcopy(empty_system_ui)
end

-- Turn off ui
---@param timeout? integer time in milliseconds to close ui. Defaults to config option
function M.deactivate_system_call_ui(timeout)
  if timeout == nil then
    timeout = config.ui.ui_close_timeout
  end

  if timeout > 0 then
    vim.defer_fn(function()
      _deactivate_system_call_ui()
    end, timeout)
  else
    _deactivate_system_call_ui()
  end
end

--- Open a ui window to show the output of the command being called.
function M.activate_system_call_ui()
  M.deactivate_system_call_ui(0)
  local ui = nil
  if config.ui.default_ui_style == "popup" then
    ui = Popup({
      border = 'single',
      anchor = "NE",
      relative = "win",
      zindex = config.ui.zindex,
      position = {
        row = 1,
        col = vim.api.nvim_win_get_width(0) - 3,
      },
      size = {
        width = config.ui.popup.demensions.width,
        height = config.ui.popup.demensions.height,
      }
    })
  end
  if ui then
    -- mount/open the component
    ui:mount()
  end
  M.system_ui.ui = ui
end

--- Open a ui w"indow to show the output of the command being called.
---@param err string stderr data
---@param data string stdout data
---@param flush boolean clear ui text and replace with full output
---@param callback function callback function with no arguments
function M.show_system_call_progress(err, data, flush, callback)
  if not M.system_ui.ui then
    return
  end

  local out = data
  if not out then
    out = ""
  end
  if err then
    out = out .. err
  end

  vim.schedule(function()
    out = out:gsub('\r', '')
    local _, line_count = out:gsub('\n', '\n')
    if flush then
      M.system_ui.line_count = 0
      pcall(vim.api.nvim_buf_set_text, M.system_ui.ui.bufnr, 0, 0, 0, 0, {})
    end

    local row = M.system_ui.line_count
    local increase = row + line_count

    if not M.system_ui.ui.bufnr then
      return
    end
    -- Don't throw errors if we can't set the text on the next line for something reason
    pcall(vim.api.nvim_buf_set_text, M.system_ui.ui.bufnr, row, 0, row, 0, vim.fn.split(out .. "\n", "\n"))
    pcall(vim.api.nvim_win_set_cursor, M.system_ui.ui.winid, { row, 0 })

    M.system_ui.line_count = increase
    if callback then
      callback()
    end
  end)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.ui")[k]
  end,
})
