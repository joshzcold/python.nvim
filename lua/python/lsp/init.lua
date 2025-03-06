local M = {}

local function call_did_change_configuration(client, config)
  client.settings = config
  if client.notify("workspace/didChangeConfiguration", { settings = client.settings }) then
    vim.notify(string.format("python.nvim: Updated configuration of lsp server: '%s'", client.name),
      vim.log.levels.INFO)
  else
    vim.notify(string.format("python.nvim: Updating configuration of lsp server: '%s' has failed", client.name),
      vim.log.levels.ERROR)
  end
end

M.python_lsp_servers = {
  basedpyright = {
    callback = function(venv_path, client)
      local new_settings = vim.tbl_deep_extend("force", client.settings, {
        python = {
          pythonPath = venv_path
        }
      })
      call_did_change_configuration(client, new_settings)
    end
  },
  pyright = {
    callback = function(venv_path, client)
      local new_settings = vim.tbl_deep_extend("force", client.settings, {
        python = {
          pythonPath = venv_path
        }
      })
      call_did_change_configuration(client, new_settings)
    end
  },
  pylsp = {
    -- python-lsp-server does not have a specific setting for python path
    callback = function(_, client)
      vim.cmd(":LspRestart pylsp")
      vim.notify(string.format("python.nvim: restart lsp client: '%s'", client.name),
        vim.log.levels.INFO)
    end
  },
  jedi_language_server = {
    -- jedi_language_server doesn't support didChangeConfiguration
    -- https://github.com/pappasam/jedi-language-server/issues/58
    callback = function(_, client)
      vim.notify(string.format("python.nvim: restart lsp client: '%s'", client.name),
        vim.log.levels.INFO)
      vim.cmd(":LspRestart jedi_language_server")
    end
  },
  -- For my homies in devops
  ansiblels = {
    callback = function(_, client)
      vim.notify(string.format("python.nvim: restart lsp client: '%s'", client.name),
        vim.log.levels.INFO)
      vim.cmd(":LspRestart ansiblels")
    end
  }
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
