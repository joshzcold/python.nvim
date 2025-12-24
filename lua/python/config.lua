---@diagnostic disable: missing-fields, inject-field
---@type python.Config
local PythonConfig = {}

--- Python.nvim config
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@class python.Config
PythonConfig.defaults = {
  -- Should return a list of tables with a `name` and a `path` entry each.
  -- Gets the argument `venvs_path` set below.
  -- By default just lists the entries in `venvs_path`.
  ---@return VEnv[]
  get_venvs = function(venvs_path)
    return require("python.venv").get_venvs(venvs_path)
  end,
  -- Path for venvs picker
  venvs_path = vim.fn.expand("~/.virtualenvs"),
  -- Something to do after setting an environment
  post_set_venv = false,
  -- base path for creating new venvs
  auto_create_venv_path = function(parent_dir)
    return vim.fs.joinpath(parent_dir, ".venv")
  end,
  -- Patterns for autocmd LspAttach that trigger the auto venv logic
  -- Add onto this list if you depend on venvs for other file types
  -- like .yaml, .yml for ansible
  auto_venv_lsp_attach_patterns = { "*.py" },

  -- Buffer patterns to activate commands for python.nvim
  command_setup_buf_pattern = { "*.py" },

  -- Load python.nvim python snippets
  python_lua_snippets = false,

  -- List of text actions to take on InsertLeave, TextChanged
  -- Put in empty table or nil to disable
  enabled_text_actions = {
    "f-strings", -- When inserting {}, put in an f-string
  },
  -- Adjust when enabled_text_actions is triggered
  enabled_text_actions_autocmd_events = { "InsertLeave" },

  treesitter = {
    functions = {
      -- Wrap treesitter identifier under cursor using substitute_options
      wrapper = {
        -- Substitute options for PythonTSWrapWithFunc
        substitute_options = {
          "print(%s)",
          "log.debug(%s)",
          "log.info(%s)",
          "log.warning(%s)",
          "log.error(%s)",
          "np.array(%s)",
        },

        -- Look for tree-sitter types to wrap
        find_types = {
          "tuple",
          "string",
          "true",
          "false",
          "list",
          "call",
          "parenthesized_expression",
          "expression_statement",
          "integer",
        },
      },
    },
  },
  -- Settings regarding ui handling
  ui = {
    -- Amount of time to pause closing of ui after a finished task
    ui_close_timeout = 5000,

    -- Default ui style for interfaces created by python.nvim
    ---@alias python_ui_default_style "'popup'|'split'|nil"
    default_ui_style = "popup",

    -- Customize the position and behavior of the ui style
    popup = {
      win_opts = {
        -- border = "rounded",
        -- relative = "win",
        -- focusable = true,
        -- title = "python.nvim",
        -- anchor = "SE",
        -- zindex = 999,
        -- width = 40,
        -- height = 20,
        -- row = vim.o.lines - 3,
        -- col = vim.o.columns -2,
      },
    },
    split = {
      win_opts = {
        -- split = 'below',
        -- win = 0,
        -- width = 40,
        -- height = 10,
        -- focusable = true,
      },
    },
  },

  -- Tell neotest-python which test runner to use
  test = {
    test_runner = "pytest",
  },
}
--minidoc_afterlines_end

-- Only for existing keys in `target`.
local function tbl_deep_extend_existing(target, source, prev_key)
  -- Return if source or target is not a table or is nil
  if type(target) ~= "table" or type(source) ~= "table" then
    return target
  end

  for key, value in pairs(source) do
    -- Only update keys that already exist in the target table
    if target[key] ~= nil then
      if type(target[key]) == "table" and type(value) == "table" then
        prev_key = prev_key .. "." .. key
        -- Recurse for nested tables
        tbl_deep_extend_existing(target[key], value, prev_key)
      else
        -- Overwrite existing key
        target[key] = value
      end
    else
      error(("python.nvim: user inputted config key: %s is not found in config table: %s"):format(key, prev_key))
    end
  end
  return target
end

---@param opts? python.Config
function PythonConfig.setup(opts)
  opts = opts or {}
  PythonConfig.config = tbl_deep_extend_existing(PythonConfig.defaults, opts, "config")
end

return setmetatable(PythonConfig, {
  __index = function(_, key)
    if PythonConfig.config == nil then
      PythonConfig.setup()
    end
    return PythonConfig.config[key]
  end,
})
