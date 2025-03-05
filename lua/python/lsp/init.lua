local M = {}


M.python_lsp_servers = {
  basedpyright = {
    python_path = function(venv_path)
      return {
        python = {
          pythonPath = venv_path
        }
      }
    end
  },
  pyright = {
    python_path = function(venv_path)
      return {
        python = {
          pythonPath = venv_path
        }
      }
    end
  },
  pylsp = {
    python_path = function(venv_path)
      return {
        python = {
          pythonPath = venv_path
        }
      }
    end
  }, -- TODO set specific settings path
  ["jedi-language-server"] = {
    python_path = function(venv_path)
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
    local config_block = M.python_lsp_servers[client.name].python_path(venv_python)
    local new_settings = vim.tbl_deep_extend("force", client.config.settings, config_block)
    client.config.settings = new_settings
    if client.notify("workspace/didChangeConfiguration", { settings = client.config.settings }) then
      vim.notify(string.format("python.nvim: Updated configuration of lsp server: '%s'", client.name),
        vim.log.levels.INFO)
    else
      vim.notify(string.format("python.nvim: Updating configuration of lsp server: '%s' has failed", client.name),
        vim.log.levels.ERROR)
    end
    ::continue::
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.lsp")[k]
  end,
})
