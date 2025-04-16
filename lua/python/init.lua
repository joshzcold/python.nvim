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
    desc = "python.nvim: Actions after lsp is ready. Attach venv",
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
    desc = "python.nvim: Loading commands for python",
    group = id,
    callback = function()
      local commands = require("python.commands")
      local dap = require("python.dap")
      local snip = require("python.snip")
      local ts = require("python.treesitter.commands")
      local keymap = require("python.keymap")
      local hatch = require("python.hatch.commands")
      commands.load_commands()
      dap.load_commands()
      ts.load_commands()
      snip.load_snippets()
      keymap.load_keymaps()
      hatch.load_commands()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "test_*.py",
    desc = "python.nvim: Loading commands for test files",
    group = id,
    callback = function()
      local test = require("python.test")
      test.load_commands()
    end,
  })

  if config.enabled_text_actions then
    local ts = require("python.treesitter.commands")
    local enabled_text_actions_map = {
      ["f-strings"] = ts.pythonFStr
    }

    vim.api.nvim_create_autocmd(config.enabled_text_actions_autocmd_events, {
      group = id,
      desc = "python.nvim: Text actions while changing text",
      callback = function(ctx)
        local buf = ctx.buf
        if vim.bo[buf].ft ~= "python" then
          return
        end
        -- deferred to prevent race conditions with other autocmds
        for _, act in pairs(config.enabled_text_actions) do
          if enabled_text_actions_map[act] then
            local stringTransformFunc = enabled_text_actions_map[act]
            vim.defer_fn(stringTransformFunc, 1)
          end
        end
      end,
    })
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python")[k]
  end,
})
