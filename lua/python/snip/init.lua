local M = {}

local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep
local ai = require("luasnip.nodes.absolute_indexer")
local partial = require("luasnip.extras").partial
local nodes = require('python.treesitter.nodes')
local config = require('python.config')

local function is_in_test_file()
  local filename = vim.fn.expand('%:p')
  -- no required convention for python tests.
  -- Just assume if test is in the full path we might be in a test file.
  return string.find(filename, "test")
end

local function is_in_test_function()
  return is_in_test_file() and nodes.inside_function()
end

local in_test_fn = {
  show_condition = is_in_test_function,
  condition = is_in_test_function,
}

local in_test_file = {
  show_condition = is_in_test_file,
  condition = is_in_test_file,
}

local in_fn = {
  show_condition = nodes.inside_function,
  condition = nodes.inside_function,
}

local not_in_fn = {
  show_condition = not nodes.inside_function,
  condition = not nodes.inside_function,
}

local snippets = {
  -- Main
  ls.s(
    { trig = "main", name = "Main", dscr = "Create a main function" },
    fmt([[
    def main():
      {}

    if __name__ == "__main__":
      main()
    ]], ls.i(0)),
    not_in_fn
  ),

  ls.s(
    {
      trig = "args_typed",
      name = "Argparse Typed Arguments",
      dscr =
      "Argparse mapping to dataclass for typed completion of arguments"
    },
    fmt([[
      import argparse
      from dataclasses import dataclass


      @dataclass
      class ProgramArgs:
          """Typed program arguments."""
          {my_arg_1}: str


      def parse_args():
          parser = argparse.ArgumentParser(description="")

          parser.add_argument("--{my_arg_2}", dest="{my_arg_3}")
          return parser.parse_args(namespace=ProgramArgs)
      {finally}
    ]],
      {
        my_arg_1 = ls.i(1, { "my_arg_1" }),
        my_arg_2 = rep(1),
        my_arg_3 = rep(1),
        finally  = ls.i(0)
      }),
    not_in_fn
  ),

  ls.s(
    {
      trig = "colors",
      name = "Color variables",
      dscr = "Python const variables of terminal colors escape sequences."
    },
    fmt([[
      PURPLE = "\033[95m"
      BLUE = "\033[94m"
      CYAN = "\033[96m"
      GREEN = "\033[92m"
      GRAY = "\033[90m"
      YELLOW = "\033[93m"
      RED = "\033[91m"
      RESET = "\033[0m"
      BOLD = "\033[1m"
      UNDERLINE = "\033[4m"
      ITALICS = "\033[3m"
      {}
    ]], {
      ls.i(0)
    }),
    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  ),

  ls.s(
    {
      trig = "match_case",
      name = "Match-Case statement",
      dscr = "Python Match Case statement with default case."
    },
    fmt([[
      match {var}:
        case "{one}":
          ...{finally}
        case _:
          ...
    ]], {
      var = ls.i(1, { "var" }),
      one = ls.i(2, { "one" }),
      finally = ls.i(0)
    }),

    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  ),
  ls.s(
    {
      trig = "switch_case",
      name = "Match-Case statement",
      dscr = "Python Match Case statement with default case."
    },
    fmt([[
      match {var}:
        case "{one}":
          ...{finally}
        case _:
          ...
    ]], {
      var = ls.i(1, { "var" }),
      one = ls.i(2, { "one" }),
      finally = ls.i(0)
    }),

    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  ),
  ls.s(
    {
      trig = "switch_case",
      name = "Match-Case statement",
      dscr = "Python Match Case statement with default case."
    },
    fmt([[
      match {var}:
        case "{one}":
          ...{finally}
        case _:
          ...
    ]], {
      var = ls.i(1, { "var" }),
      one = ls.i(2, { "one" }),
      finally = ls.i(0)
    }),

    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  ),
  ls.s(
    {
      trig = "ternary_condition",
      name = "Python version of a ternay",
      dscr = "Single line conditional, emulating ternarary"
    },
    fmt([[
      {var} = "{foo}" if {True} else "{bar}"{finally}
    ]], {
      var = ls.i(1, { "var" }),
      foo = ls.i(2, { "foo" }),
      True = ls.i(3, { "True" }),
      bar = ls.i(4, { "bar" }),
      finally = ls.i(0)
    }),

    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  ),
  ls.s(
    {
      trig = "list_comprehension",
      name = "Python create list loop expression",
      dscr = "Create new list from expression inside of list"
    },
    fmt([[
      {var} = [a for a in x if a == True]
    ]], {
      var = ls.i(1, { "var" }),
    }),
    {
      show_condition = function() return true end,
      condition = function() return true end,
    }
  )
}

function M.load_snippets()
  if not config.python_snippets then
    return
  end
  ls.add_snippets("python", snippets)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.snip")[k]
  end,
})
