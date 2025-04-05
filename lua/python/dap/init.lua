--- DAP integrations

local M = {}

local state = require("python.state")

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
---@param callback? function
function M.prepare_debugpy(callback)
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

--- Interactively create dap configuration
---@param cwd string current working directory for python_state key
---@param venv VEnv venv to attach to pythonPath
---@param python_state  PythonState python_state object
local function create_dap_config(cwd, venv, python_state)
  local dap = require("dap")
  vim.ui.select({ "file", "file:args", "program:args" }, {
    prompt = "python.nvim: Select new dap style configuration"
  }, function(choice)
    if not choice then
        return
    end
    local config = {
      type = 'python',
      request = 'launch',
      name = cwd,
      program = '${file}',
      pythonPath = vim.fs.joinpath(venv.path, "bin", "python")
    }

    if choice == "file:args" then
      vim.ui.input({
        prompt = "Program Arguments: "
      }, function(input)
        local args = vim.split(input, " ")
        config['args'] = args
      end)
    elseif choice == "program:args" then
      vim.ui.input({
        prompt = "Program: "
      }, function(program)
        vim.ui.input({
          prompt = "Program Arguments: "
        }, function(input)
          local args = vim.split(input, " ")
          config['program'] = program
          config['args'] = args
        end)
      end)
    end
    python_state.dap[cwd] = config
    state.save(python_state)
    dap.run(config)
  end)
end

function M.load_commands()
  local dap = require("dap")
  vim.api.nvim_create_user_command("PythonDap", function()
    M.prepare_debugpy(function(venv)
      vim.schedule(function()
        local dap_python = require("dap-python")
        dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
        local python_state = state.State()
        local cwd = vim.fn.getcwd()
        if python_state.dap[cwd] == nil then
            create_dap_config(cwd, venv, python_state)
        else
          vim.ui.select({ "Yes", "Create New" }, {
            prompt = "Use this config?: " .. vim.inspect(python_state.dap[cwd])
          }, function(choice)
            if choice == "Create New" then
              create_dap_config(cwd, venv, python_state)
            elseif choice == "Yes" then
              dap.run(python_state.dap[cwd])
            end
          end)
        end
      end)
    end)
  end, {
    desc = "python.nvim: create or list dap configure"
  })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.dap")[k]
  end,
})
