local config = require('python.config')
local state = require("python.state")
local interpreters = require("python.venv.interpreters")
local ui = require("python.ui")
local M = {}

---Remove venv from state by key
---@param venv_key string
---@param delete_dir boolean attempt deletion of venv from directory
function M.delete_venv_from_state(venv_key, delete_dir)
  if not venv_key then
    vim.notify_once(string.format("python.nvim: Could not delete venv from state. venv_key was nil"),
      vim.log.levels.ERROR)
    return
  end
  local lsp = require("python.lsp")
  local python_venv = require('python.venv')


  local python_state = state.State()
  if not python_state.venvs[venv_key] then
    vim.notify_once(
      string.format("python.nvim: Could not delete venv from state. %s was not found in state.venv", venv_key),
      vim.log.levels.ERROR)
    return
  end

  if not delete_dir then
    return
  end
  local old_venv_path = python_state.venvs[venv_key].venv_path
  if not old_venv_path then
    return
  end
  if vim.fn.isdirectory(old_venv_path) then
    vim.ui.select({ "Yes", "No" }, {
      prompt = ("Delete this venv directory?: %s"):format(old_venv_path)
    }, function(choice)
      if choice and choice == "Yes" then
        vim.fn.delete(old_venv_path, "rf")
        vim.notify_once(string.format("python.nvim: Deleted venv: %s", old_venv_path), vim.log.levels.WARN)
      end
    end)
  end

  python_venv.set_venv_path(nil)
  lsp.notify_workspace_did_change()

  for k, _ in pairs(python_state.venvs) do
    if k == venv_key then
      python_state.venvs[venv_key] = nil
      break
    end
  end
  state.save(python_state)
end

--- Set venv. Only set venv if its different than current.
--- local venv_dir = settings.auto_create_venv_dir
---@param venv_path string | nil full path to venv directory
---@param venv_name string name of the venv to set
---@param venv_source? string name of the source of the venv. useful in determining conda or venv
function M.python_set_venv(venv_path, venv_name, venv_source)
  local lsp = require("python.lsp")
  if venv_path then
    local python_venv = require('python.venv')
    local current_venv_name = nil
    local current_venv = python_venv.current_venv()
    if current_venv then
      current_venv_name = current_venv.name
    end
    if vim.fs.basename(venv_path) ~= current_venv_name then
      if not venv_source then
        venv_source = "venv"
      end
      python_venv.set_venv_path({ path = venv_path, name = venv_name, source = venv_source })
      vim.notify_once("python.nvim: set venv at: " .. venv_path)
      lsp.notify_workspace_did_change()
    end
  end
end

--- Run uv sync at lock file directory. Set env path when done.
---@param uv_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
---@param script boolean are we installing from a script definition
function M.uv_sync(uv_lock_path, venv_dir, callback, script)
  vim.schedule(function()
    if vim.fn.executable("uv") == 0 then
      vim.notify_once(
        ("python.nvim: 'uv' application not found please install: %s"):format("https://github.com/astral-sh/uv"),
        vim.log.levels.ERROR)
      return
    end
    vim.notify_once('python.nvim: starting uv sync at: ' .. uv_lock_path, vim.log.levels.INFO)
    local dir_name = vim.fs.dirname(uv_lock_path)
    local cmd = {
      'uv', 'sync', "--active", "--frozen"
    }
    -- Install from /// script definition in python script
    if script then
      vim.notify_once("python.nvim: Installing dependencies from uv script block")
      cmd = { 'uv', 'sync', '--active', '--script', vim.api.nvim_buf_get_name(0) }
    end
    vim.system(
      cmd,
      {
        cwd = dir_name,
        stdout = ui.show_system_call_progress,
        env = {
          VIRTUAL_ENV = venv_dir
        }
      },
      function(obj)
        vim.schedule(
          function()
            if obj.code ~= 0 then
              vim.notify_once('python.nvim: ' .. vim.inspect(obj.stderr), vim.log.levels.ERROR)
              return
            end
            ui.show_system_call_progress(obj.stderr, obj.stdout, true, function()
              ui.deactivate_system_call_ui()
            end)
            callback()
          end
        )
      end
    )
    ui.activate_system_call_ui()
  end)
