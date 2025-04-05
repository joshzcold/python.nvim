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
  -- Path for venvs picker
  venvs_path = vim.fn.expand('~/.virtualenvs'),
  -- Something to do after setting an environment
  post_set_venv = nil,
  -- base path for creating new venvs
  auto_create_venv_path = function(parent_dir)
    return vim.fs.joinpath(parent_dir, '.venv')
  end,
  -- Patterns for autocmd LspAttach that trigger the auto venv logic
  -- Add onto this list if you depend on venvs for other file types
  -- like .yaml, .yml for ansible
  auto_venv_lsp_attach_patterns = { "*.py" },

  -- Filetypes to activate commands for python.nvim
  command_setup_filetypes = { "python" },

  -- Load python.nvim python snippets
  python_lua_snippets = false,

  -- Settings regarding ui handling
  ui = {
    -- Amount of time to pause closing of ui after a finished task
    ui_close_timeout = 5000,
    -- zindex of new ui elements.
    zindex = 999,
    -- Default ui style for interfaces created by python.nvim
    ---@alias python_ui_default_style "'popup'|nil"
    default_ui_style = "popup",
    popup = {
      demensions = {
        width = "60",
        height = "25"
      }
    }
  },

  test = {
    test_runner = "pytest"
  }
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
