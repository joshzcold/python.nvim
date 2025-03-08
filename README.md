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
    "joshzcold/python.nvim"
    opts = {}
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
  - [ ] Automatically install debugpy into venv
  - [ ] Interactively create a DAP config for a program per project

- [ ] Utility features
  - [ ] Function to swap type checking mode for pyright, basedpyright
  - [ ] Function to launch test method, class, etc. in DAP

- [ ] Library of snippets

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