end

--- Run pdm sync at lock file directory. Set env path when done.
---@param pdm_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
function M.pdm_sync(pdm_lock_path, venv_dir, callback)
  if vim.fn.executable("pdm") == 0 then
    vim.notify_once(
      ("python.nvim: 'pdm' application not found please install: %s"):format("https://pdm-project.org/en/latest/"),
      vim.log.levels.ERROR)
    return
  end
  vim.notify_once('python.nvim: starting pdm sync at: ' .. pdm_lock_path, vim.log.levels.INFO)
  local dir_name = vim.fs.dirname(pdm_lock_path)
  vim.system(
    { 'pdm', 'use', '-f', venv_dir },
    {
      cwd = dir_name
    },
    function(obj1)
      if obj1.code ~= 0 then
        vim.notify_once('python.nvim: ' .. vim.inspect(obj1.stderr), vim.log.levels.ERROR)
        ui.deactivate_system_call_ui(10000)
        return
      end
      vim.system(
        { 'pdm', 'sync' },
        {
          cwd = dir_name,
          stdout = ui.show_system_call_progress
        },
        function(obj2)
          vim.schedule(
            function()
              if obj2.code ~= 0 then
                vim.notify_once('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
                return
              end
              ui.show_system_call_progress(obj2.stderr, obj2.stdout, true, function()
                ui.deactivate_system_call_ui()
              end)
              callback()
            end
          )
        end
      )
      vim.schedule(function()
        ui.activate_system_call_ui()
      end)
    end
  )
end

--- Run pdm sync at lock file directory. Set env path when done.
---@param poetry_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
function M.poetry_sync(poetry_lock_path, venv_dir, callback)
  if vim.fn.executable("poetry") == 0 then
    vim.notify_once(
      ("python.nvim: 'poetry' application not found please install: %s"):format("https://python-poetry.org/"),
      vim.log.levels.ERROR)
    return
  end
  vim.notify_once('python.nvim: starting poetry sync at: ' .. poetry_lock_path, vim.log.levels.INFO)
  local dir_name = vim.fs.dirname(poetry_lock_path)
  vim.system(
    { 'poetry', 'env', 'use', vim.fs.joinpath(venv_dir, "bin", "python") },
    {
      cwd = dir_name
    },
    function(obj1)
      if obj1.code ~= 0 then
        vim.notify_once('python.nvim: ' .. vim.inspect(obj1.stderr), vim.log.levels.ERROR)
        ui.deactivate_system_call_ui(10000)
        return
      end
      vim.system(
        { 'poetry', 'sync', '--no-root' },
        {
          cwd = dir_name,
          stdout = ui.show_system_call_progress
        },
        function(obj2)
          vim.schedule(
            function()
              if obj2.code ~= 0 then
                vim.notify_once('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
                return
              end
              ui.show_system_call_progress(obj2.stderr, obj2.stdout, true, function()
                ui.deactivate_system_call_ui()
              end)
              callback()
            end
          )
        end
      )
      vim.schedule(function()
        ui.activate_system_call_ui()
      end)
    end
  )
end

--- Create venv with python venv module and pip install at location
---@param requirements_path string full path to requirements.txt, dev-requirements.txt or pyproject.toml
---@param venv_dir string
---@param callback function
function M.pip_install_with_venv(requirements_path, venv_dir, callback)
  local dir_name = vim.fs.dirname(requirements_path)
  vim.notify_once(
    'python.nvim: starting pip install at: ' .. requirements_path .. ' in venv: ' .. venv_dir,
    vim.log.levels.INFO
  )
  vim.schedule(
    function()
      local pip_path = venv_dir .. '/' .. 'bin/pip'
      local pip_cmd = { pip_path, 'install', '-r', requirements_path }

      if string.find(requirements_path, 'pyproject.toml$') then
        pip_cmd = { pip_path, 'install', '.' }
      end
      vim.system(
        pip_cmd,
        {
          cwd = dir_name,
          stdout = ui.show_system_call_progress
        },
        function(obj2)
          vim.schedule(function()
            if obj2.code ~= 0 then
              vim.notify_once('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
              ui.deactivate_system_call_ui(10000)
            else
              ui.show_system_call_progress(obj2.stderr, obj2.stdout, true, function()
                ui.deactivate_system_call_ui()
              end)
              callback()
            end
          end)
        end
      )
      vim.schedule(function()
        ui.activate_system_call_ui()
      end)
    end
  )
end

---Create the python venv with selected interpreter"
---@param venv_path string path of venv to create
---@param python_interpreter string path to python executable to use
function M.create_venv_with_python(venv_path, python_interpreter)
  vim.notify_once('python.nvim: creating venv at: ' .. venv_path, vim.log.levels.INFO)
  local cmd = { python_interpreter, '-m', 'venv', venv_path }
  vim.system(
    cmd,
    {},
    function(obj)
      if obj.code ~= 0 then
        vim.notify_once('python.nvim: ' .. vim.inspect(obj.stderr .. obj.stdout), vim.log.levels.ERROR)
        return
      end
    end):wait()
end

--- Have user select a python interpreter from found options.
--- Expected to be running in a coroutine for vim.ui
---@return string | nil Path to python interpreter
local function pick_python_interpreter()
  local co = coroutine.running()
  vim.schedule(function()
    vim.ui.select(interpreters.python_interpreters(), { prompt = 'Select a python interpreter: ' },
      function(str) coroutine.resume(co, str) end)
  end)
  local python_interpreter_user_input = coroutine.yield()
  if not python_interpreter_user_input then
    return
  end
  return python_interpreter_user_input
end


--- Have user input the path to the venv they want to create, with a supplied default
--- Expected to be running in a coroutine for vim.ui
---@param detect DetectVEnv
---@return string | nil Path to venv that user wants to create
local function pick_venv_path(detect)
  local detectM = require("python.venv.detect")
  local default_input = config.auto_create_venv_path(detect.dir)
  local description = detectM.check_paths[detect.venv.install_method].desc

  local coro = coroutine.running()
  vim.schedule(function()
    vim.ui.input({
        prompt = description .. "\nInput new venv path: ",
        default = default_input
      },
      function(str)
        coroutine.resume(coro, str)
      end)
  end)
  local venv_path_user_input = coroutine.yield()

  if venv_path_user_input == nil then
    return
  end

  local wanted_dir = vim.fs.dirname(venv_path_user_input)
  if vim.fn.isdirectory(wanted_dir) == 0 then
    vim.notify_once(string.format("Error: directory of new venv doesn't exist: '%s'", venv_path_user_input),
      vim.log.levels.ERROR)
    return
  end
  return venv_path_user_input
end

--- Do Update or Installation of the venv, either update an existing venv or have the user select to
--- create a new venv and install dependencies, selecting a python interpreter.
---@param detect DetectVEnv
local function venv_install_file(detect)
  local detectM = require("python.venv.detect")
  -- Keep track of last set venv dir in module level variable. This allows us to retrigger the venv
  -- update when we detect a new dependency file while still in a neovim session.
  local last_parent_dir = Auto_set_python_venv_parent_dir
  if last_parent_dir ~= detect.dir then
    Auto_set_python_venv_parent_dir = detect.dir
  end

  local install_function = detectM.check_paths[detect.venv.install_method].func

  -- We detected a pre-existing venv and we want to just update its dependencies
  if detect.venv.venv_path ~= nil or detect.venv.python_interpreter ~= nil then
    if not install_function then
      vim.notify(
        ("python.nvim: Unable to find an install function for detected method: '%s'"):format(detect.venv.install_method),
        vim.log.levels.ERROR)
      return
    end
    install_function(detect.venv.install_file, detect.venv.venv_path, function() end)
    return
  end

  -- We need to create the venv and pick its python interpreter
  -- Get venv path to create
  coroutine.resume(coroutine.create(function()
    local venv_path_user_input = pick_venv_path(detect)
    if venv_path_user_input == nil then
      vim.notify("python.nvim: Skipping venv creation, no venv path selected", vim.log.levels.WARN)
      return
    end
    -- Get wanted python interpreter
    local python_interpreter_user_input = pick_python_interpreter()
    if python_interpreter_user_input == nil then
      vim.notify("python.nvim: Skipping venv creation, no python selected.", vim.log.levels.WARN)
      return
    end

    M.create_venv_with_python(venv_path_user_input, python_interpreter_user_input)

    install_function(detect.venv.install_file, venv_path_user_input, function()
      local val = {
        python_interpreter = python_interpreter_user_input,
        venv_path = venv_path_user_input,
        install_method = detect.venv.install_method,
        install_file = detect.venv.install_file,
        source = "venv"
      }
      local python_state = state.State()

      local venv_name = vim.fs.basename(vim.fs.dirname(detect.venv.install_file))
      M.python_set_venv(val.venv_path, venv_name)
      python_state.venvs[detect.dir] = val
      state.save(python_state)
    end)
  end))
end

local function set_venv_state()
  local detectM = require("python.venv.detect")
  ---@type DetectVEnv | nil
  local detect = detectM.detect_venv_dependency_file(false, false)

  if detect == nil then
    vim.notify(
      "python.nvim: Could not find a python dependency file for this cwd",
      vim.log.levels.WARN)
    return
  end

  venv_install_file(detect)
end

--- Automatically create venv directory and use multiple method to auto install dependencies
--- Use module level variable Auto_set_python_venv_parent_dir to keep track of the last venv dir, so
---   We don't do the creation process again when you are in the same project.
function M.create_and_install_venv()
  set_venv_state()
end

local function delete_venv_from_selection()
  local python_state = state.State()

  local keys = {}
  for cwd, _ in pairs(python_state.venvs) do
    table.insert(keys, cwd)
  end

  vim.ui.select(keys, {
    prompt = "Delete venv project from state: "
  }, function(choice)
    if choice == nil then
      return
    end
    M.delete_venv_from_state(choice, true)
  end)
end

---Delete a venv from state and filesystem
---@param select boolean
function M.delete_venv(select)
  local detectM = require("python.venv.detect")
  if select then
    delete_venv_from_selection()
    return
  end
  local detect = detectM.detect_venv_dependency_file(false, true)
  if detect == nil then
    vim.notify("python.nvim: Current venv in not found in state. Cant continue", vim.log.levels.WARN)
    return
  end
  M.delete_venv_from_state(detect.dir, true)
end

--- Interactively set a venv in state.
--- This is used when users manually select a venv and want it cached for next run.
---@param venv VEnv venv object to pull from
function M.user_set_venv_in_state_confirmation(venv)
  local cwd = vim.fn.getcwd()
  local python_state = state.State()
  vim.ui.select({ "Yes", "No" }, {
    prompt = string.format("Save env path for this cwd? '%s' -> '%s': ", cwd, venv.path)
  }, function(choice)
    if choice == "Yes" then
      python_state.venvs[cwd] = {
        python_interpreter = "unknown",
        venv_path = venv.path,
        install_method = "unknown",
        install_file = "unknown",
        source = venv.source
      }
      state.save(python_state)
      vim.notify_once(string.format(
        "python.nvim: Saved venv '%s' for cwd '%s'. Use :PythonVEnvDeleteSelect to remove it.",
        venv.path, cwd))
    end
  end)
end

function M.detect_contents_for_dependencies(_, _)
  local detectM = require("python.venv.detect")
  for pattern, install_function in pairs(detectM.check_file_patterns) do
    local match = vim.fn.getline(vim.fn.search(pattern, 'n'))
    if match ~= nil then
      install_function()
    end
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.venv.create")[k]
  end,
})
