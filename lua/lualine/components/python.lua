local M = require('lualine.component'):extend()

local default_opts = {
  icon = '',
  color = { fg = '#FFD43B' },
}

function M:init(options)
  options = vim.tbl_deep_extend('keep', options or {}, default_opts)
  M.super.init(self, options)
end

function M:update_status()
  local venv = require('python.venv').current_venv()
  if venv then
    return venv.name
  else
    return 'no venv'
  end
end

return M
