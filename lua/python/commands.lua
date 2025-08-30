-- python.nvim commands
local PythonCommands = {}

---@class PythonSubcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, PythonSubcommand>
local subcommand_tbl = {
  test = {
    impl = function(args, _)
      local test = require("python.test")
      local command = args[1]

      if command == "test" then
        test.neotest_test()
        return
      end
      if command == "test_method" then
        test.neotest_test_method()
        return
      end
      if command == "test_file" then
        test.neotest_test_file()
        return
      end
      if command == "test_debug" then
        test.neotest_debug_test()
        return
      end
      if command == "test_method_debug" then
        test.neotest_debug_test_method()
        return
      end
      if command == "test_file_debug" then
        test.neotest_debug_test_file()
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "test",
        "test_method",
        "test_file",
        "test_debug",
        "test_method_debug",
        "test_file_debug",
      }

      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  dap = {
    impl = function(args, _)
      local dap = require("python.dap")
      local command = args[1]

      if command == "" then
        dap.python_dap_run()
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {}

      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  hatch = {
    impl = function(args, _)
      local hatch = require("python.hatch.commands")
      local command = args[1]

      if not hatch.check_hatch() then
        vim.notify("python.nvim: command 'hatch' not found on your system.", vim.log.levels.WARN)
        return
      end

      if command == "install" then
        hatch.hatch_install_python()
        return
      end

      if command == "delete" then
        hatch.hatch_delete_python()
        return
      end
      if command == "list" then
        hatch.hatch_list_python()
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "install",
        "delete",
        "list",
      }

      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  lsp = {
    impl = function(args, _)
      local lsp = require("python.lsp.commands")
      local command = args[1]

      if command == "pyright_change_type_checking_mode" then
        lsp.pyright_change_type_checking(args[#args])
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "pyright_change_type_checking_mode",
      }

      if subcmd_arg_lead:find("pyright_change_type_checking_mode") ~= nil then
        return { "off", "basic", "standard", "strict", "all" }
      end
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  uv = {
    impl = function(args, _)
      local uv = require("python.uv.commands")
      if not uv.check_uv() then
        vim.notify("python.nvim: command 'uv' not found on system.")
        return
      end
      local command = args[1]

      if command == "install_python" then
        uv.uv_install_python()
        return
      end

      if command == "delete_python" then
        uv.uv_delete_python()
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "install_python",
        "delete_python",
      }
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  treesitter = {
    impl = function(args, _)
      local ts = require("python.treesitter")
      local ts_cmd = require("python.treesitter.commands")
      local command = args[1]

      if command == "test" then
        ts.test_ts_queries()
        return
      end

      if command == "toggle_enumerate" then
        ts_cmd.ts_toggle_enumerate()
      end

      if command == "wrap_cursor" then
        -- Account for if the last argument is the command or an actual arg
        local wrap_arg = args[#args]
        if wrap_arg == "wrap_cursor" then
          wrap_arg = ""
        end
        ts_cmd.ts_wrap_at_cursor(wrap_arg)
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "toggle_enumerate",
        "wrap_cursor",
        "test",
      }
      if subcmd_arg_lead:find("wrap_cursor") ~= nil then
        local config = require("python.config")
        return config.treesitter.functions.wrapper.substitute_options
      end
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  venv = {
    impl = function(args, _)
      local lsp = require("python.lsp")
      local create = require("python.venv.create")
      local venv = require("python.venv")
      local command = args[1]
      if command == "install" then
        create.create_and_install_venv()
        return
      end
      if command == "pick" then
        venv.pick_venv()
        return
      end
      if command == "reload_lsps" then
        lsp.notify_workspace_did_change()
        return
      end
      if command == "delete" then
        create.delete_venv(false)
        return
      end
      if command == "delete_select" then
        create.delete_venv(true)
        return
      end
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "pick",
        "install",
        "reload_lsps",
        "delete",
        "delete_select",
      }
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
}

---@param opts table :h lua-guide-commands-create
local function python_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify("Rocks: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

function PythonCommands.load_commands()
  -- NOTE: the options will vary, based on your use case.
  vim.api.nvim_create_user_command("Python", python_cmd, {
    nargs = "+",
    desc = "Python.nvim commands",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Python[!]*%s(%S+)%s(.*)$")
      if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
        -- The subcommand has completions. Return them.
        return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Python[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return vim
          .iter(subcommand_keys)
          :filter(function(key)
            return key:find(arg_lead) ~= nil
          end)
          :totable()
      end
    end,
    bang = true, -- If you want to support ! modifiers
    range = true, -- Support some visual command
  })
end

return PythonCommands
