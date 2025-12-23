local PythonTreeSitterNodes = {}

-- part of the code from polarmutex/contextprint.nvim
local api = vim.api
local fn = vim.fn
local get_node_text = vim.treesitter.get_node_text
local parse = vim.treesitter.query.parse

-- Helper function to convert 0-indexed treesitter range to 1-indexed vim range
local function get_vim_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return start_row + 1, start_col + 1, end_row + 1, end_col + 1
end

-- Helper function to recurse through match captures (replaces locals.recurse_local_nodes)
local function recurse_captures(match, query, callback)
  for id, node in pairs(match) do
    local name = query.captures[id]
    if name then
      callback(id, node, name)
    end
  end
end

PythonTreeSitterNodes.count_parents = function(node)
  local count = 0
  local n = node.declaring_node
  while n ~= nil do
    n = n:parent()
    count = count + 1
  end
  return count
end

-- @param nodes Array<node_wrapper>
-- perf note.  I could memoize some values here...
PythonTreeSitterNodes.sort_nodes = function(nodes)
  table.sort(nodes, function(a, b)
    return PythonTreeSitterNodes.count_parents(a) < PythonTreeSitterNodes.count_parents(b)
  end)
  return nodes
end

-- local lang = vim.api.nvim_buf_get_option(bufnr, 'ft')
-- node_wrapper
-- returns [{
--   declaring_node = tsnode
--   dim: {s: {r, c}, e: {r, c}},
--   name: string
--   type: string
-- }]
PythonTreeSitterNodes.get_nodes = function(query, lang, defaults, bufnr)
  if lang ~= "python" then
    return nil
  end
  bufnr = bufnr or 0
  local success, parsed_query = pcall(function()
    return parse(lang, query)
  end)
  if not success then
    vim.notify_once("treesitter parse failed, make sure treesitter installed and setup correctly", vim.log.levels.WARN)
    return nil
  end

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local root = parser:parse()[1]:root()
  local start_row, _, end_row, _ = root:range()
  local results = {}
  for pattern, match, metadata in parsed_query:iter_matches(root, bufnr, start_row, end_row) do
    local sRow, sCol, eRow, eCol
    local declaration_node
    local type = "nil"
    local name = "nil"
    recurse_captures(match, parsed_query, function(_, node, path)
      local idx = string.find(path, ".", 1, true)
      local op = string.sub(path, idx + 1, #path)

      type = string.sub(path, 1, idx - 1)
      if name == nil then
        name = defaults[type] or "empty"
      end

      if op == "name" then
        name = get_node_text(node, bufnr)
      elseif op == "declaration" then
        declaration_node = node
        sRow, sCol, eRow, eCol = get_vim_range(node)
      end
    end)

    if declaration_node ~= nil then
      table.insert(results, {
        declaring_node = declaration_node,
        dim = { s = { r = sRow, c = sCol }, e = { r = eRow, c = eCol } },
        name = name,
        type = type,
      })
    end
  end

  return results
end

local nodes = {}
local nodestime = {}

PythonTreeSitterNodes.get_all_nodes = function(query, lang, defaults, bufnr, pos_row, pos_col, ntype)
  -- ulog(query, lang, defaults, pos_row, pos_col)
  bufnr = bufnr or api.nvim_get_current_buf()
  local key = tostring(bufnr) .. query
  local filetime = fn.getftime(fn.expand("%"))
  if nodes[key] ~= nil and nodestime[key] ~= nil and filetime == nodestime[key] then
    return nodes[key]
  end
  if lang ~= "go" then
    return nil
  end
  -- ulog(bufnr, nodestime[key], filetime)
  -- todo a huge number
  pos_row = pos_row or 30000
  local success, parsed_query = pcall(function()
    return parse(lang, query)
  end)
  if not success then
    -- ulog('failed to parse ts query: ' .. query .. 'for ' .. lang)
    return nil
  end

  local parser = vim.treesitter.get_parser(bufnr, lang)
  local root = parser:parse()[1]:root()
  local start_row, _, end_row, _ = root:range()
  local results = {}
  local node_type
  for pattern, match, metadata in parsed_query:iter_matches(root, bufnr, start_row, end_row) do
    local sRow, sCol, eRow, eCol
    local declaration_node
    local type_node
    local type = ""
    local name = ""
    local op = ""
    -- local method_receiver = ""
    -- ulog(match)

    recurse_captures(match, parsed_query, function(_, node, path)
      -- local idx = string.find(path, ".", 1, true)
      -- The query may return multiple nodes, e.g.
      -- (type_declaration (type_spec name:(type_identifier)@type_decl.name type:(type_identifier)@type_decl.type))@type_decl.declaration
      -- returns { { @type_decl.name, @type_decl.type, @type_decl.declaration} ... }
      local idx = string.find(path, ".[^.]*$") -- find last `.`
      op = string.sub(path, idx + 1, #path)
      local dbg_txt = get_node_text(node, bufnr) or ""
      if #dbg_txt > 100 then
        dbg_txt = string.sub(dbg_txt, 1, 100) .. "..."
      end
      type = string.sub(path, 1, idx - 1) -- e.g. struct.name, type is struct
      if type:find("type") and op == "type" then -- type_declaration.type
        node_type = get_node_text(node, bufnr)
        -- ulog('type: ' .. type)
      end

      -- stylua: ignore
      -- ulog(
      --   "node ", vim.inspect(node), "\n path: " .. path .. " op: " .. op
      --     .. "  type: " .. type .. "\n txt: " .. dbg_txt .. "\n range: " .. tostring(a1 or 0)
      --     .. ":" .. tostring(b1 or 0) .. " TO " .. tostring(c1 or 0) .. ":" .. tostring(d1 or 0)
      -- )
      -- stylua: ignore end
      --
      -- may not handle complex node
      if op == 'name' or op == 'value' or op == 'definition' then
        -- ulog('node name ' .. name)
        name = get_node_text(node, bufnr) or ''
        type_node = node
      elseif op == 'declaration' or op == 'clause' then
        declaration_node = node
        sRow, sCol, eRow, eCol = get_vim_range(node)
      else
        -- ulog('unknown op: ' .. op)
      end
    end)
    if declaration_node ~= nil then
      -- ulog(name .. ' ' .. op, sRow, eRow)
      -- ulog(sRow, pos_row)
      if sRow > pos_row then
        -- ulog(tostring(sRow) .. ' beyond ' .. tostring(pos_row))
      end
      table.insert(results, {
        declaring_node = declaration_node,
        dim = { s = { r = sRow, c = sCol }, e = { r = eRow, c = eCol } },
        name = name,
        operator = op,
        type = node_type or type,
      })
    end
    if type_node ~= nil and ntype then
      -- ulog('type_only')
      sRow, sCol, eRow, eCol = get_vim_range(type_node)
      table.insert(results, {
        type_node = type_node,
        dim = { s = { r = sRow, c = sCol }, e = { r = eRow, c = eCol } },
        name = name,
        operator = op,
        type = type,
      })
    end
  end
  -- ulog('total nodes got: ' .. tostring(#results))
  nodes[key] = results
  nodestime[key] = filetime
  return results
end

PythonTreeSitterNodes.nodes_in_buf = function(query, default, bufnr, row, col)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  if row == nil or col == nil then
    row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row, col = row, col + 1
  end
  local ns = PythonTreeSitterNodes.get_all_nodes(query, ft, default, bufnr, row, col, true)
  if ns == nil then
    -- vim.notify_once('Unable to find any nodes.', vim.log.levels.DEBUG)
    -- ulog('Unable to find any nodes. place your cursor on a go symbol and try again')
    return nil
  end

  return ns
end

PythonTreeSitterNodes.nodes_at_cursor = function(query, default, bufnr, ntype)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row, col = row, col + 1
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "ft")
  if ft ~= "go" then
    return
  end
  local ns = PythonTreeSitterNodes.get_all_nodes(query, ft, default, bufnr, row, col, ntype)
  if ns == nil then
    vim.notify_once("Unable to find any nodes. place your cursor on a go symbol and try again", vim.log.levels.DEBUG)
    -- ulog('Unable to find any nodes. place your cursor on a go symbol and try again')
    return nil
  end
  -- ulog(#ns)
  local nodes_at_cursor = PythonTreeSitterNodes.sort_nodes(PythonTreeSitterNodes.intersect_nodes(ns, row, col))
  if not nodes_at_cursor then
    -- cmp-command-line will causing cursor to move to end of line
    -- lets try move back a bit and try to find nodes again
    row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row, col = row, col - 5
    nodes_at_cursor = PythonTreeSitterNodes.sort_nodes(PythonTreeSitterNodes.intersect_nodes(ns, row, col))
  end
  -- ulog(row, col, vim.inspect(nodes_at_cursor):sub(1, 100))
  if nodes_at_cursor == nil or #nodes_at_cursor == 0 then
    -- if _GO_NVIM_CFG.verbose then
    --   vim.notify_once(
    --     'Unable to find any nodes at pos. ' .. tostring(row) .. ':' .. tostring(col),
    --     vim.log.levels.DEBUG
    --   )
    -- end
    -- ulog('Unable to find any nodes at pos. ' .. tostring(row) .. ':' .. tostring(col))
    return nil
  end

  return nodes_at_cursor
end

function PythonTreeSitterNodes.inside_function()
  local current_node = vim.treesitter.get_node()
  if not current_node then
    return false
  end
  local expr = current_node

  while expr do
    if expr:type() == "function_definition" then
      return true
    end
    expr = expr:parent()
  end
  return false
end

return PythonTreeSitterNodes
