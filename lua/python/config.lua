---@diagnostic disable: missing-fields, inject-field
---@type python.Config
local M = {}

---@class python.Config
local defaults = {
  -- Should return a list of tables with a `name` and a `path` entry each.
  -- Gets the argument `venvs_path` set below.
  -- By default just lists the entries in `venvs_path`.
  ---@return VEnv[]
  get_venvs = function(venvs_path)
    return require('python.venv').get_venvs(venvs_path)
  end,
  -- Path passed to `get_venvs`.
  venvs_path = vim.fn.expand('~/.virtualenvs'),
  -- Something to do after setting an environment
  post_set_venv = nil,
  -- Attempt detect and auto create venv directories using
  -- pdm
  -- requirements.txt
  -- dev-requirements.txt
  -- pyproject.toml
  auto_create_venv = false,
  -- directory to create for venv auto creation
  auto_create_venv_dir = '.venv',
}

---@param opts? python.Config
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', defaults, opts)
end

return setmetatable(M, {
  __index = function(_, key)
    if M.config == nil then
      M.setup()
    end
    return M.config[key]
  end,
})
