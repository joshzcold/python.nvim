# python.nvim

Python Tools for Neovim

> [!WARNING]
> This plugin is currently in alpha status and can be subject to breaking changes
> Please file issues when found and feel free to contribute

https://github.com/user-attachments/assets/025f8475-e946-4875-bc91-53508ea5d3fa

## Installation

<details>
<summary>lazy.nvim</summary>

**Example Config**

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
    },
    init = function()
      vim.api.nvim_set_keymap(
        "n",
        "<leader>pv",
        '<cmd>lua require("python.venv").pick_venv()<cr>',
        { desc = "Python pick venv" }
      )
    end,
  }
}
```

**Include Snippets** by enabling `python_lua_snippets` and adding LuaSnip as a dependency

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
        python_lua_snippets = true
    },
  }
}
```

</details>

<summary>Configuration Options</summary>

<details>

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
        -- Should return a list of tables with a `name` and a `path` entry each.
        -- Gets the argument `venvs_path` set below.
        -- By default just lists the entries in `venvs_path`.
        ---@return VEnv[]
        get_venvs = function(venvs_path)
            return require('python.venv').get_venvs(venvs_path)
        end,
        -- Path for venvs picker
        venvs_path = vim.fn.expand('~/.virtualenvs'),
        -- Something to do after setting an environment
        post_set_venv = nil,
        -- base path for creating new venvs
        auto_create_venv_path = function(parent_dir)
            return vim.fs.joinpath(parent_dir, '.venv')
        end,
        -- Patterns for autocmd LspAttach that trigger the auto venv logic
        -- Add onto this list if you depend on venvs for other file types
        -- like .yaml, .yml for ansible
        auto_venv_lsp_attach_patterns = { "*.py" },

        -- Filetypes to activate commands for python.nvim
        command_setup_filetypes = { "python" },

        -- Load python.nvim python snippets
        python_lua_snippets = false,

        -- Settings regarding ui handling
        ui = {
            -- Amount of time to pause closing of ui after a finished task
            ui_close_timeout = 5000,
            -- zindex of new ui elements.
            zindex = 999,
            -- Default ui style for interfaces created by python.nvim
            ---@alias python_ui_default_style "'popup'|nil"
            default_ui_style = "popup",
            popup = {
            demensions = {
                width = "60",
                height = "25"
            }
            }
        },

        -- Tell neotest-python which test runner to use
        test = {
            test_runner = "pytest"
        }
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

- [x] Optional Python Snippets through luasnip

- [x] Integration with neotest. Commands to easily run tests through venv setup with `python.nvim`

- [ ] Treesitter integration
  - [ ] Functions utilizing treesitter for helpful code actions

## Commands

## Main Commands

| Command              | Functionality                                                                        |
| -------------------- | ------------------------------------------------------------------------------------ |
| `:PythonVEnvInstall` | Create a venv and install dependencies if a supported python package format is found |
| `:PythonDap`         | Create and save a new Dap configuration                                              |
| `:PythonTest`        | Run Suite of tests with `neotest`                                                    |
| `:PythonTestMethod`  | Run test function/method with `neotest`                                              |
| `:PythonTestFile`    | Run test file with `neotest`                                                         |

## Advanced Commands

| Command                   | Functionality                                                           |
| ------------------------- | ----------------------------------------------------------------------- |
| `:PythonVEnvDeleteSelect` | Select a venv to delete from `python.nvim` state                        |
| `:PythonVEnvDelete`       | Delete current selected venv in project in `python.nvim` state          |
| `:PythonDebugTest`        | Run Suite of tests with `neotest` in `dap` mode with `dap-python`       |
| `:PythonDebugTestMethod`  | Run test function/method with `neotest` in `dap` mode with `dap-python` |
| `:PythonDebugTestFile`    | Run test file with `neotest` in `dap` mode with `dap-python`            |

## Supported python package managers

| Manager | Install File         | Install Method   |
| ------- | -------------------- | ---------------- |
| uv      | uv.lock              | `uv sync`        |
| pdm     | pdm.lock             | `pdm sync`       |
| pip     | pyproject.toml       | `pip install .`  |
| pip     | dev-requirements.txt | `pip install -r` |
| pip     | requirements.txt     | `pip install -r` |

## Special Thanks

[swenv.nvim](https://github.com/AckslD/swenv.nvim) For almost all of the logic in selecting virtual envs.
Use this plugin if you want a more simple venv management plugin for your workflow.

[go.nvim](https://github.com/ray-x/go.nvim) for inspiration.
```
