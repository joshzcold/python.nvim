-- Utility functions and commands utilizing treesitter
local M = {}
local nodes = require('python.treesitter.nodes')

function M.load_commands()
  vim.api.nvim_create_user_command("PythonDictToTypedDict", function()
    print(nodes.inside_function())
  end, {})
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.treesitter.commands")[k]
  end,
})
