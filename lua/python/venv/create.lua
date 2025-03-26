local M = {}

local config = require('python.config')
local state = require("python.state")
local IS_WINDOWS = vim.uv.os_uname().sysname == 'Windows_NT'

--- Set venv. Only set venv if its different than current.
--- local venv_dir = settings.auto_create_venv_dir
---@param venv_path string full path to venv directory
---@param venv_name string name of the venv to set
local function python_set_venv(venv_path, venv_name)
  local lsp = require("python.lsp")
  if venv_path then
    local python_venv = require('python.venv')
    local current_venv_name = nil
    local current_venv = python_venv.current_venv()
    if current_venv then
      current_venv_name = current_venv.name
    end
    if vim.fs.basename(venv_path) ~= current_venv_name then
      python_venv.set_venv_path({ path = venv_path, name = venv_name, source = "venv" })
      vim.notify("python.nvim: set venv at: " .. venv_path)
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
  -- get parent directory via vim expand
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

--- Run pdm sync at lock file directory. Set env path when done.
---@param pdm_lock_path string full path to pdm lock file
---@param venv_dir string full path to pdm lock file
---@param callback function
local function pdm_sync(pdm_lock_path, venv_dir, callback)
  vim.notify('python.nvim: starting pdm sync at: ' .. pdm_lock_path, vim.log.levels.INFO)
  local dir_name = vim.fs.dirname(pdm_lock_path)
  vim.system(
    { 'pdm', 'use', '-f', venv_dir },
    {
      cwd = dir_name
    },
    function(obj1)
      if obj1.code ~= 0 then
        vim.notify('python.nvim: ' .. vim.inspect(obj1.stderr), vim.log.levels.ERROR)
        return
      end
      vim.system(
        { 'pdm', 'sync' },
        {
          cwd = dir_name
        },
        function(obj2)
          vim.schedule(
            function()
              if obj2.code ~= 0 then
                vim.notify('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
                return
              end
              callback()
            end
          )
        end
      )
    end
  )
end

--- Create venv with python venv module and pip install at location
---@param requirements_path string full path to requirements.txt, dev-requirements.txt or pyproject.toml
---@param venv_dir string
---@param callback function
local function pip_install_with_venv(requirements_path, venv_dir, callback)
  local dir_name = vim.fs.dirname(requirements_path)
  vim.notify(
    'python.nvim: starting pip install at: ' .. requirements_path .. ' in venv: ' .. venv_dir,
    vim.log.levels.INFO
  )
  vim.schedule(
    function()
      local pip_path = venv_dir .. '/' .. 'bin/pip'
      print(pip_path)
      local pip_cmd = { pip_path, 'install', '-r', requirements_path }

      if string.find(requirements_path, 'pyproject.toml$') then
        pip_cmd = { pip_path, 'install', '.' }
      end
      vim.system(
        pip_cmd,
        {
          cwd = dir_name,
        },
        function(obj2)
          vim.schedule(function()
            if obj2.code ~= 0 then
              vim.notify('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
            else
              callback()
            end
          end)
        end
      )
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
  ['pdm.lock'] = function(install_file, venv_dir, callback)
    pdm_sync(install_file, venv_dir, callback)
  end,
}

local check_paths_ordered_keys = {
  "pdm.lock", "pyproject.toml", "dev-requirements.txt", "requirements.txt"
}

---@return table<string> list of potential python interpreters to use
local function python_interpreters()
  -- TODO detect python interpreters from windows
  if IS_WINDOWS then
    return { "python3" }
  end
  local pythons = vim.fn.globpath("/usr/bin/", 'python3.*', false, true)
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
    vim.notify("python.nvim: Warning could not detect python interpreters. Defaulting to python3", vim.log.levels.WARN)
    interpreters = { "python3" }
  end
  return interpreters
end

---Create the python venv with selected interpreter
---@param venv_path string path of venv to create
---@param python_interpreter string path to python executable to use
---@param callback function
local function create_venv_with_python(venv_path, python_interpreter, callback)
  vim.notify('python.nvim: creating venv at: ' .. venv_path, vim.log.levels.INFO)
  vim.system(
    { python_interpreter, '-m', 'venv', venv_path },
    {},
    function(obj)
      if obj.code ~= 0 then
        vim.notify('python.nvim: ' .. vim.inspect(obj.stderr .. obj.stdout), vim.log.levels.ERROR)
        return
      end
      callback()
    end)
end

local function set_venv_state()
  local detect = M.detect_venv(false)

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
      vim.ui.input({ prompt = "Input new venv path", default = default_input }, function(venv_path_user_input)
        local wanted_dir = vim.fs.dirname(venv_path_user_input)
        if vim.fn.isdirectory(wanted_dir) == 0 then
          vim.notify(string.format("Error: directory of new venv doesn't exist: '%s'", venv_path_user_input),
            vim.log.levels.ERROR)
          return
        end
        vim.schedule(function()
          vim.ui.select(python_interpreters(), { prompt = 'Select a python interpreter' },
            function(python_interpreter_user_input)
              create_venv_with_python(venv_path_user_input, python_interpreter_user_input, function()
                install_function(install_file, venv_path_user_input, function()
                  local val = {
                    python_interpreter = python_interpreter_user_input,
                    venv_path = venv_path_user_input,
                    install_method = detect_val.install_method,
                    install_file = install_file
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
  local python_state = state.State()
  for k, v in ipairs(python_state.venvs) do
    if v == venv_key then
      table.remove(python_state.venvs, k)
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
    prompt = "Delete venv project from state"
  }, function(choice)
    python_state.venvs[choice] = nil
    state.save(python_state)
    vim.notify(string.format("python.nvim: Removed '%s' from state.", choice))
  end)
end

---Delete a venv from state and filesystem
---@param select boolean
function M.delete_venv(select)
  if select then
    delete_venv_from_selection()
  else
    delete_venv_from_state()
  end
end

--- Interactively set a venv in state.
--- This is used when users manually select a venv and want it cached for next run.
---@param venv_path string Path to venv to save for this cwd
function M.user_set_venv_in_state_confirmation(venv_path)
  local cwd = vim.fn.getcwd()
  local python_state = state.State()
  vim.ui.select({ "Yes", "No" }, {
    prompt = string.format("Save venv path for this cwd? '%s' -> '%s'", cwd, venv_path)
  }, function(choice)
    if choice == "Yes" then
      python_state.venvs[cwd] = {
        python_interpreter = "unknown",
        venv_path = venv_path,
        install_method = "unknown",
        install_file = "unknown"
      }
      state.save(python_state)
      vim.notify(string.format("python.nvim: Saved venv '%s' for cwd '%s'. Use :PythonVEnvDeleteSelect to remove it.",
        venv_path, cwd))
    end
  end)
end

---@return table<table<string>, PythonStateVEnv> | nil
---@param notify boolean
function M.detect_venv(notify)
  local python_state = state.State()

  local cwd = vim.fn.getcwd()

  -- set venv if cwd is found in state before doing searches.
  if python_state.venvs[cwd] ~= nil and vim.fn.isdirectory(python_state.venvs[cwd].venv_path) ~= 0 then
    python_set_venv(python_state.venvs[cwd].venv_path, vim.fs.basename(python_state.venvs[cwd].venv_path))
    return { cwd, python_state.venvs[cwd] }
  end

  for _, search_path in pairs(check_paths_ordered_keys) do
    local found_path = nil
    found_path = search_up(search_path)
    if found_path ~= nil then
      -- TODO allow user to select if they want this to be path scoped or git repo scoped
      local parent_dir = vim.fs.dirname(found_path)
      local key = parent_dir

      if python_state.venvs[key] ~= nil then
        local venv_path = python_state.venvs[key].venv_path
        if vim.fn.isdirectory(venv_path) == 0 then
          delete_venv_from_state(key)
        else
          python_set_venv(venv_path, vim.fs.basename(parent_dir))
          return { key, python_state.venvs[key] }
        end
      end
      if notify then
        vim.notify(
          string.format("python.nvim: venv not found for '%s' run :PythonVEnvInstall to create one ", parent_dir),
          vim.log.levels.WARN)
      end
      return { key, {
        install_method = search_path,
        install_file = found_path,
        python_interpreter = nil,
        venv_path = nil,
      } }
    end
  end
  return nil
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.venv.create")[k]
  end,
})
