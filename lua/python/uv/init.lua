local M = {}

return setmetatable(M, {
  __index = function(_, k)
    return require("python.uv")[k]
  end,
})
