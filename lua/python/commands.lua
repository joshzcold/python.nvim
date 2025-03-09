-- python.nvim commands
local M = {}

function M.load_commands()
  local lsp = require("python.lsp")
  local create = require("python.venv.create")
  vim.api.nvim_create_user_command("PythonVEnvInstall", function()
    create.create_and_install_venv()
  end, {})
  vim.api.nvim_create_user_command("PythonVEnvReloadLSPs", function()
    lsp.notify_workspace_did_change()
  end, {})
  vim.api.nvim_create_user_command("PythonVEnvDelete", function()
    create.delete_venv(false)
  end, {})
  vim.api.nvim_create_user_command("PythonVEnvDeleteSelect", function()
    create.delete_venv(true)
  end, {})
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.commands")[k]
  end,
})
