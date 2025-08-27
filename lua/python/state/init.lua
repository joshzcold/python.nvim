local PythonState = {}

---@class PythonStateVEnv
---@field python_interpreter string | nil
---@field venv_path string | nil
---@field install_method string
---@field install_file string
---@field source string
PythonStateVEnv = {}

---@class PythonStateDap
---@field file string
---@field args string[]
PythonStateDap = {}

--[[
Should look like this
{
    venvs(PythonStateVEnv[]) = {
        "/path/to/cwd/directory/of/venv" = {
            python_interpreter = "python3.8.2",
            venv_path = "/path/to/cwd/directory/of/venv/.venv",
            install_method = "pdm" | "requirements.txt" | "dev-requirements.txt",
            install_file = "/path/to/installation/file/requirements.txt",
        },
    },
    dap(PythonStateDap[]) = {
        "/path/to/cwd/directory/of/venv" = {
            file = "program.py",
            args = {"-foo", "bar"}
        },
    }
}

]]
--
---@class PythonState
---@field venvs table<string, PythonStateVEnv>
---@field dap table<string, dap.Configuration>
PythonState = PythonState or {
  venvs = {},
  dap = {},
}

local data_path = vim.fn.stdpath("data")
local state_dir = vim.fs.joinpath(data_path, "python.nvim")
local state_path = vim.fs.joinpath(state_dir, "state.json")

---@return PythonState
function PythonState.State()
  if vim.fn.isdirectory(state_dir) == 0 then
    if vim.fn.mkdir(state_dir, "p") ~= 1 then
      error(string.format("python.nvim: mkdirp error creating directory: %s", state_dir))
    end
  end

  if vim.fn.filereadable(state_path) == 0 then
    vim.fn.writefile({ vim.json.encode(PythonState) }, state_path, "s")
  end

  local state_file_text = ""
  for _, line in pairs(vim.fn.readfile(state_path)) do
    state_file_text = state_file_text .. line .. "\n"
  end

  PythonState = vim.json.decode(state_file_text)
  if PythonState.venvs == nil then
    PythonState.venvs = {}
  end
  if PythonState.dap == nil then
    PythonState.dap = {}
  end
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
function PythonState.save(new_state)
  local result_state = merge_tables(PythonState, new_state)
  vim.fn.writefile({ vim.json.encode(result_state) }, state_path, "s")
end

return PythonState
