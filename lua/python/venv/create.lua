local M = {}

local config = require('python.config')
local venv_dir = config.auto_create_venv_dir

--- Set venv. Only set venv if its different than current.
--- local venv_dir = settings.auto_create_venv_dir
---@param venv_path string full path to venv directory
---@param venv_name string name of the venv to set
local function python_set_venv(venv_path, venv_name)
  if venv_path then
    local python_venv = require('python.venv')
    local current_venv_name = nil
    local current_venv = python_venv.current_venv()
    if current_venv then
      current_venv_name = current_venv.name
    end
    if venv_path ~= current_venv_name then
      python_venv.set_venv_path({ path = venv_path, name = venv_name, source = "venv" })
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
local function pdm_sync(pdm_lock_path)
  vim.notify('python.nvim: starting pdm sync at: ' .. pdm_lock_path, vim.log.levels.INFO)
  local dir_name = vim.fs.dirname(pdm_lock_path)
  vim.system(
    { 'pdm', 'sync' },
    {
      cwd = dir_name,
      on_exit = function(obj)
        vim.schedule(function()
          if obj.code ~= 0 then
            vim.notify('python.nvim: ' .. vim.inspect(obj.stderr), vim.log.levels.ERROR)
          else
            local venv_path = dir_name .. '/' .. venv_dir
            local venv_name = vim.fs.basename(dir_name)
            python_set_venv(venv_path, venv_name)
            vim.notify('python.nvim: set venv: ' .. venv_path, vim.log.levels.INFO)
          end
        end)
      end
    }
  )
end

--- Create venv with python venv module and pip install at location
---@param requirements_path string full path to requirements.txt, dev-requirements.txt or pyproject.toml
local function pip_install_with_venv(requirements_path)
  local dir_name = vim.fs.dirname(requirements_path)
  local venv_path = dir_name .. '/' .. venv_dir
  vim.notify(
    'python.nvim: starting pip install at: ' .. requirements_path .. ' in venv: ' .. venv_path,
    vim.log.levels.INFO
  )
  local python_app = 'python3'
  if vim.fn.executable(python_app) ~= 1 then
    python_app = 'python'
  end
  vim.system(
    { python_app, '-m', 'venv', venv_path },
    {
    cwd = dir_name,
    on_exit = function(obj)
      vim.schedule(function()
        if obj.code ~= 0 then
          vim.notify('python.nvim: ' .. vim.inspect(obj.stderr .. obj.stdout), vim.log.levels.ERROR)
        else
          local pip_path = venv_path .. '/' .. 'bin/pip'
          local install_args = { 'install', '-r', requirements_path }
          if string.find(requirements_path, 'pyproject.toml$') then
            install_args = { 'install', '.' }
          end

          local pip_install_cmd = table.insert{install_args, 1, pip_path}
          vim.system(
              pip_install_cmd,
              {cwd = dir_name,
                on_exit = function(obj2)
                  vim.schedule(function()
                    if obj2.code ~= 0 then
                      vim.notify('python.nvim: ' .. vim.inspect(obj2.stderr), vim.log.levels.ERROR)
                    else
                      local venv_name = vim.fs.basename(dir_name)
                      python_set_venv(venv_path, venv_name)
                      vim.notify('Set venv: ' .. venv_path, vim.log.levels.INFO)
                    end
                  end)
                end
              }
            )
        end
      end)
    end,
    }
  )
end

--- Automatically create venv directory and use multiple method to auto install dependencies
--- Use module level variable Auto_set_python_venv_parent_dir to keep track of the last venv dir, so
---   We don't do the creation process again when you are in the same project.
M.auto_create_set_python_venv = function()
  local stop = false
  local check_paths = {
    {
      path = venv_dir,
      callback = function(path)
        -- initial set, still want to do dependency install from others if available
        local venv_name = vim.fs.basename(vim.fs.dirname(path))
        python_set_venv(path, venv_name)
      end,
    },
    {
      path = 'pdm.lock',
      callback = function(path)
        pdm_sync(path)
        Auto_set_python_venv_parent_dir = vim.fs.dirname(path)
        stop = true
      end,
    },
    {
      path = 'requirements.txt',
      callback = function(path)
        pip_install_with_venv(path)
        Auto_set_python_venv_parent_dir = vim.fs.dirname(path)
        stop = true
      end,
    },
    {
      path = 'dev-requirements.txt',
      callback = function(path)
        pip_install_with_venv(path)
        Auto_set_python_venv_parent_dir = vim.fs.dirname(path)
        stop = true
      end,
    },
    {
      path = 'pyproject.toml',
      callback = function(path)
        pip_install_with_venv(path)
        Auto_set_python_venv_parent_dir = vim.fs.dirname(path)
        stop = true
      end,
    },
  }

  for _, val in ipairs(check_paths) do
    local found_path = nil
    local search_path = val.path
    local callback = val.callback
    if stop then
      return
    end
    found_path = search_up(search_path)
    if found_path ~= nil then
      local last_parent_dir = Auto_set_python_venv_parent_dir
      local new_parent_dir = vim.fs.dirname(found_path)
      if last_parent_dir ~= new_parent_dir then
        callback(found_path)
      end
    end
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.venv.create")[k]
  end,
})
