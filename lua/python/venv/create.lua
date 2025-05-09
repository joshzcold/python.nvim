local config = require('python.config')
local state = require("python.state")
local IS_WINDOWS = vim.uv.os_uname().sysname == 'Windows_NT'
local IS_MACOS = vim.uv.os_uname().sysname == 'Darwin'
local ui = require("python.ui")

--- Set venv. Only set venv if its different than current.
--- local venv_dir = settings.auto_create_venv_dir
---@param venv_path string full path to venv directory
---@param venv_name string name of the venv to set
---@param venv_source? string name of the source of the venv. useful in determining conda or venv
local function python_set_venv(venv_path, venv_name, venv_source)
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

--- Search for file or directory until we either the top of the git repo or root
---@param dir_or_file string name of directory or file
---@return string | nil found either nil or full path of found file/directory
local function search_up(dir_or_file)
  local found = nil
  local dir_to_check = nil
  -- get parent directory of current file in buffer via vim expand
  local dir_template = '%:p:h'
  while not found and dir_to_check ~= '/' do
    dir_to_check = vim.fn.expand(dir_template)
    local check_path = dir_to_check .. '/' .. dir_or_file
    local check_git = dir_to_check .. '/' .. '.git'
    if vim.fn.isdirectory(check_path) == 1 or vim.fn.filereadable(check_path) == 1 then
      found = dir_to_check .. '/' .. dir_or_file
    else
      dir_template = dir_template .. ':h'
    end
    -- If we hit a .git directory then stop searching and return found even if nil
    if vim.fn.isdirectory(check_git) == 1 then
      return found
    end
  end
  return found
end

