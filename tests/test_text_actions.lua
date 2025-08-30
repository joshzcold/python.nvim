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
      child.lua([[require('python').setup()]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

local get_lines = function()
  return child.api.nvim_buf_get_lines(0, 0, -1, true)
end

T["text_actions"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.cmd("e _not_existing_new_buffer.py")
    end,
  },
})

T["text_actions"]["insert_f_string"] = function()
  child.type_keys("i", [[print("{foo}")]], "<left><esc>")

  eq(get_lines(), { [[print(f"{foo}")]] })
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
