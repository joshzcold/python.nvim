-- Utility functions and commands utilizing treesitter
local M = {}
local nodes = require('python.treesitter.nodes')
local ts = require('python.treesitter')

function M.load_commands()
	-- vim.api.nvim_create_user_command("PythonDictToTypedDict", function()
	--   print(nodes.inside_function())
	-- end, {})

	vim.api.nvim_create_user_command("PythonTestTSQueries", function()
		ts.test_ts_queries()
	end, {})
end

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|TSNode nil if no node or nvim version too old
local function getNodeAtCursor()
	if vim.treesitter.get_node == nil then
		vim.notify("python.nvim requires at least nvim 0.9.", vim.log.levels.WARN)
		return
	end
	return vim.treesitter.get_node()
end

---@param node TSNode
---@return string
local function getNodeText(node) return vim.treesitter.get_node_text(node, 0) end

---@param node TSNode
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
	pcall(vim.cmd.undojoin) -- make undos ignore the next change, see #8
	vim.api.nvim_buf_set_text(0, startRow, startCol, endRow, endCol, lines)
end

function M.pythonFStr()
	local maxCharacters = 200 -- safeguard to prevent converting invalid code
	local node = getNodeAtCursor()
	if not node then return end

	local strNode
	if node:type() == "string" then
		strNode = node
	elseif node:type():find("^string_") then
		strNode = node:parent()
	elseif node:type() == "escape_sequence" then
		strNode = node:parent():parent()
	else
		return
	end
	if not strNode then return end
	local text = getNodeText(strNode)

	-- GUARD
	if text == "" then return end                -- don't convert empty strings, user might want to enter sth
	if #text > maxCharacters then return end     -- safeguard on converting invalid code

	local isFString = text:find("^r?f")          -- rf -> raw-formatted-string
	local hasBraces = text:find("{.-[^%d,%s].-}") -- nonRegex-braces, see #12 and #15

	if not isFString and hasBraces then
		text = "f" .. text
		replaceNodeText(strNode, text)
	elseif isFString and not hasBraces then
		text = text:sub(2)
		replaceNodeText(strNode, text)
	end
end

return setmetatable(M, {
	__index = function(_, k)
		return require("python.treesitter.commands")[k]
	end,
})
