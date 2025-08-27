local config = require("python.config")

local split_default_style = {
  split = "below",
  win = 0,
  width = 40,
  height = 10,
  focusable = true,
}

local popup_default_style = {
  border = "rounded",
  relative = "win",
  focusable = true,
  title = "python.nvim",
  anchor = "SE",
  zindex = 999,
  width = 40,
  height = 20,
  row = vim.o.lines - 3,
  col = vim.o.columns - 2,
  style = "minimal",
}

---@class UI
---@field win_opts table<string, any>
---@field win number | nil
---@field buf number | nil
local UI = {
  win_opts = {},
  win = nil,
  buf = nil,
}

function UI:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function UI:mount()
  self.buf = vim.api.nvim_create_buf(false, true)
  self.win = vim.api.nvim_open_win(self.buf, false, self.win_opts)
end

function UI:unmount()
  vim.api.nvim_win_close(self.win, true)
end

local empty_system_ui = {
  ---@type UI
  ui = nil,
  line_count = 0,
}

local PythonUI = {
  system_ui = vim.deepcopy(empty_system_ui),
}

local function _deactivate_system_call_ui()
  if PythonUI.system_ui.ui then
    PythonUI.system_ui.ui:unmount()
  end
  PythonUI.system_ui = vim.deepcopy(empty_system_ui)
end

-- Turn off ui
---@param timeout? integer time in milliseconds to close ui. Defaults to config option
function PythonUI.deactivate_system_call_ui(timeout)
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
function PythonUI.activate_system_call_ui()
  PythonUI.deactivate_system_call_ui(0)
  local ui = nil
  if config.ui.default_ui_style == "popup" then
    local win_opts = vim.tbl_deep_extend("keep", config.ui.popup.win_opts or {}, popup_default_style)
    ui = UI:new({ win_opts = win_opts })
  end
  if config.ui.default_ui_style == "split" then
    local win_opts = vim.tbl_deep_extend("keep", config.ui.split.win_opts or {}, split_default_style)
    ui = UI:new({ win_opts = win_opts })
  end
  if ui then
    -- mount/open the component
    ui:mount()
  end
  PythonUI.system_ui.ui = ui
end

--- Open a ui w"indow to show the output of the command being called.
---@param err string stderr data
---@param data string stdout data
---@param flush boolean clear ui text and replace with full output
---@param callback function callback function with no arguments
function PythonUI.show_system_call_progress(err, data, flush, callback)
  if not PythonUI.system_ui.ui then
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
    out = out:gsub("\r", "")
    local _, line_count = out:gsub("\n", "\n")
    if flush then
      PythonUI.system_ui.line_count = 0
      pcall(vim.api.nvim_buf_set_text, PythonUI.system_ui.ui.buf, 0, 0, 0, 0, {})
    end

    local row = PythonUI.system_ui.line_count
    local increase = row + line_count

    if not PythonUI.system_ui.ui.buf then
      return
    end
    -- Don't throw errors if we can't set the text on the next line for something reason
    pcall(vim.api.nvim_buf_set_text, PythonUI.system_ui.ui.buf, row, 0, row, 0, vim.fn.split(out .. "\n", "\n"))
    pcall(vim.api.nvim_win_set_cursor, PythonUI.system_ui.ui.win, { row, 0 })

    PythonUI.system_ui.line_count = increase
    if callback then
      callback()
    end
  end)
end

return PythonUI
