local M = {}


M.python_lsp_servers = {
  basedpyright = {
    callback = function(venv_path, client)
      local new_settings = vim.tbl_deep_extend("force", client.settings, {
        python = {
          pythonPath = venv_path
        }
      })
      client.settings = new_settings
      if client.notify("workspace/didChangeConfiguration", { settings = client.settings }) then
        vim.notify(string.format("python.nvim: Updated configuration of lsp server: '%s'", client.name),
          vim.log.levels.INFO)
      else
        vim.notify(string.format("python.nvim: Updating configuration of lsp server: '%s' has failed", client.name),
          vim.log.levels.ERROR)
      end
    end
  },
  pyright = {
    callback = function(venv_path, client)
      M.python_lsp_servers['basedpyright'].callback(venv_path, client)
    end
  },
  pylsp = {
    callback = function(_, _)
      vim.cmd(":LspRestart pylsp")
    end
  }, -- TODO set specific settings path
  ["jedi-language-server"] = {
    callback = function(venv_path, client)
      return {
        python = {
          pythonPath = venv_path
        }
      }
    end
  }, -- TODO set specific settings path
}

function M.notify_workspace_did_change()
  local clients = vim.lsp.get_clients()
  local venv = require("python.venv").current_venv()
  if not clients or not venv then
    return
  end

  local venv_python = venv.path .. "/bin/python"

  ---@class vim.lsp.Client
  for _, client in pairs(clients) do
    if M.python_lsp_servers[client.name] == nil then
      goto continue
    end
    M.python_lsp_servers[client.name].callback(venv_python, client)
    ::continue::
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.lsp")[k]
  end,
})
