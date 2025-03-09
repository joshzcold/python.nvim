local M = {}
local nodes = require('python.treesitter.nodes')
local config = require('python.config')

function M.is_in_test_file()
  local filename = vim.fn.expand('%:p')
  -- no required convention for python tests.
  -- Just assume if test is in the full path we might be in a test file.
  return string.find(filename, "test")
end

function M.is_in_test_function()
  return M.is_in_test_file() and nodes.inside_function()
end

local snippets = {

}

function M.load_snippets()
  if not config.python_snippets then
    return
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.snip")[k]
  end,
})
