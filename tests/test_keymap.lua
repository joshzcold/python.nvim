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

-- Keymaps can be loaded
T['keymaps'] = function()
  child.cmd("cd examples/python_projects/uv")
  child.cmd("e main.py")
  local keymap = child.cmd_capture("map <leader>pi")
  assert(string.find(keymap, "python venv install", 1, true))
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
