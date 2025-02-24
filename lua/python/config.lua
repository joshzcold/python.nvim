---@type Python.Config
local M = {}

---@class Python.Config
local defaults = {
  foo = true
}

---@type Python.Config
local options

---@param opts? Python.Config
function M.setup(opts)
  opts = opts or {}
  local options = {}
  options = vim.tbl_extend('force', defaults, opts)
end

return setmetatable(M, {
  __index = function(_, key)
    if options == nil then
      M.setup()
    end
    return options[key]
  end,
})
