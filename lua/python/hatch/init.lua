local M = {}

return setmetatable(M, {
  __index = function(_, k)
    return require("python.hatch")[k]
  end,
})
