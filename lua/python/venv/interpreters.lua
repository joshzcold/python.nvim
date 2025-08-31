local PythonVENVInterpreters = {}
local IS_WINDOWS = vim.uv.os_uname().sysname == "Windows_NT"
local IS_MACOS = vim.uv.os_uname().sysname == "Darwin"

---
---@return table found_hatch_pythons list of python interpreters found by hatch
function PythonVENVInterpreters.hatch_interpreters()
  if vim.fn.executable("hatch") == 1 then
    local hatch_python_paths = vim.fn.expand("~/.local/share/hatch/pythons")
    if vim.fn.isdirectory(hatch_python_paths) then
      local found_hatch_pythons =
        vim.fn.globpath(hatch_python_paths, vim.fs.joinpath("**", "bin", "python3.*"), false, true)
      if found_hatch_pythons then
        return found_hatch_pythons
      end
    end
  end
  return {}
end

---
---@return table found_uv_pythons list of python interpreters found by uv
function PythonVENVInterpreters.uv_interpreters()
  if vim.fn.executable("uv") == 1 then
    local uv_python_paths = vim.fn.expand("~/.local/share/uv/python")
    if vim.fn.isdirectory(uv_python_paths) then
      local found_uv_pythons = vim.fn.globpath(uv_python_paths, vim.fs.joinpath("**", "bin", "python3.*"), false, true)
      if found_uv_pythons then
        return found_uv_pythons
      end
    end
  end
  return {}
end

---@return table<string> list of potential python interpreters to use
function PythonVENVInterpreters.python_interpreters()
  -- TODO detect python interpreters from windows
  if IS_WINDOWS then
    return { "python3" }
  end
  local pythons = vim.fn.globpath("/usr/bin/", "python3.*", false, true)

  if IS_MACOS then
    local homebrew_path = vim.fn.globpath("/opt/homebrew/bin/", "python3.*", false, true)
    for _, p in pairs(homebrew_path) do
      table.insert(pythons, 1, p)
    end
  end
  local found_uv = PythonVENVInterpreters.uv_interpreters()
  if found_uv then
    for _, p in pairs(found_uv) do
      table.insert(pythons, 1, p)
    end
  end
  local found_hatch = PythonVENVInterpreters.hatch_interpreters()
  if found_hatch then
    for _, p in pairs(found_hatch) do
      table.insert(pythons, 1, p)
    end
  end
  local interpreters = nil
  for _, p in pairs(pythons) do
    if not interpreters then
      interpreters = {}
    end
    if string.match(vim.fs.basename(p), "python3.%d+$") then
      table.insert(interpreters, 1, p)
    end
  end
  if not interpreters then
    vim.notify_once(
      "python.nvim: Warning could not detect python interpreters. Defaulting to python3",
      vim.log.levels.WARN
    )
    interpreters = { "python3" }
  end
  return interpreters
end

return PythonVENVInterpreters
