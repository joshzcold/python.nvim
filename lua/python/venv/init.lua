---@class VEnv
---@field source string
---@field path string
---@field name string

local PythonVENV = {}

local current_venv = nil

local IS_WINDOWS = vim.uv.os_uname().sysname == "Windows_NT"
local ORIGINAL_PATH = vim.fn.getenv("PATH")

local update_PATH = function(path)
  local sep
  local dir
  if IS_WINDOWS then
    sep = ";"
    dir = "Scripts"
  else
    sep = ":"
    dir = "bin"
  end
  vim.fn.setenv("PATH", vim.fs.joinpath(path, dir .. sep .. ORIGINAL_PATH))
end

---Set active VEnv, updating venv and PATH variables.
---@param venv VEnv | nil
function PythonVENV.set_venv_path(venv)
  if venv == nil then
    current_venv = venv
    return
  end
  local config = require("python.config")
  if venv.source == "conda" or venv.source == "micromamba" then
    vim.fn.setenv("CONDA_PREFIX", venv.path)
    vim.fn.setenv("CONDA_DEFAULT_ENV", venv.name)
    vim.fn.setenv("CONDA_PROMPT_MODIFIER", "(" .. venv.name .. ")")
    venv.name = ("(conda) %s"):format(venv.name)
  else
    vim.fn.setenv("VIRTUAL_ENV", venv.path)
  end
  current_venv = venv
  -- TODO: remove old path
  update_PATH(venv.path)
  if config.post_set_venv then
    config.post_set_venv(venv)
  end
end

---Get the currently set VEnv object from plugin memory
---@return VEnv | nil
function PythonVENV.current_venv()
  return current_venv
end

---@return VEnv[]
local get_venvs_for = function(base_path, source, opts)
  local options = { only_dirs = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end

  local venvs = {}
  if base_path == nil then
    return venvs
  end
  for name, type in vim.fs.dir(base_path, { depth = 1 }) do
    if type == "directory" or not options.only_dirs then
      table.insert(venvs, {
        name = name,
        path = vim.fs.joinpath(base_path, name),
        source = source,
      })
    end
  end
  return venvs
end

local get_pixi_base_path = function()
  local current_dir = vim.fn.getcwd()
  local pixi_root = vim.fs.joinpath(current_dir, ".pixi")

  if vim.fn.filereadable(pixi_root) == 0 then
    return nil
  else
    return vim.fs.joinpath(pixi_root, "envs")
  end
end

local get_conda_base_path = function()
  local conda_exe = vim.fn.getenv("CONDA_EXE")
  if conda_exe == vim.NIL then
    return nil
  else
    return vim.fs.joinpath(vim.fs.dirname(vim.fs.dirname(conda_exe)), "envs")
  end
end

local get_conda_base_env = function()
  local venvs = {}
  local path = os.getenv("CONDA_EXE")
  if path then
    table.insert(venvs, {
      name = "base",
      path = vim.fn.fnamemodify(path, ":p:h:h"),
      source = "conda",
    })
  end
  return venvs
end

local get_micromamba_base_path = function()
  local micromamba_root_prefix = vim.fn.getenv("MAMBA_ROOT_PREFIX")
  if micromamba_root_prefix == vim.NIL then
    return nil
  else
    return vim.fs.joinpath(micromamba_root_prefix, "envs")
  end
end

local get_pyenv_base_path = function()
  local pyenv_root = vim.fn.getenv("PYENV_ROOT")
  if pyenv_root == vim.NIL then
    return nil
  else
    return vim.fs.joinpath(pyenv_root, "versions")
  end
end

---Get a list of venvs from multiple supported sources.
---@return table<VEnv> List of venvs found from multiple lists
PythonVENV.get_venvs = function(venvs_path)
  local venvs = {}
  vim.list_extend(venvs, get_venvs_for(venvs_path, "venv"))
  vim.list_extend(venvs, get_venvs_for(get_pixi_base_path(), "pixi"))
  vim.list_extend(venvs, get_venvs_for(get_conda_base_path(), "conda"))
  vim.list_extend(venvs, get_conda_base_env())
  vim.list_extend(venvs, get_venvs_for(get_micromamba_base_path(), "micromamba"))
  vim.list_extend(venvs, get_venvs_for(get_pyenv_base_path(), "pyenv"))
  vim.list_extend(venvs, get_venvs_for(get_pyenv_base_path(), "pyenv", { only_dirs = false }))
  return venvs
end

---Checks who appears first in PATH. Returns `true` if `first` appears first and `false` otherwise
---@param first string|nil
---@param second string|nil
---@return boolean
local has_high_priority_in_path = function(first, second)
  if first == nil or first == vim.NIL then
    return false
  end

  if second == nil or second == vim.NIL then
    return true
  end

  local find_first = string.find(ORIGINAL_PATH, first)
  local find_second = string.find(ORIGINAL_PATH, second)
  if find_first and find_second then
    return find_first < find_second
  end
  return false
end

---Load in a venv that is already set in env vars.
PythonVENV.load_existing_venv = function()
  local venv

  local venv_env = vim.fn.getenv("VIRTUAL_ENV")
  if venv_env ~= vim.NIL then
    venv = {
      name = vim.fs.basename(venv_env),
      path = venv_env,
      source = "venv",
    }
  end

  local conda_env = vim.fn.getenv("CONDA_DEFAULT_ENV")
  if conda_env ~= vim.NIL and has_high_priority_in_path(conda_env, venv_env) then
    venv = {
      name = ("(conda) %s"):format(conda_env),
      path = vim.fn.getenv("CONDA_PREFIX"),
      source = "conda",
    }
  end

  if venv then
    current_venv = venv
  end
end

---Interactively pick a venv to set as active.
PythonVENV.pick_venv = function()
  local config = require("python.config")
  local create = require("python.venv.create")
  vim.schedule(function()
    local items = config.get_venvs(config.venvs_path)
    vim.ui.select(items, {
      prompt = "Select python venv: ",
      format_item = function(item)
        return string.format("%s (%s) [%s]", item.name, item.path, item.source)
      end,
    }, function(choice)
      if not choice then
        return
      end
      PythonVENV.set_venv_path(choice)
      create.user_set_venv_in_state_confirmation(choice)
    end)
  end)
end

return PythonVENV
