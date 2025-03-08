-- LSP user commands

M = {}

local function based_pyright_commands()
  vim.api.nvim_create_user_command("PythonBasedPyRightChangeTypeCheckingMode", function(opts)
    local clients = vim.lsp.get_clients({
      bufnr = vim.api.nvim_get_current_buf(),
      name = "basedpyright",
    })
    for _, client in ipairs(clients) do
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
        basedpyright = {
          analysis = {
            typeCheckingMode = opts.args,
          },
        },
      })
      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
  end, {
    nargs = 1,
    count = 1,
    complete = function()
      return { "off", "basic", "standard", "strict", "all" }
    end,
  })
end

--- Load specific commands if lsp servers are found
function M.load_lsp_server_commands()
  local clients = vim.lsp.get_clients()
  if not clients then
    return
  end
  ---@class vim.lsp.Client
  for _, client in pairs(clients) do
    if client.name == "basedpyright" then
      based_pyright_commands()
    end
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.lsp.commands")[k]
  end,
})
