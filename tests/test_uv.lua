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
      child.lua([[require('python').setup()]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})
T['uv'] = MiniTest.new_set({
  hooks = {
    pre_case = function()
    end
  }
})

T['uv']['command'] = function()
  child.cmd("cd examples/python_projects/uv")
  child.cmd("e main.py")
  child.cmd([[!rm -rf .venv]])
  child.cmd([[UV sync]])
  local dir = child.lua("return vim.fn.expand('%:p:h')")
  local venv_dir = vim.fs.joinpath(dir, ".venv")

  -- give some seconds for uv sync to download package
  vim.loop.sleep(3000)
  eq(child.lua(("return vim.fn.isdirectory('%s')"):format(venv_dir)), 1)
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
