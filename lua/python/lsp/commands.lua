-- LSP user commands

local M = {}

--- Change the type checking mode of either basedpyright or pyright if found.
---@param mode string type checking mode
function M.pyright_change_type_checking(mode)
  local check_clients = { "pyright", "basedpyright" }

  for _, client_name in pairs(check_clients) do
    local clients = vim.lsp.get_clients({
      bufnr = vim.api.nvim_get_current_buf(),
      name = client_name,
    })
    for _, client in ipairs(clients) do
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
        basedpyright = {
          analysis = {
            typeCheckingMode = mode,
          },
        },
      })
      local msg = ("python.nvim: Set type check mode: %s on lsp: %s"):format(mode, client_name)
      vim.notify(msg)

      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.lsp.commands")[k]
  end,
})
