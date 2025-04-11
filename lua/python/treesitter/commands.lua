-- Utility functions and commands utilizing treesitter
local M = {}
local nodes = require('python.treesitter.nodes')
local ts = require('python.treesitter')

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

local function ts_toggle_enumerate()
	local node = getNodeAtCursor()
	if not node then return end

	local listNode
	if node:type() == "for_statement" then
		listNode = node
	elseif node:type() == "indentifier" or node:type() == "pattern_list" then
		listNode = node:parent()
	else
		vim.notify_once("python.nvim: Treesitter, not on a python list", vim.log.levels.WARN)
		return
	end

	if not listNode then return end
	local left = listNode:field("left")[1]
	local right = listNode:field("right")[1]
	if not left or not right then
		return
	end
	local left_text = getNodeText(left)
	local right_text = getNodeText(right)
	if not left_text or not right_text then
		return
	end

	local left_items = vim.split(left_text, ",", { trimempty = true })
	local is_enumerate = string.match(right_text, "^enumerate.+")

	if #left_items == 1 and not is_enumerate then
		left_text = ("idx, %s"):format(left_text)
		right_text = ("enumerate(%s)"):format(right_text)

		replaceNodeText(right, right_text)
		replaceNodeText(left, left_text)
	elseif #left_items > 1 and is_enumerate then
		local right_text_match = string.match(right_text, [[^enumerate%W(.+)%W]])
		right_text = right_text_match
		print(right_text)
		replaceNodeText(right, right_text)

		left_text = left_items[2]
		left_text = left_text:gsub("%s+", "")
		replaceNodeText(left, left_text)
	end
end

function M.load_commands()
	vim.api.nvim_create_user_command("PythonTestTSQueries", function()
		ts.test_ts_queries()
	end, {})

	vim.api.nvim_create_user_command("PythonTSToggleEnumerate", function()
		ts_toggle_enumerate()
	end, {})
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
