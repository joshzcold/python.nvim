
<div align="center">
<img src="./doc/python_nvim_logo.svg" alt="logo" width="200"/>

<h2>Python Tools for Neovim</h2>

</div>

https://github.com/user-attachments/assets/5a637270-3785-4929-828b-628d553b5732

## Installation

<details>
<summary>lazy.nvim</summary>

**Example Config**

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    dependencies = {
        { "mfussenegger/nvim-dap" },
        { "mfussenegger/nvim-dap-python" },
        { "neovim/nvim-lspconfig" },
        { "L3MON4D3/LuaSnip" },
        { "nvim-neotest/neotest" },
        { "nvim-neotest/neotest-python" },
    },
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
    }
    -- Optional suggested keymaps
    keys = {
      { "<leader>pv", "<cmd>Python venv pick<cr>", desc = "python.nvim: pick venv" },
      { "<leader>pi", "<cmd>Python venv install<cr>", desc = "python.nvim: python venv install" },
      { "<leader>pd", "<cmd>Python dap<cr>", desc = "python.nvim: python run debug program" },

      -- Test Actions
      { "<leader>ptt", "<cmd>Python test test<cr>", desc = "python.nvim: python run test suite" },
      { "<leader>ptm", "<cmd>Python test test_method<cr>", desc = "python.nvim: python run test method" },
      { "<leader>ptf", "<cmd>Python test test_file<cr>", desc = "python.nvim: python run test file" },
      { "<leader>ptdd", "<cmd>Python test test_debug<cr>", desc = "python.nvim: run test suite in debug mode." },
      {
        "<leader>ptdm",
        "<cmd>Python test test_method_debug<cr>",
        desc = "python.nvim: run test method in debug mode.",
      },
      { "<leader>ptdf", "<cmd>Python test_file_debug<cr>", desc = "python.nvim: run test file in debug mode." },

      -- VEnv Actions
      { "<leader>ped", "<cmd>Python venv delete_select<cr>", desc = "python.nvim: select and delete a known venv." },
      { "<leader>peD", "<cmd>Python venv delete<cr>", desc = "python.nvim: delete current venv set." },

      -- Language Actions
      { "<leader>ppe", "<cmd>Python treesitter toggle_enumerate<cr>", desc = "python.nvim: turn list into enumerate" },
      {
        "<leader>pw",
        "<cmd>Python treesitter wrap_cursor<cr>",
        desc = "python.nvim: wrap treesitter identifier with pattern",
      },
      {
        "<leader>pw",
        mode = "v",
        ":Python treesitter wrap_cursor<cr>",
        desc = "python.nvim: wrap treesitter identifier with pattern",
      },
    },
  }
}
```

**Include Snippets** by enabling `python_lua_snippets` and adding LuaSnip as a dependency

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    dependencies = {
        { "mfussenegger/nvim-dap" },
        { "mfussenegger/nvim-dap-python" },
        { "neovim/nvim-lspconfig" },
        { "L3MON4D3/LuaSnip" },
        { "nvim-neotest/neotest" },
        { "nvim-neotest/neotest-python" },
    },
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
        python_lua_snippets = true
    },
  }
}
```

</details>

<details>
<summary>vim.pack</summary>

**Example Config**

```lua
vim.pack.add("https://github.com/joshzcold/python.nvim")
vim.pack.add("https://github.com/mfussenegger/nvim-dap")
vim.pack.add("https://github.com/mfussenegger/nvim-dap-python")
vim.pack.add("https://github.com/neovim/nvim-lspconfig")
vim.pack.add("https://github.com/L3MON4D3/LuaSnip")
vim.pack.add("https://github.com/nvim-neotest/neotest")
vim.pack.add("https://github.com/nvim-neotest/neotest-python")
```

</details>

