---@class python
local M = {}

---@param opts? python.Config
function M.setup(opts)
  require("python.config").setup(opts)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.commands")[k]
  end,
})
