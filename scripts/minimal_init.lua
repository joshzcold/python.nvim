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
require("luasnip").setup()
require("luasnip.extras.fmt")
require("luasnip.nodes.absolute_indexer")
require("mini.test").setup()
require("mini.doc").setup()

-- Setup nvim-treesitter
require("nvim-treesitter").install("python")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("PythonTreesitter", { clear = true }),
  pattern = "python",
  desc = "Enable treesitter highlighting and indentation",
  callback = function(event)
    local buf = event.buf

    -- Start highlighting
    pcall(vim.treesitter.start, buf, "python")
  end,
})
