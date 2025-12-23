local nodes = require("python.treesitter.nodes")

local PythonTreeSitter = {
  queries = {
    query_func = "(function_definition)",
  },
}

function PythonTreeSitter.test_ts_queries()
  local current_node = vim.treesitter.get_node()
  if not current_node then
    return
  end
  for name, query in pairs(PythonTreeSitter.queries) do
    ---@class vim.treesitter.Query
    result = vim.treesitter.query.parse("python", query)
    print(vim.inspect(result.captures))
    print(vim.inspect(current_node:type()))
  end
end

return PythonTreeSitter
