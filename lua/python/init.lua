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
      local lsp = require("python.lsp.commands")

      if not args.data.client_id then
        return
      end

      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client == nil then
        return
      end

      lsp.load_commands()
      -- TODO: should I put this in an autocmd that only runs once instead of for
      -- each lsp server?
      create.detect_venv(true)
    end,
  })

  -- Load up commands for users
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = config.command_setup_filetypes,
    group = id,
    callback = function()
      local commands = require("python.commands")
      local dap = require("python.dap")
      local snip = require("python.snip")
      local ts = require("python.treesitter.commands")
      local keymap = require("python.keymap")
      commands.load_commands()
      dap.load_commands()
      ts.load_commands()
      snip.load_snippets()
      keymap.load_keymaps()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "test_*.py",
    group = id,
    callback = function()
      local test = require("python.test")
      test.load_commands()
    end,
  })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python")[k]
  end,
})
