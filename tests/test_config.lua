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
      child.lua([[config = require('python.config')]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

T["setup"] = MiniTest.new_set()

T["setup"]["init"] = function()
  child.lua("config.setup({})")
  eq(child.lua("return config.python_lua_snippets"), false)
end

T["setup"]["override"] = function()
  child.lua("config.setup({ python_lua_snippets = true })")
  eq(child.lua("return config.python_lua_snippets"), true)
end

T["setup"]["not_found"] = function()
  child.lua("config.setup({ ui = { popup = {foobar = true}} })")
  eq(
    child.lua([[return vim.split(vim.fn.execute("messages", "silent"), "\n")]]),
    { "", "python.nvim: user inputted config key: foobar is not found in config table: config.ui.popup" }
  )
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