<details>
<summary>Configuration Options</summary>

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = {
    -- Should return a list of tables with a `name` and a `path` entry each.
    -- Gets the argument `venvs_path` set below.
    -- By default just lists the entries in `venvs_path`.
    ---@return VEnv[]
    get_venvs = function(venvs_path)
        return require("python.venv").get_venvs(venvs_path)
    end,
    -- Path for venvs picker
    venvs_path = vim.fn.expand("~/.virtualenvs"),
    -- Something to do after setting an environment
    post_set_venv = nil,
    -- base path for creating new venvs
    auto_create_venv_path = function(parent_dir)
        return vim.fs.joinpath(parent_dir, ".venv")
    end,
    -- Patterns for autocmd LspAttach that trigger the auto venv logic
    -- Add onto this list if you depend on venvs for other file types
    -- like .yaml, .yml for ansible
    auto_venv_lsp_attach_patterns = { "*.py" },

    -- Buffer patterns to activate commands for python.nvim
    command_setup_buf_pattern = { "*.py" },

    -- Load python.nvim python snippets
    python_lua_snippets = false,

    -- List of text actions to take on InsertLeave, TextChanged
    -- Put in empty table or nil to disable
    enabled_text_actions = {
        "f-strings", -- When inserting {}, put in an f-string
    },
    -- Adjust when enabled_text_actions is triggered
    enabled_text_actions_autocmd_events = { "InsertLeave" },

    treesitter = {
        functions = {
        -- Wrap treesitter identifier under cursor using substitute_options
        wrapper = {
            -- Substitute options for PythonTSWrapWithFunc
            substitute_options = {
            "print(%s)",
            "log.debug(%s)",
            "log.info(%s)",
            "log.warning(%s)",
            "log.error(%s)",
            "np.array(%s)",
            },

            -- Look for tree-sitter types to wrap
            find_types = {
            "tuple",
            "string",
            "true",
            "false",
            "list",
            "call",
            "parenthesized_expression",
            "expression_statement",
            "integer",
            },
        },
        },
    },
    -- Settings regarding ui handling
    ui = {
        -- Amount of time to pause closing of ui after a finished task
        ui_close_timeout = 5000,

        -- Default ui style for interfaces created by python.nvim
        ---@alias python_ui_default_style "'popup'|'split'|nil"
        default_ui_style = "popup",

        -- Customize the position and behavior of the ui style
        popup = {
        win_opts = {
            -- border = "rounded",
            -- relative = "win",
            -- focusable = true,
            -- title = "python.nvim",
            -- anchor = "SE",
            -- zindex = 999,
            -- width = 40,
            -- height = 20,
            -- row = vim.o.lines - 3,
            -- col = vim.o.columns -2,
        },
        },
        split = {
        win_opts = {
            -- split = 'below',
            -- win = 0,
            -- width = 40,
            -- height = 10,
            -- focusable = true,
        },
        },
    },

    -- Tell neotest-python which test runner to use
    test = {
        test_runner = "pytest",
    },
    }
  }
}

