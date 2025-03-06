---@class python
local M = {}

---@param opts? python.Config
function M.setup(opts)
  local config = require("python.config")
  config.setup(opts)

  local id = vim.api.nvim_create_augroup("python_nvim_autocmd_group", { clear = true })

  -- Auto load venv on lsp server attach
  vim.api.nvim_create_autocmd({ "LspAttach" }, {
    pattern = config.auto_venv_lsp_attach_patterns,
    group = id,
    callback = function(args)
      local create = require("python.venv.create")
      local lsp = require("python.lsp")

      if not args.data.client_id then
        return
      end

      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client == nil then
        return
      end

      create.detect_venv(true)
    end,
  })

  -- Load up commands for users
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "python" },
    group = id,
    callback = function()
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
    end,
  })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.commands")[k]
  end,
})
