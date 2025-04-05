local config = require("python.config")
local venv = require("python.venv")


local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

M = {}

function M.load_keymaps()
  if next(config.keymaps.mappings) == nil then
    return
  end
  for key, val in pairs(config.keymaps.mappings) do
    map(val[1], key, val[2], val[3])
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.keymap")[k]
  end,
})
