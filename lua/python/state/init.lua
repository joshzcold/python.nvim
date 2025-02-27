local M = {}
local data_path = vim.fn.stdpath("data")
M.data_path = data_path

---@class PythonStateVEnv
---@field python_interpreter string
---@field venv_path string
---@field venv_cwd_path string
---@field venv_git_project_path string

---@class PythonState
---@field venvs PythonStateVEnv[]
PythonState = PythonState or {}

local state_dir = vim.fs.joinpath(data_path, "python.nvim")
local state_path = vim.fs.joinpath(state_dir, "state.json")

function M.state()
  if not vim.fn.isdirectory(state_dir) then
    if vim.fn.mkdir(state_dir, "p") ~= 1 then
      error(string.format("python.nvim: mkdirp error creating directory: %s", state_dir))
    end
  end

  if not vim.fn.filereadable(state_path) then
    vim.fn.writefile(vim.json.encode(PythonState), state_path, "s")
  end

  local state_file_text = ""
  for line in vim.fn.readfile(state_path) do
    state_file_text = state_file_text .. line .. "\n"
  end

  PythonState = vim.json.decode(state_file_text)
  return PythonState
end

-- tbl_deep_extend does not work the way you would think
local function merge_table_impl(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k]) == "table" then
        merge_table_impl(t1[k], v)
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
end

local function merge_tables(...)
    local out = {}
    for i = 1, select("#", ...) do
        merge_table_impl(out, select(i, ...))
    end
    return out
end

---@param new_state PythonState
function M.save(new_state)
  local result_state = merge_tables(PythonState, new_state)
  vim.fn.writefile(vim.json.encode(PythonState), state_path, "s")
end

return setmetatable(M, {
  __index = function(_, k)
    return require("python.state")[k]
  end,
})
