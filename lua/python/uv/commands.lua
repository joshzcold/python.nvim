local ui = require("python.ui")
local M = {}


local function check_uv()
  if vim.fn.executable("uv") == 0 then
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

--- Execute uv directly with arguments passed by user.
---@param opts vim.api.keyset.create_user_command.command_args
local function uv(opts)
  local args = {}

  for _, fa in pairs(opts.fargs) do
    if fa == "%" then
      table.insert(args, vim.fn.expand("%"))
      goto continue
    end
    table.insert(args, fa)
    ::continue::
  end
  local cmd = { 'uv', unpack(args) }
  vim.schedule(function()
    vim.system(
      cmd,
      {
        cwd = vim.fn.getcwd(),
        stdout = ui.show_system_call_progress,
        stderr = ui.show_system_call_progress,
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
          end
        )
      end
    )
    ui.activate_system_call_ui()
  end)
end

local function uv_completion(arglead, cmdlin, cursorpos)
  local args = vim.split(cmdlin, " ")
  local cmd = { 'uv' }

  for _, arg in pairs(args) do
    if arg == "UV" or arg == "" then
      goto continue
    end

    if string.find(arg, "^%-") then
      goto continue
    end

    table.insert(cmd, arg)
    ::continue::
  end
  table.insert(cmd, "--help")

  local obj = vim.system(cmd, { text = true }):wait()

  local result = {}

  local function do_insert_match(match)
    if arglead ~= "" then
      if string.find(match, arglead, 0, true) then
        table.insert(result, match)
      end
      goto continue
    end
    table.insert(result, match)
    ::continue::
  end

  local patterns = {
    "(%-%-%w+[%w-]*)",   -- Matching '--argmument' in the output
    "(%-%w),",           -- Matching '-f' flag in the output
    "\n%s%s([a-z-]+)%s", -- Matching '  subcommand' flag in the output
  }

  for _, pattern in pairs(patterns) do
    for match in string.gmatch(obj.stdout, pattern) do
      do_insert_match(match)
    end
  end

  return result
end

function M.load_commands()
  if not check_uv() then
    return
  end
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
    local versions = uv_installed_versions()
    vim.ui.select(versions, { prompt = "Select a python version to delete via uv: " }, function(selection)
      if not selection then
        return
      end
      uv_delete_version(selection)
    end)
  end, { desc = "python.nvim: install a python version using uv." })

  vim.api.nvim_create_user_command("UV", function(opts)
    uv(opts)
  end, {
    desc = "python.nvim: pass-through uv commands.",
    complete = uv_completion,
    nargs = "*"
  })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.uv")[k]
  end,
})
