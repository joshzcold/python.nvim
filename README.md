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
    }
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

        -- List of text actions to take on InsertLeave, TextChanged
        -- Put in empty table or nil to disable
        enabled_text_actions = {
            "f-strings" -- When inserting {}, put in an f-string
        },
        -- Adjust when enabled_text_actions is triggered
        enabled_text_actions_autocmd_events = { "InsertLeave" },

        -- Load python keymaps. Everything starting with <leader>p...
        keymaps = {
            -- following nvim_set_keymap() mode, lhs, rhs, opts
            mappings = {
            ['<leader>pv'] = { "n", "<cmd>PythonVEnvPick<cr>", { desc = "python.nvim: pick venv" } },
            ['<leader>pi'] = { "n", "<cmd>PythonVEnvInstall<cr>", { desc = "python.nvim: python venv install" } },
            ['<leader>pd'] = { "n", "<cmd>PythonDap<cr>", { desc = "python.nvim: python run debug program" } },

            -- Test Actions
            ['<leader>ptt'] = { "n", "<cmd>PythonTest<cr>", { desc = "python.nvim: python run test suite" } },
            ['<leader>ptm'] = { "n", "<cmd>PythonTestMethod<cr>", { desc = "python.nvim: python run test method" } },
            ['<leader>ptf'] = { "n", "<cmd>PythonTestFile<cr>", { desc = "python.nvim: python run test file" } },
            ['<leader>ptdd'] = { "n", "<cmd>PythonDebugTest<cr>", { desc = "python.nvim: run test suite in debug mode." } },
            ['<leader>ptdm'] = { "n", "<cmd>PythonDebugTestMethod<cr>", { desc = "python.nvim: run test method in debug mode." } },
            ['<leader>ptdf'] = { "n", "<cmd>PythonDebugTestFile<cr>", { desc = "python.nvim: run test file in debug mode." } },

            -- VEnv Actions
            ['<leader>ped'] = { "n", "<cmd>PythonVEnvDeleteSelect<cr>", { desc = "python.nvim: select and delete a known venv." } },
            ['<leader>peD'] = { "n", "<cmd>PythonVEnvDelete<cr>", { desc = "python.nvim: delete current venv set." } },

            -- Language Actions
            ['<leader>ppe'] = { "n", "<cmd>PythonTSToggleEnumerate<cr>", { desc = "python.nvim: turn list into enumerate" } },
            }
        },
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

  > Enable with `python_lua_snippets` in config

- [x] Integration with neotest. Commands to easily run tests through venv setup with `python.nvim`

  > See `test` in config and `:PythonTest*` commands

- [ ] Treesitter integration
  - [ ] Functions utilizing treesitter for helpful code actions
    - [x] Auto insert fstrings while typing `{}`
      > See `enabled_text_actions` in config
    - [x] Toggle a list into an `enumerate()` list with index
      > Try `:PythonTSToggleEnumerate` on a `for x in list` list

## Commands

## Main Commands

| Default KeyMap | Command                    | Functionality                                                                        |
| -------------- | -------------------------- | ------------------------------------------------------------------------------------ |
| `<leader>pi`   | `:PythonVEnvInstall`       | Create a venv and install dependencies if a supported python package format is found |
| `<leader>pd`   | `:PythonDap`               | Create and save a new Dap configuration                                              |
| `<leader>ptt`  | `:PythonTest`              | Run Suite of tests with `neotest`                                                    |
| `<leader>ptm`  | `:PythonTestMethod`        | Run test function/method with `neotest`                                              |
| `<leader>ptf`  | `:PythonTestFile`          | Run test file with `neotest`                                                         |
| `<leader>ppe`  | `:PythonTSToggleEnumerate` | Turn a regular list into `enumerate()` list and back                                 |

## Advanced Commands

| Default KeyMap | Command                   | Functionality                                                           |
| -------------- | ------------------------- | ----------------------------------------------------------------------- |
| `<leader>ped`  | `:PythonVEnvDeleteSelect` | Select a venv to delete from `python.nvim` state                        |
| `<leader>peD`  | `:PythonVEnvDelete`       | Delete current selected venv in project in `python.nvim` state          |
| `<leader>ptdd` | `:PythonDebugTest`        | Run Suite of tests with `neotest` in `dap` mode with `dap-python`       |
| `<leader>ptdm` | `:PythonDebugTestMethod`  | Run test function/method with `neotest` in `dap` mode with `dap-python` |
| `<leader>ptdf` | `:PythonDebugTestFile`    | Run test file with `neotest` in `dap` mode with `dap-python`            |

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

[nvim-puppeteer](https://github.com/chrisgrieser/nvim-puppeteer) for treesitter action on inserting f-strings
