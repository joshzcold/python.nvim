local tsutil = require('nvim-treesitter.ts_utils')
local nodes = require('python.treesitter.nodes')


local M = {
  query_func = '(function_definition)',
}

return setmetatable(M, {
  __index = function(_, k)
    return require("python.treesitter")[k]
  end,
})
