---@class python
local M = {}

---@param opts? python.Config
function M.setup(opts)
  require("python.config").setup(opts)

  local id = vim.api.nvim_create_augroup("python_nvim_autocmd_group", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python" },
    group = id,
    callback = function()
      local create = require("python.venv.create")
      create.detect_venv(true)

      vim.api.nvim_create_user_command("PythonVEnvInstall", function()
        create.create_and_install_venv()
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