--- Run uv sync at lock file directory. Set env path when done.
---@param uv_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
local function uv_sync(uv_lock_path, venv_dir, callback)
  if vim.fn.executable("uv") == 0 then
    vim.notify_once(
      ("python.nvim: 'uv' application not found please install: %s"):format("https://github.com/astral-sh/uv"),
      vim.log.levels.ERROR)
    return
  end
  vim.notify_once('python.nvim: starting uv sync at: ' .. uv_lock_path, vim.log.levels.INFO)
  local dir_name = vim.fs.dirname(uv_lock_path)
  vim.print(dir_name)
  vim.system(
    { 'uv', 'sync' },
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
  vim.schedule(function()
    ui.activate_system_call_ui()
  end)
end

--- Run pdm sync at lock file directory. Set env path when done.
---@param pdm_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
local function pdm_sync(pdm_lock_path, venv_dir, callback)
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
local function poetry_sync(poetry_lock_path, venv_dir, callback)
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
local function pip_install_with_venv(requirements_path, venv_dir, callback)
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

local check_paths = {
  ['requirements.txt'] = function(install_file, venv_dir, callback)
    pip_install_with_venv(install_file, venv_dir, callback)
  end,
  ['dev-requirements.txt'] = function(install_file, venv_dir, callback)
    pip_install_with_venv(install_file, venv_dir, callback)
  end,
  ['pyproject.toml'] = function(install_file, venv_dir, callback)
    pip_install_with_venv(install_file, venv_dir, callback)
  end,
  ['poetry.lock'] = function(install_file, venv_dir, callback)
    poetry_sync(install_file, venv_dir, callback)
  end,
  ['pdm.lock'] = function(install_file, venv_dir, callback)
    pdm_sync(install_file, venv_dir, callback)
  end,
  ['uv.lock'] = function(install_file, venv_dir, callback)
    uv_sync(install_file, venv_dir, callback)
  end,
}

local check_paths_ordered_keys = {
  "uv.lock", "pdm.lock", "poetry.lock", "pyproject.toml", "dev-requirements.txt", "requirements.txt"
}

---
---@return table found_hatch_pythons list of python interpreters found by hatch
local function hatch_interpreters()
  if vim.fn.executable("hatch") == 1 then
    local hatch_python_paths = vim.fn.expand("~/.local/share/hatch/pythons")
    if vim.fn.isdirectory(hatch_python_paths) then
      local found_hatch_pythons = vim.fn.globpath(hatch_python_paths, vim.fs.joinpath("**", "bin", "python3.*"), false,
        true)
      if found_hatch_pythons then
        return found_hatch_pythons
      end
    end
  end
  return {}
end

---@return table<string> list of potential python interpreters to use
local function python_interpreters()
  -- TODO detect python interpreters from windows
  if IS_WINDOWS then
    return { "python3" }
  end
  -- TODO for macos we probably need to look in other places other than homebrew
  local pythons = vim.fn.globpath("/usr/bin/", 'python3.*', false, true)

  if IS_MACOS then
    local homebrew_path = vim.fn.globpath("/opt/homebrew/bin/", 'python3.*', false, true)
    for _, p in pairs(homebrew_path) do
      table.insert(pythons, 1, p)
    end
  end
  local found_hatch = hatch_interpreters()
  if found_hatch then
    for _, p in pairs(found_hatch) do
      table.insert(pythons, 1, p)
    end
  end
  local interpreters = nil
  for _, p in pairs(pythons) do
    if not interpreters then
      interpreters = {}
    end
    if string.match(vim.fs.basename(p), "python3.%d+$") then
      table.insert(interpreters, 1, p)
    end
  end
  if not interpreters then
    vim.notify_once("python.nvim: Warning could not detect python interpreters. Defaulting to python3",
      vim.log.levels.WARN)
    interpreters = { "python3" }
  end
  return interpreters
end

---Create the python venv with selected interpreter
---@param venv_path string path of venv to create
---@param python_interpreter string path to python executable to use
---@param callback function
local function create_venv_with_python(venv_path, python_interpreter, callback)
  vim.notify_once('python.nvim: creating venv at: ' .. venv_path, vim.log.levels.INFO)
  vim.system(
    { python_interpreter, '-m', 'venv', venv_path },
    {},
    function(obj)
      if obj.code ~= 0 then
        vim.notify_once('python.nvim: ' .. vim.inspect(obj.stderr .. obj.stdout), vim.log.levels.ERROR)
        return
      end
      callback()
    end)
end

local function set_venv_state()
  local detect = M.detect_venv(false, false)

  if detect == nil then
    vim.notify(
      "python.nvim: Could not find a python dependency file for this cwd",
      vim.log.levels.WARN)
    return
  end

  local new_parent_dir = detect[1]
  local detect_val = detect[2]

  local last_parent_dir = Auto_set_python_venv_parent_dir
  if last_parent_dir ~= new_parent_dir then
    Auto_set_python_venv_parent_dir = new_parent_dir
  end
  local key = new_parent_dir
  local install_function = check_paths[detect_val.install_method]
  local venv_path = detect_val.venv_path
  local install_file = detect_val.install_file

  -- TODO allow user to select if they want this to be path scoped or git repo scoped
  if detect_val.venv_path == nil or detect_val.python_interpreter == nil then
    local default_input = config.auto_create_venv_path(new_parent_dir)
    vim.schedule(function()
      vim.ui.input({ prompt = "Input new venv path: ", default = default_input }, function(venv_path_user_input)
        local wanted_dir = vim.fs.dirname(venv_path_user_input)
        if vim.fn.isdirectory(wanted_dir) == 0 then
          vim.notify_once(string.format("Error: directory of new venv doesn't exist: '%s'", venv_path_user_input),
            vim.log.levels.ERROR)
          return
        end
        vim.schedule(function()
          vim.ui.select(python_interpreters(), { prompt = 'Select a python interpreter: ' },
            function(python_interpreter_user_input)
              create_venv_with_python(venv_path_user_input, python_interpreter_user_input, function()
                install_function(install_file, venv_path_user_input, function()
                  local val = {
                    python_interpreter = python_interpreter_user_input,
                    venv_path = venv_path_user_input,
                    install_method = detect_val.install_method,
                    install_file = install_file,
                    source = "venv"
                  }
                  local python_state = state.State()

                  local venv_name = vim.fs.basename(vim.fs.dirname(install_file))
                  python_set_venv(val.venv_path, venv_name)
                  python_state.venvs[key] = val
                  state.save(python_state)
                end)
              end)
            end)
        end)
      end)
    end)
    return
  end
  if not install_function then
    vim.notify(
      ("python.nvim: Unable to find an install function for detected method: '%s'"):format(detect_val.install_method),
      vim.log.levels.ERROR)
    return
  end
  install_function(install_file, venv_path, function() end)
end

--- Automatically create venv directory and use multiple method to auto install dependencies
--- Use module level variable Auto_set_python_venv_parent_dir to keep track of the last venv dir, so
---   We don't do the creation process again when you are in the same project.
function M.create_and_install_venv()
  set_venv_state()
end

---Remove venv from state by key
---@param venv_key any
local function delete_venv_from_state(venv_key)
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
  local old_venv_path = python_state.venvs[venv_key].venv_path
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

local function delete_venv_from_selection()
  local python_state = state.State()

  local keys = {}
  for cwd, _ in pairs(python_state.venvs) do
    table.insert(keys, cwd)
  end

  vim.ui.select(keys, {
    prompt = "Delete venv project from state: "
  }, function(choice)
    delete_venv_from_state(choice)
  end)
end

---Delete a venv from state and filesystem
---@param select boolean
function M.delete_venv(select)
  if select then
    delete_venv_from_selection()
  else
    local python_state = state.State()
    local detect = M.detect_venv(false, true)
    if detect == nil or not python_state.venvs[detect[1]] then
      vim.notify("python.nvim: Current venv in not found in state. Cant continue", vim.log.levels.WARN)
      return
    end
    delete_venv_from_state(detect[1])
  end
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

---@return table<table<string>, PythonStateVEnv> | nil
---@param notify boolean Send notification when venv is not found
---@param cwd_allowed? boolean Allow use of cwd when detecting
function M.detect_venv(notify, cwd_allowed)
  local python_state = state.State()

  local found_parent_dir = nil
  local found_search_path = nil
  local found_key = nil
  local found_path = nil

  for _, search_path in pairs(check_paths_ordered_keys) do
    found_path = nil
    found_path = search_up(search_path)
    if found_path ~= nil then
      found_parent_dir = vim.fs.dirname(found_path)
      local key = found_parent_dir

      found_search_path = search_path
      found_key = key
      found_path = found_path

      if python_state.venvs[key] ~= nil then
        local venv_path = python_state.venvs[key].venv_path
        if vim.fn.isdirectory(venv_path) == 0 then
          delete_venv_from_state(key)
        else
          python_set_venv(venv_path, vim.fs.basename(found_parent_dir))
          return { key, python_state.venvs[key] }
        end
      end

      break
    end
  end
  if cwd_allowed then
    local cwd = vim.fn.getcwd()
    if not found_parent_dir then
      found_parent_dir = cwd
    end

    -- set venv if cwd is found in state before doing searches.
    if python_state.venvs[cwd] ~= nil and vim.fn.isdirectory(python_state.venvs[cwd].venv_path) ~= 0 then
      python_set_venv(
        python_state.venvs[cwd].venv_path,
        vim.fs.basename(python_state.venvs[cwd].venv_path),
        python_state.venvs[cwd].source
      )
      return { cwd, python_state.venvs[cwd] }
    end
  end
  -- We found a dependency file, but we aren't stored in State
  -- cwd check also failed, so we can continue.
  if found_search_path and found_key and found_path then
    return { found_key, {
      install_method = found_search_path,
      install_file = found_path,
      source = "venv",
      python_interpreter = nil,
      venv_path = nil,
    } }
  end
  if notify then
    vim.notify_once(
      string.format("python.nvim: venv not found for '%s' run :PythonVEnvInstall to create one ", found_parent_dir),
      vim.log.levels.WARN)
  end
  return nil
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.venv.create")[k]
  end,
})
