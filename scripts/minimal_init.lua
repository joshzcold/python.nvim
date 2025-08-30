-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

local runtime_dependencies = {
  "deps/mini.nvim",
  "deps/nvim-treesitter",
  "deps/neotest",
  "deps/neotest-python",
  "deps/nvim-dap",
  "deps/nvim-dap-python",
  "deps/nvim-lspconfig",
  "deps/LuaSnip",
}
local runtime_path = vim.fn.join(runtime_dependencies, ",")
vim.cmd("set rtp+=" .. runtime_path)

-- Set up 'mini.test'
require("luasnip.extras.fmt")
require("luasnip.nodes.absolute_indexer")
require("nvim-treesitter.locals")
require("nvim-treesitter").setup()
require("mini.test").setup()
require("mini.doc").setup()
require("nvim-treesitter.configs").setup({
  modules = {
    "highlight",
  },
  sync_install = false,
  auto_install = true,
  ignore_install = {},
  ensure_installed = {
    "python",
  },
  highlight = {
    enable = true,
  },
})
