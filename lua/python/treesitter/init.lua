local tsutil = require('nvim-treesitter.ts_utils')
local nodes = require('python.treesitter.nodes')

local M = {
  queries = {
    query_func = '(function_definition)',
  }
}

function M.test_ts_queries()
  local current_node = tsutil.get_node_at_cursor()
  if not current_node then
    return
  end
  for name, query in pairs(M.queries) do
    ---@class vim.treesitter.Query
    result = vim.treesitter.query.parse("python", query)
    print(vim.inspect(result.captures))
    print(vim.inspect(current_node:type()))
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.treesitter")[k]
  end,
})
