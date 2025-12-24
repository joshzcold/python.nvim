--- *python.nvim* Python tool box for neovim
---
--- MIT License Copyright (c) 2025 Joshua Cold
---
--- ==============================================================================
---
--- |python.nvim| is a collection of tools for python development in neovim.
--- Helping speed up dependency management, debugging and other tasks that
--- apart of developing in the python language.
---
---@class python
local Python = {}

---@param opts? python.Config
function Python.setup(opts)
  local config = require("python.config")
  config.setup(opts)

  local id = vim.api.nvim_create_augroup("python_nvim_autocmd_group", { clear = true })

  -- Auto load venv on lsp server attach
  vim.api.nvim_create_autocmd({ "LspAttach" }, {
    pattern = config.auto_venv_lsp_attach_patterns,
    desc = "python.nvim: Actions after lsp is ready. Attach venv",
    group = id,
    callback = function(args)
      local detect = require("python.venv.detect")

      if not args.data.client_id then
        return
      end

      local client = vim.lsp.get_client_by_id(args.data.client_id)

      if client == nil then
        return
      end

      -- TODO: should I put this in an autocmd that only runs once instead of for
      -- each lsp server?
      detect.detect_venv_dependency_file(true, true)
    end,
  })

  -- Load up commands for users
  vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = config.command_setup_buf_pattern,
    desc = "python.nvim: Loading commands for python",
    group = id,
    callback = function()
      local venv = require("python.venv")
      local commands = require("python.commands")
      local snip = require("python.snip")
      local uv = require("python.uv.commands")

      commands.load_commands()
      uv.load_commands()

      snip.load_snippets()

      venv.load_existing_venv()
    end,
  })

  if config.enabled_text_actions then
    local ts = require("python.treesitter.commands")
    local enabled_text_actions_map = {
      ["f-strings"] = ts.pythonFStr,
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

return Python
