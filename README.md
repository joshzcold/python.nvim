# python.nvim

Python Tools for Neovim

> [!WARNING]
> This plugin is currently in progress and is subject to bugs
> Please file issues when found and feel free to contribute

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
return {
  ---@module 'python'
  {
    "joshzcold/python.nvim",
    ---@type python.Config
    opts = { ---@diagnostic disable-line: missing-fields`
    },
    dependencies = {
      { "mfussenegger/nvim-dap" },
      { "mfussenegger/nvim-dap-python" },
      { "MunifTanjim/nui.nvim" },
      { "neovim/nvim-lspconfig" },
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
    dependencies = {
      { "mfussenegger/nvim-dap" },
      { "mfussenegger/nvim-dap-python" },
      { "neovim/nvim-lspconfig" },
      { "MunifTanjim/nui.nvim" },
      { "L3MON4D3/LuaSnip" }
    },
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

- [ ] Easier setup of python debugging

  - [x] Automatically install debugpy into venv
  - [X] Interactively create a DAP config for a program, saving configuration.

- [ ] Utility features

  - [x] Function to swap type checking mode for pyright, basedpyright
  - [x] Function to launch test method, class, etc. in DAP

- [X] Python Snippets through luasnip

- [ ] Treesitter integration
  - [ ] Functions utilizing treesitter for helpful code actions

## Supported python package managers

| Manager | Install File         | Install Method   |
| ------- | -------------------- | ---------------- |
| pdm     | pdm.lock             | `pdm sync`       |
| pip     | pyproject.toml       | `pip install .`  |
| pip     | dev-requirements.txt | `pip install -r` |
| pip     | requirements.txt     | `pip install -r` |

## Special Thanks

[swenv,nvim](https://github.com/AckslD/swenv.nvim) For almost all of the logic in selecting venvs.
Use this plugin if you want a more simple venv management plugin for your workflow.
