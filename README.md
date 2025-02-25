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

- [X] Switch between virtual envs interactively
- [ ] Interactively create virtual envs and install dependencies
    - [ ] Reload all the common python LSP servers if found to be running
    - [ ] Lot of commands to control venvs
- [ ] Keep track of envs/pythons per project in state
- [ ] Easier setup of python debugging
    - [ ] Automatically install debugpy into venv
    - [ ] Interactively create a DAP config for a program per project

## Special Thanks

[swenv,nvim](https://github.com/AckslD/swenv.nvim) For almost all of the logic in selecting venvs.
Use this plugin if you want a more simple venv management plugin for your workflow.
