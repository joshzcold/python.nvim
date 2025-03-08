--- DAP integrations

M = {}

--- Get venv for DAP functions
---@return VEnv | nil venv
local function get_venv()
  local venv = require('python.venv').current_venv()
  if not venv then
    vim.notify("python.nvim: Need a venv to do DAP actions", vim.log.levels.WARN)
    return
  end
  return venv
end


--- Read venv with debug py and launch callback
---@param callback function
local function prepare_debugpy(callback)
  local venv = get_venv()
  if not venv then
    return
  end
  vim.system(
    { vim.fs.joinpath(venv.path, "bin", "pip"), "install", "debugpy" },
    {}, function(obj)
      if obj.code ~= 0 then
        vim.notify('python.nvim: ' .. vim.inspect(obj.stderr), vim.log.levels.ERROR)
        return
      end
      vim.notify(string.format('python.nvim: Installed debugpy into %s', venv.name), vim.log.levels.INFO)
      callback(venv)
    end
  )
end

function M.load_dap_commands()
  vim.api.nvim_create_user_command("PythonDapPytestTestMethod", function()
    prepare_debugpy(function(venv)
      vim.schedule(function()
        local dap_python = require("dap-python")
        dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
        dap_python.test_runner = "pytest"
        dap_python.test_method()
      end)
    end)
  end, {
    desc = "python.nvim: run test method with python dap"
  })
  vim.api.nvim_create_user_command("PythonDapPytestTestClass", function()
    prepare_debugpy(function(venv)
      vim.schedule(function()
        local dap_python = require("dap-python")
        dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
        dap_python.test_runner = "pytest"
        dap_python.test_class()
      end)
    end)
  end, {
    desc = "python.nvim: run test class with python dap"
  })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.dap")[k]
  end,
})
