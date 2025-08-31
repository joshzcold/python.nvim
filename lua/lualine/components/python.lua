local M = require("lualine.component"):extend()

local default_opts = {
  icon = "",
  color = { fg = "#FFD43B" },
}

function M:init(options)
  options = vim.tbl_deep_extend("keep", options or {}, default_opts)
  M.super.init(self, options)
end

function M:update_status()
  local venv_path = vim.fn.getenv("VIRTUAL_ENV")
  local conda_env = vim.fn.getenv("CONDA_DEFAULT_ENV")

  if venv_path ~= vim.NIL then
    if vim.fs.basename(venv_path) == ".venv" then
      return vim.fs.basename(vim.fs.dirname(venv_path))
    end
    return vim.fs.basename(venv_path)
  elseif conda_env ~= nil then
    return conda_env
  else
    return "no venv"
  end
end

return M
