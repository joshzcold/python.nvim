-- Define helper aliases
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
local child = MiniTest.new_child_neovim()

-- Define main test set of this file
local T = new_set({
  -- Register hooks
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      -- Load tested plugin
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

--- expect to detect wanted methods per project.
T['detect'] = MiniTest.new_set({
  parametrize = {
    {
      {
        project_path = "examples/python_projects/pip_requirements",
        install_file = "requirements.txt",
        dependency_method = "requirements.txt"
      }
    },
    {
      {
        project_path = "examples/python_projects/pip_pyproject",
        install_file = "pyproject.toml",
        dependency_method = "pyproject.toml"
      }
    },
    {
      {
        project_path = "examples/python_projects/uv",
        install_file = "uv.lock",
        dependency_method = "uv.lock"
      }
    },
    {
      {
        project_path = "examples/python_projects/poetry",
        install_file = "poetry.lock",
        dependency_method = "poetry.lock"
      }
    },
    {
      {
        project_path = "examples/python_projects/uv_script",
        install_file = "uv-script.py",
        dependency_method = "/// script"
      }
    },
    {
      {
        project_path = "examples/python_projects/no_dep",
        install_file = "test.py",
        dependency_method = "",
        expect_nil = true
      }
    },
  }
})

T['detect']['methods'] = function(args)
  require("python.venv.detect")
  local project_path = args.project_path
  child.cmd("cd " .. project_path)
  child.cmd([[!rm -rf .venv]])
  child.cmd("e " .. args.install_file)
  child.lua([[detect = require('python.venv.detect')]])

  -- Get abspath in lua for older versions of neovim
  local abspath = child.lua("return vim.fn.expand('%:p:h')")

  -- Weird vim.fs.joinpath in test is meant to have vim output the same pathing
  -- format that happens in windows from joinpath in detect_venv_dependency_file
  if vim.uv.os_uname().sysname == 'Windows_NT' then
    abspath = vim.fs.joinpath(vim.fs.dirname(child.lua("return vim.fn.expand('%:p:h')")),
      vim.fs.basename(args.project_path))
  end

  ---@type DetectVEnv | vim.NIL
  local ex = DetectVEnv:new({
    dir = abspath,
    venv = {
      install_file = vim.fs.joinpath(abspath, args.install_file),
      install_method = args.dependency_method,
      source = "venv"
    }
  })
  if args.expect_nil then
    ex = vim.NIL
  end

  eq(child.lua([[ return detect.detect_venv_dependency_file(false, false) ]]), ex)
end

return T
