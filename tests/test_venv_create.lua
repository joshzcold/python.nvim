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
      child.restart({ "-u", "scripts/minimal_init.lua" })
      -- Load tested plugin
      child.lua([[require('python').setup({})]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["create"] = MiniTest.new_set({ n_retry = 3 })

-- NOTE: requires python3 and python3-venv installed on system
T["create"]["venv"] = function()
  child.lua("create = require('python.venv.create')")
  child.cmd("cd examples/python_projects/uv")
  child.cmd("!rm -rf .venv")
  child.cmd("e main.py")
  child.lua("create.create_venv_with_python('.venv', 'python3')")
  assert(vim.fn.isdirectory("examples/python_projects/uv/.venv") == 1)
  child.cmd("!rm -rf .venv")
end

-- NOTE: requires uv installed on system
T["create"]["uv_sync"] = function()
  child.lua("create = require('python.venv.create')")
  child.cmd("cd examples/python_projects/uv")
  child.cmd("!rm -rf .venv")
  child.cmd("e main.py")
  child.lua("create.create_venv_with_python('.venv', 'python3')")
  child.lua("create.uv_sync('uv.lock', '.venv', function()end, false)")

  local dep_path =
    vim.fn.system([[examples/python_projects/uv/.venv/bin/python -c 'import sys; print(sys.path[-1], end="")']])

  assert(string.find(dep_path, "python_projects", 1, true))

  local check_dir = vim.fs.joinpath(dep_path, "requests")
  eq(vim.fn.isdirectory(check_dir), 1)
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
