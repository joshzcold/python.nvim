-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  -- Add 'mini.nvim' to 'runtimepath' to be able to use 'mini.test'
  -- Assumed that 'mini.nvim' is stored in 'deps/mini.nvim'
  --
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
  require("mini.test").setup()
  require("mini.doc").setup()
end
