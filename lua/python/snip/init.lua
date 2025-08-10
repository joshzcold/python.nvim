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

local always = {
  show_condition = function() return true end,
  condition = function() return true end,
}

local snippets = {
  -- Main
  ls.s(
    { trig = "main", name = "Main", dscr = "python.nvim: Create a main function" },
    fmt([[
    def main():
      {}

    if __name__ == "__main__":
      main()
    ]], ls.i(0)),
    not_in_fn
  ),

  ls.s(
    { trig = "ifmain", name = "Main", dscr = "python.nvim: Create a main function" },
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
      trig = "argparse_typed",
      name = "Argparse Typed Arguments",
      dscr =
      "python.nvim: Argparse mapping to dataclass for typed completion of arguments"
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
      dscr = "python.nvim: Python const variables of terminal colors escape sequences."
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
    always
  ),

  ls.s(
    {
      trig = "match_case",
      name = "Match-Case statement",
      dscr = "python.nvim: Python Match Case statement with default case."
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
    always
  ),
  ls.s(
    {
      trig = "switch_case",
      name = "Match-Case statement",
      dscr = "python.nvim: Python Match Case statement with default case."
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
    always
  ),
  ls.s(
    {
      trig = "if_ternary_condition",
      name = "Python version of a ternay",
      dscr = "python.nvim: Single line conditional, emulating ternarary"
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
    always
  ),
  ls.s(
    {
      trig = "list_comprehension",
      name = "Python create list loop expression",
      dscr = "python.nvim: Create new list from expression inside of list"
    },
    fmt([[
      {var} = [a for a in x if a == True]
    ]], {
      var = ls.i(1, { "var" }),
    }),
    always
  ),
  ls.s(
    {
      trig = "merge_dicts",
      name = "Python create dict from 2 dicts using spread operation",
      dscr = "python.nvim: Create dictionary from spread operator"
    },
    fmt([[
      {var} = {{**{dict_1}, **{dict_2} }}
    ]], {
      var = ls.i(1, { "var" }),
      dict_1 = ls.i(1, { "dict_1" }),
      dict_2 = ls.i(1, { "dict_2" }),
    }),
    always
  ),
  ls.s(
    {
      trig = "with_open",
      name = "python create open file io",
      dscr = "python.nvim: create io object with open"
    },
    fmt([[
      with open("/path", "{r}", encoding="utf-8") as f:
        ...{finally}
    ]], {
      r = ls.i(1, { "r" }),
      finally = ls.i(0),
    }),
    always
  ),
  ls.s(
    {
      trig = "for_with_index",
      name = "Python For in loop with index",
      dscr = "python.nvim: for in loop with index in python"
    },
    fmt([[
      for i, {val} in enumerate({var}):
        ...{finally}
    ]], {
      val = ls.i(1, { "val" }),
      var = ls.i(2, { "var" }),
      finally = ls.i(0),
    }),
    always
  ),
  ls.s(
    {
      trig = "enumerate",
      name = "Python For in loop with index",
      dscr = "python.nvim: for in loop with index in python"
    },
    fmt([[
      for i, {val} in enumerate({var}):
        ...{finally}
    ]], {
      val = ls.i(1, { "val" }),
      var = ls.i(2, { "var" }),
      finally = ls.i(0),
    }),
    always
  ),
  ls.s(
    {
      trig = "colored_logs",
      name = "Python colorized logger formatter",
      dscr = "python.nvim: logging module formatter for colored logs"
    },
    fmt([[
      import logging

      class ColoredFormatter(logging.Formatter):
          """Colorize log output in logger."""

          grey = "\033[90m"
          cyan = "\033[96m"
          yellow = "\033[93m"
          red = "\033[91m"
          bold_red = "\033[1;31m"
          reset = "\033[0m"
          str_format = "%(levelname)s - %(message)s (%(filename)s:%(lineno)d)"  # type: ignore

          FORMATS = {{
              logging.DEBUG: grey + str_format + reset,  # type: ignore
              logging.INFO: cyan + str_format + reset,  # type: ignore
              logging.WARNING: yellow + str_format + reset,  # type: ignore
              logging.ERROR: red + str_format + reset,  # type: ignore
              logging.CRITICAL: bold_red + str_format + reset,  # type: ignore
          }}

          def format(self, record):
              """Return log message using mapped formatter per level."""
              log_fmt = self.FORMATS.get(record.levelno)
              formatter = logging.Formatter(log_fmt)
              return formatter.format(record)

      log: logging.Logger = logging.getLogger(__file__)
      log.setLevel(logging.INFO)
      ch = logging.StreamHandler()
      ch.setLevel(logging.INFO)
      ch.setFormatter(ColoredFormatter())
      log.addHandler(ch)
    ]], {}, {}
    ),
    {},
    not_in_fn
  ),

  ls.s(
    {
      trig = "requests_get",
      name = "requests GET",
      dscr = "python.nvim: requests Library get call",
    },
    fmt([[
        resp = requests.get(url="{}", headers={{}}, params={{}})
        resp.raise_for_status()
      ]],
      {
        ls.i(1, "http://localhost")
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "requests_post",
      name = "requests POST",
      dscr = "python.nvim: requests Library post call",
    },
    fmt([[
        resp = requests.post(url="{}", headers={{}}, params={{}}, body={{

        }})
        resp.raise_for_status()
      ]],
      {
        ls.i(1, "http://localhost")
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "requests_put",
      name = "requests PUT",
      dscr = "python.nvim: requests Library put call",
    },
    fmt([[
        resp = requests.put(url="{}", headers={{}}, params={{}}, body={{

        }})
        resp.raise_for_status()
      ]],
      {
        ls.i(1, "http://localhost")
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "requests_delete",
      name = "requests DELETE",
      dscr = "python.nvim: requests Library delete call",
    },
    fmt([[
        resp = requests.delete(url="{}", headers={{}}, params={{}})
        resp.raise_for_status()
      ]],
      {
        ls.i(1, "http://localhost")
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "add_argument_string",
      name = "argparse string arg",
      dscr = "python.nvim: argparse string argument",
    },
    fmt([[
        parser.add_argument('--{}', metavar='{}', type=str, help='{}', required=True)
      ]],
      {
        ls.i(1, "arg"),
        ls.i(2, "-a"),
        ls.i(3, "help"),
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "add_argument_boolean",
      name = "argparse string bool",
      dscr = "python.nvim: argparse bool argument flag",
    },
    fmt([[
        parser.add_argument('--{}', metavar='{}', action="store_true", help='{}')
      ]],
      {
        ls.i(1, "on"),
        ls.i(2, "-y"),
        ls.i(3, "Turn on this feature"),
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "add_argument_list",
      name = "argparse string list",
      dscr = "python.nvim: argparse list arguments",
    },
    fmt([[
        parser.add_argument('--{}', metavar='{}', action="append", help='{}')
      ]],
      {
        ls.i(1, "list"),
        ls.i(2, "-l"),
        ls.i(3, "Append arguments into a list"),
      },
      {}
    ),
    always
  ),
  ls.s(
    {
      trig = "#!/usr/bin/env uv",
      name = "UV script shebang with dependencies",
      dscr = "python.nvim: UV script shebang with dependency definition.",
    },
    fmt([[
        #!/usr/bin/env -S uv run --script
        #
        # /// script
        # requires-python = ">=3.12"
        # dependencies = [
        #   "{}"
        # ]
        # ///
      ]],
      {
        ls.i(1, "requests"),
      },
      {}
    ),
    always
  ),
}

function M.load_snippets()
  if not config.python_lua_snippets then
    return
  end
  if vim.g._python_nvim_snippets_loaded == nil then
    ls.add_snippets("python", snippets)
  end
  vim.g._python_nvim_snippets_loaded = true
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.snip")[k]
  end,
})
