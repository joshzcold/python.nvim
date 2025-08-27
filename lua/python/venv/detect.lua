local state = require("python.state")
local create = require("python.venv.create")

local PythonVENVDetect = {}
local IS_WINDOWS = vim.uv.os_uname().sysname == "Windows_NT"

---@class DetectVEnv
---@field dir string Current working directory found containing venv
---@field venv PythonStateVEnv information on the detected venv
DetectVEnv = {}

function DetectVEnv:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Check if this directory is found in stats
function DetectVEnv:found_in_state(key)
  local python_state = state.State()
  if key and python_state.venvs[key] ~= nil then
    local venv_path = python_state.venvs[key].venv_path
    if venv_path and vim.fn.isdirectory(venv_path) == 0 then
      create.delete_venv_from_state(key, false)
    else
      create.python_set_venv(venv_path, vim.fs.basename(key))
      self.dir = key
      self.venv = python_state.venvs[key]
      return true
    end
  end
  return false
end

--- Check if cwd is current in state
function DetectVEnv:found_in_cwd()
  local python_state = state.State()
  local cwd = vim.fn.getcwd()

  -- set venv if cwd is found in state before doing searches.
  if python_state.venvs[cwd] ~= nil and vim.fn.isdirectory(python_state.venvs[cwd].venv_path) ~= 0 then
    local venv_name = vim.fs.basename(python_state.venvs[cwd].venv_path)
    if not venv_name then
      return false
    end
    create.python_set_venv(python_state.venvs[cwd].venv_path, venv_name, python_state.venvs[cwd].source)
    self.dir = cwd
    self.venv = python_state.venvs[cwd]
    return true
  end
  return false
end

PythonVENVDetect.check_paths = {
  ["requirements.txt"] = {
    func = function(install_file, venv_dir, callback)
      create.pip_install_with_venv(install_file, venv_dir, callback)
    end,
    type = "file",
    desc = "Installing dependencies via requirements.txt and pip",
  },
  ["dev-requirements.txt"] = {
    func = function(install_file, venv_dir, callback)
      create.pip_install_with_venv(install_file, venv_dir, callback)
    end,
    type = "file",
    desc = "Installing dependencies via dev-requirements.txt and pip",
  },
  ["pyproject.toml"] = {
    func = function(install_file, venv_dir, callback)
      create.pip_install_with_venv(install_file, venv_dir, callback)
    end,
    type = "file",
    desc = "Installing dependencies via pyproject.toml and pip",
  },
  ["poetry.lock"] = {
    func = function(install_file, venv_dir, callback)
      create.poetry_sync(install_file, venv_dir, callback)
    end,
    type = "file",
    desc = "Installing dependencies via poetry.lock and poetry",
  },
  ["pdm.lock"] = {
    func = function(install_file, venv_dir, callback)
      create.pdm_sync(install_file, venv_dir, callback)
    end,
    type = "file",
    desc = "Installing dependencies via pdm.lock and pdm",
  },
  ["uv.lock"] = {
    func = function(install_file, venv_dir, callback)
      create.uv_sync(install_file, venv_dir, callback, false)
    end,
    type = "file",
    desc = "Installing dependencies via uv.lock and uv",
  },
  ["/// script"] = {
    func = function(install_file, venv_dir, callback)
      create.uv_sync(install_file, venv_dir, callback, true)
    end,
    type = "pattern",
    desc = "Installing dependencies via uv /// script block and uv --script",
  },
}

PythonVENVDetect.check_paths_ordered_keys = {
  "uv.lock",
  "/// script",
  "pdm.lock",
  "poetry.lock",
  "pyproject.toml",
  "dev-requirements.txt",
  "requirements.txt",
}

--- Search for file or directory until we either the top of the git repo or root
---@param dir_or_file string name of directory or file
---@return string | nil found either nil or full path of found file/directory
function PythonVENVDetect.search_up(dir_or_file)
  local found = nil
  local dir_to_check = nil
  -- get parent directory of current file in buffer via vim expand
  local dir_template = "%:p:h"
  -- TODO replace this with neovim built-in vim.fs.find
  while not found and (dir_to_check ~= "/" and dir_to_check ~= "C:\\" and dir_to_check ~= "D:\\") do
    dir_to_check = vim.fn.expand(dir_template)
    local check_path = vim.fs.joinpath(dir_to_check, dir_or_file)
    local check_git = vim.fs.joinpath(dir_to_check, ".git")
    if vim.fn.isdirectory(check_path) == 1 or vim.fn.filereadable(check_path) == 1 then
      found = vim.fs.joinpath(dir_to_check, dir_or_file)
    else
      dir_template = dir_template .. ":h"
    end
    -- If we hit a .git directory then stop searching and return found even if nil
    if vim.fn.isdirectory(check_git) == 1 then
      return found
    end
  end
  return found
end

--- Go through the list of possible dependency sources and return the first match.
--- check_paths_ordered_keys is an opinionated list of dependency sources that match
--- what the community probably wants detected first.
---@return string | nil found
---@return string | nil search
function PythonVENVDetect.search_for_detected_type()
  for _, search in pairs(PythonVENVDetect.check_paths_ordered_keys) do
    local check_type = PythonVENVDetect.check_paths[search].type

    if check_type == "file" then
      local found = PythonVENVDetect.search_up(search)
      if found ~= nil then
        return found, search
      end
    end

    if check_type == "pattern" then
      if vim.fn.search(search) ~= 0 then
        local found = vim.api.nvim_buf_get_name(0)
        -- Go through join path to get / slashes to be consistent in windows like
        -- we get with M.search_up
        if IS_WINDOWS then
          found = vim.fs.joinpath(vim.fs.dirname(found), vim.fs.basename(found))
        end
        return found, search
      end
    end
  end
  return nil, nil
end

---@return DetectVEnv | nil
---@param notify boolean Send notification when venv is not found
---@param cwd_allowed? boolean Allow use of cwd when detecting
function PythonVENVDetect.detect_venv_dependency_file(notify, cwd_allowed)
  local found, found_search_path = PythonVENVDetect.search_for_detected_type()

  local found_parent_dir = vim.fs.dirname(found)

  ---@type DetectVEnv
  local detect = DetectVEnv:new()

  -- What we detected is currently saved in state so we can use it
  if detect:found_in_state(found_parent_dir) then
    return detect
  end

  -- Did not detect something in state, Lets check if the user's cwd is in state and use that
  if cwd_allowed and detect:found_in_cwd() then
    return detect
  end

  -- We found a dependency file, but we aren't stored in State
  -- cwd check also failed, so we can continue with creating a brand new venv.
  if found_search_path and found_parent_dir and found then
    detect.dir = found_parent_dir
    detect.venv = {
      install_method = found_search_path,
      install_file = found,
      source = "venv",
      python_interpreter = nil,
      venv_path = nil,
    }
    if notify then
      vim.notify_once(
        string.format("python.nvim: venv not found for '%s' run :PythonVEnvInstall to create one ", found_parent_dir),
        vim.log.levels.WARN
      )
    end
    return detect
  end

  -- Nothing found
  return nil
end

return PythonVENVDetect
