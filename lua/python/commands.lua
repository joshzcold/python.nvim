---@class python.Commands
local M = {}

local config = require('python.config')

function M.pick_venv()
  print("pick_venv", config.foo)
end

return M
