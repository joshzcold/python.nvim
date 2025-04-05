local M = {}

local dap = require("python.dap")
local config = require("python.config")

local dap_python = require("dap-python")
local neotest = require("neotest")

-- Setup neotest and merge configuration to supply current venv
local function neotest_setup()
  local venv = require('python.venv').current_venv()

  local neotest_python_config = {
    runner = config.test.test_runner,
  }

  -- If in venv then executes tests within that venv
  if venv then
    neotest_python_config["python"] = vim.fs.joinpath(venv.path, "bin", "python3")
  end
  local neotest_config = require("neotest.config")

  local new_config = {
    adapters = {
      require("neotest-python")(neotest_python_config)
    }
  }

  -- Merge existing configuration
  local merged = vim.tbl_deep_extend('force', neotest_config, new_config)
  neotest.setup(merged)
end

local function neotest_test_method()
  neotest_setup()
  neotest.run.run()
end

local function neotest_test()
  neotest_setup()
  neotest.run.run({ suite = true })
  neotest.summary.open()
end

local function neotest_debug_test()
  dap.prepare_debugpy(function(venv)
    vim.schedule(function()
      dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
      neotest_setup()
      neotest.run.run({ suite = true, strategy = "dap" })
    end)
  end)
end

local function neotest_test_file()
  neotest_setup()
  neotest.run.run(vim.fn.expand("%"))
  neotest.summary.open()
end

local function neotest_debug_test_file()
  dap.prepare_debugpy(function(venv)
    vim.schedule(function()
      dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
      neotest_setup()
      neotest.run.run({ vim.fn.expand("%"), strategy = "dap", suite = false })
    end)
  end)
end

local function neotest_debug_test_method()
  dap.prepare_debugpy(function(venv)
    vim.schedule(function()
      dap_python.setup(vim.fs.joinpath(venv.path, "bin", "python3"), {})
      neotest_setup()
      neotest.run.run({ strategy = "dap", suite = false })
    end)
  end)
end

function M.load_commands()
  vim.api.nvim_create_user_command("PythonTest", function()
    neotest_test()
  end, { desc = "python.nvim: run test suite with neotest" })

  vim.api.nvim_create_user_command("PythonTestMethod", function()
    neotest_test_method()
  end, { desc = "python.nvim: run test method with neotest" })

  vim.api.nvim_create_user_command("PythonTestFile", function()
    neotest_test_file()
  end, { desc = "python.nvim: run test file with neotest" })

  vim.api.nvim_create_user_command("PythonDebugTest", function()
    neotest_debug_test()
  end, { desc = "python.nvim: run test suite with neotest in debug mode" })

  vim.api.nvim_create_user_command("PythonDebugTestMethod", function()
    neotest_debug_test_method()
  end, { desc = "python.nvim: run test method with neotest in debug mode" })

  vim.api.nvim_create_user_command("PythonDebugTestFile", function()
    neotest_debug_test_file()
  end, { desc = "python.nvim: run test class with neotest in debug mode" })
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.test")[k]
  end,
})
