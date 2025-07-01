local ui = require("python.ui")
local M = {}


local function check_uv()
  if vim.fn.executable("uv") == 0 then
    vim.notify_once(("python.nvim: Program 'uv' is required: %s"):format("https://docs.astral.sh/uv/"),
      vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Get list of python versions uv can install
---@return table list of available python versions from uv
local function uv_available_versions()
  local output = {}
  vim.system({ "uv", "python", "list", "--only-downloads", "--output-format", "json" }, {}, function(obj)
    local found_available = {}
    local available_line_shown = false
    local python_json = vim.json.decode(obj.stdout)
    for _, pobj in pairs(python_json) do
      table.insert(output, 1, pobj['key'])
    end
  end):wait()
  return output
end

--- Get list of python versions uv has already installed
---@return table list of available python versions from uv
local function uv_installed_versions()
  local output = {}
  vim.system({ "uv", "python", "list", "--only-installed", "--output-format", "json" }, {}, function(obj)
    local found_available = {}
    local available_line_shown = false
    local python_json = vim.json.decode(obj.stdout)
    for _, pobj in pairs(python_json) do
      if string.find(pobj['path'], "uv") then
        table.insert(output, 1, pobj['key'])
      end
    end
  end):wait()
  return output
end

--- Install a python version using uv
---@param version string Python version to install via uv
local function uv_install_version(version)
  vim.schedule(
    function()
      vim.system(
        { "uv", "python", "install", version },
        {
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

--- Delete a python version using uv
---@param version string Python version to install via uv
local function uv_delete_version(version)
  vim.schedule(
    function()
      vim.system(
        { "uv", "python", "uninstall", version },
        {
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

function M.load_commands()
  vim.api.nvim_create_user_command("PythonUVInstallPython", function()
    if not check_uv() then
      return
    end
    local versions = uv_available_versions()
    vim.ui.select(versions, { prompt = "Select a python version to install via uv: " }, function(selection)
      if not selection then
        return
      end
      uv_install_version(selection)
    end)
  end, { desc = "python.nvim: install a python version using uv." })

  vim.api.nvim_create_user_command("PythonUVDeletePython", function()
    if not check_uv() then
      return
    end
    local versions = uv_installed_versions()
    vim.ui.select(versions, { prompt = "Select a python version to delete via uv: " }, function(selection)
      if not selection then
        return
      end
      uv_delete_version(selection)
    end)
  end, { desc = "python.nvim: install a python version using uv." })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.uv")[k]
  end,
})