```

</details>

## Features

- [x] Switch between virtual envs interactively
- [x] Interactively create virtual envs and install dependencies

  - [x] Reload all the common python LSP servers if found to be running
  - [x] Lot of commands to control venvs

- [x] Keep track of envs/pythons per project in state

- [x] Easier setup of python debugging

  - [x] Automatically install debugpy into venv
  - [x] Interactively create a DAP config for a program, saving configuration.

- [x] Utility features

  - [x] Function to swap type checking mode for pyright, basedpyright
  - [x] Function to launch test method, class, etc. in DAP
  - [x] Functions to install python interpreters via [hatch](https://hatch.pypa.io/latest/)

- [x] Optional Python Snippets through luasnip

  > Enable with `python_lua_snippets` in config

- [x] Integration with neotest. Commands to easily run tests through venv setup with `python.nvim`

  > See `test` in config and `:PythonTest*` commands

- Treesitter integration
- Functions utilizing treesitter for helpful code actions
- [x] Auto insert fstrings while typing `{}`
  > See `enabled_text_actions` in config
- [x] Toggle a list into an `enumerate()` list with index
  > Try `:Python treesitter toggle_enumerate` on a `for x in list` list
- [x] Wrap treesitter objects with a pattern.
  > Try `:Python treesitter wrap_cursor` on a list or tuple. Check config for options
  > Can turn `[1, 2, 3]` -> `np.array([1, 2, 3])`
  > Supply a pattern to immediately wrap like `:Python treesitter wrap_cursor np.array(%s)`
  > Select in visual mode and execute `:'<'>Python treesitter wrap_cursor`

## Commands

## Main Commands

| Command                               | Functionality                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------ |
| `:Python venv install`                | Create a venv and install dependencies if a supported python package format is found |
| `:Python dap`                         | Create and save a new Dap configuration                                              |
| `:Python test test`                        | Run Suite of tests with `neotest`                                                    |
| `:Python test test_method`                 | Run test function/method with `neotest`                                              |
| `:Python test test_file`                   | Run test file with `neotest`                                                         |
| `:Python treesitter toggle_enumerate` | Turn a regular list into `enumerate()` list and back                                 |
| `:Python treesitter wrap_cursor`      | Wrap treesitter indentifiers in a pattern for quick injection.                       |
| `:Python treesitter wrap_cursor`      | Wrap treesitter indentifiers in visual mode                                          |

## Advanced Commands

| Command                      | Functionality                                                                          |
| ---------------------------- | -------------------------------------------------------------------------------------- |
| `:Python venv delete_select` | Select a venv to delete from `python.nvim` state                                       |
| `:Python venv delete`        | Delete current selected venv in project in `python.nvim` state                         |
| `:Python test test_debug`         | Run Suite of tests with `neotest` in `dap` mode with `dap-python`                      |
| `:Python test test_method_debug`  | Run test function/method with `neotest` in `dap` mode with `dap-python`                |
| `:Python test test_file_debug`    | Run test file with `neotest` in `dap` mode with `dap-python`                           |
| `:Python hatch list`         | List python interpreters installed by [hatch](https://hatch.pypa.io/latest/)           |
| `:Python hatch install`      | Install a python interpreter using [hatch](https://hatch.pypa.io/latest/)              |
| `:Python hatch delete`       | Delete a python interpreter from [hatch](https://hatch.pypa.io/latest/)                |
| `:Python uv install_python`  | Delete a python interpreter from [uv](https://docs.astral.sh/uv/)                      |
| `:Python uv delete_python`   | Delete a python interpreter from [uv](https://docs.astral.sh/uv/)                      |
| `:UV <command>`              | Pass through commands to [uv](https://docs.astral.sh/uv/) with command line completion |

## Supported python package managers

| Manager | Install File         | Install Method                                                                               |
| ------- | -------------------- | -------------------------------------------------------------------------------------------- |
| uv      | uv.lock              | `uv sync --active --frozen`                                                                  |
| uv      | `/// script` block   | `uv sync --sync --script % --active`                                                         |
| pdm     | pdm.lock             | `pdm sync`                                                                                   |
| poetry  | poetry.lock          | `poetry sync --no-root`                                                                      |
| pip     | pyproject.toml       | `pip install .`                                                                              |
| pip     | dev-requirements.txt | `pip install -r`                                                                             |
| pip     | requirements.txt     | `pip install -r`                                                                             |
| conda   | -                    | When using the environment picker. python.nvim saves the environment you last used in state. |

## Supported OS's

- [x] Linux

- [x] MacOS

  - [x] I am detecting python interpreters in homebrew and hatch and uv. Testing in ci.

- [ ] Windows (Un tested)
  - [ ] Need to test this plugin on a windows machine to verify. I have seen online that neovim users are deciding on WezTerm + WSL to handle support for neovim plugins.

## Special Thanks

[swenv.nvim](https://github.com/AckslD/swenv.nvim) For almost all of the logic in selecting virtual envs.
Use this plugin if you want a more simple venv management plugin for your workflow.

[go.nvim](https://github.com/ray-x/go.nvim) for inspiration.

[nvim-puppeteer](https://github.com/chrisgrieser/nvim-puppeteer) for treesitter action on inserting f-strings
