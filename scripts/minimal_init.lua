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
  ensure_installed = {},
  highlight = {
    enable = true,
  },
})

-- Clean path for use in a prefix comparison
---@param input string
---@return string
local function clean_path(input)
  local pth = vim.fn.fnamemodify(input, ":p")
  if vim.fn.has("win32") == 1 then
    pth = pth:gsub("/", "\\")
  end
  return pth
end

local function ts_is_installed(lang)
  local matched_parsers = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", true) or {}
  local configs = require("nvim-treesitter.configs")
  local install_dir = configs.get_parser_install_dir()
  if not install_dir then
    return false
  end
  install_dir = clean_path(install_dir)
  for _, path in ipairs(matched_parsers) do
    local abspath = clean_path(path)
    if vim.startswith(abspath, install_dir) then
      return true
    end
  end
  return false
end

if not ts_is_installed("python") then
  vim.cmd("TSInstallSync python")
end
