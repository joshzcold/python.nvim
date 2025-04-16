local M = {}


local function check_hatch()
  if vim.fn.executable("hatch") == 0 then
    vim.notify_once(("python.nvim: Program 'hatch' is required: %s"):format("https://hatch.pypa.io/latest/"),
      vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Get list of python versions hatch has installed
---@return table list of available python versions from hatch
local function hatch_installed_versions()
  local output = {}
  vim.system({ "hatch", "python", "show", "--ascii" }, {}, function(obj)
    local found_installed = {}
    for line in vim.gsplit(obj.stdout, "\n", { plain = true }) do
      local available_line = string.match(line, "Available")
      if available_line then
        break
      end
      local matched = string.match(line, "(%d%.%d+%s*|%s*%d.%d+)")
      table.insert(found_installed, 1, matched)
    end


    for _, f in pairs(found_installed) do
      local parts = vim.split(f, "|", { trimempty = true })
      parts[1] = parts[1]:gsub("%s+", "")
      table.insert(output, 1, parts[1])
    end
  end):wait()
  return output
end

--- Get list of python versions hatch can install
---@return table list of available python versions from hatch
local function hatch_available_versions()
  local output = {}
  vim.system({ "hatch", "python", "show", "--ascii" }, {}, function(obj)
    local found_available = {}
    local available_line_shown = false
    for line in vim.gsplit(obj.stdout, "\n", { plain = true }) do
      local available_line = string.match(line, "Available")
      if available_line then
        available_line_shown = true
      end

      if available_line_shown then
        local matched = string.match(line, "(%d%.%d+%s*|%s*%d.%d+)")
        table.insert(found_available, 1, matched)
      end
    end


    for _, f in pairs(found_available) do
      local parts = vim.split(f, "|", { trimempty = true })
      parts[1] = parts[1]:gsub("%s+", "")
      table.insert(output, 1, parts[1])
    end
  end):wait()
  return output
end


--- Install a python version using hatch
---@param version string Python version to install via hatch
local function hatch_install_version(version)
  print("TODO install hatch version")
end


function M.load_commands()
  vim.api.nvim_create_user_command("PythonHatchInstallPython", function()
    if not check_hatch() then
      return
    end
    local versions = hatch_available_versions()
    vim.ui.select(versions, { prompt = "Select a python version to install via hatch: " }, function(selection)
      if not selection then
        return
      end
      hatch_install_version(selection)
    end)
  end, {})
  vim.api.nvim_create_user_command("PythonHatchListPython", function()
    if not check_hatch() then
      return
    end
    local versions = hatch_installed_versions()
    vim.print(versions)
  end, {})
  vim.api.nvim_create_user_command("PythonHatchDeletePython", function()
    if not check_hatch() then
      return
    end
  end, {})
  vim.api.nvim_create_user_command("PythonHatchDeletePython", function()
    if not check_hatch() then
      return
    end
  end, {})
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.hatch.commands")[k]
  end,
})
