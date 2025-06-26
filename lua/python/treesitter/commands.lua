-- Utility functions and commands utilizing treesitter
local M = {}
local nodes = require('python.treesitter.nodes')
local ts = require('python.treesitter')
local config = require('python.config')

---get node at cursor and validate that the user has at least nvim 0.9
---@return nil|TSNode nil if no node or nvim version too old
local function getNodeAtCursor()
	if vim.treesitter.get_node == nil then
		vim.notify("python.nvim requires at least nvim 0.9.", vim.log.levels.WARN)
		return
	end
	return vim.treesitter.get_node()
end

---@param node TSNode node to start search
---@param node_types table list of node types to look for
---@return nil | TSNode
local function findNodeOfParentsWithType(node, node_types)
	local nodeType = node:type()
	if vim.list_contains(node_types, nodeType) then
		return node
	end
	local parent = node:parent()
	if parent then
		return findNodeOfParentsWithType(parent, node_types)
	end
	return nil
end

---@param node TSNode
---@return string
local function getNodeText(node) return vim.treesitter.get_node_text(node, 0) end

---@param node TSNode
---@param replacementText string
local function replaceNodeText(node, replacementText)
	local startRow, startCol, endRow, endCol = node:range()
	local lines = vim.split(replacementText, "\n")
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

local function get_cursor()
	local cursor = vim.api.nvim_win_get_cursor(0)
	return { row = cursor[1], col = cursor[2] }
end

local function get_visual_from_command()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	vim.print("get_visual_from_command", start_pos, end_pos)
	return { start = { row = start_pos[2], col = start_pos[3] }, ending = { row = end_pos[2], col = end_pos[3] } }
end

local function get_visual_selection()
	local start_pos = vim.fn.getpos(".")
	local end_pos = vim.fn.getpos("v")
	vim.print("get_visual_selection", start_pos, end_pos)
	return { start = { row = start_pos[2], col = start_pos[3] }, ending = { row = end_pos[2], col = end_pos[3] } }
end

---@param subtitute_option nil|string if string then use as substitute
---	otherwise select from config
local function visual_wrap_subsitute_options(subtitute_option)
	-- TODO get selection of actual selected text
	local positions = get_visual_selection()
	local postitions_2 = get_visual_from_command()
	vim.print("positions", positions)
	vim.print("postitions_2", postitions_2)
	local start_pos = positions.start
	local end_pos = positions.ending
	vim.print(start_pos, end_pos)
	local selected_buf_text = vim.api.nvim_buf_get_text(0, start_pos.row, start_pos.col, end_pos.row, end_pos.col, {})
	vim.print(selected_buf_text)
	local node_text = vim.fn.join(selected_buf_text, "\n")
	vim.print(node_text)
	local new_text

	if subtitute_option and subtitute_option ~= "" then
		new_text = subtitute_option:format(node_text)
		local lines = vim.split(new_text, "\n")
		vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, lines)
		return
	end
	vim.ui.select(config.treesitter.functions.wrapper.substitute_options, {
		prompt = ("Wrapping: %s <- with:"):format(node_text),
	}, function(selection)
		if not selection then
			return
		end
		new_text = selection:format(node_text)
		local lines = vim.split(new_text, "\n")
		vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, lines)
		return
	end)
end

---@param subtitute_option nil|string if string then use as substitute
---	otherwise select from config
local function ts_wrap_at_cursor(subtitute_option)
	local m = vim.fn.visualmode() -- detect current mode

	vim.print(m)
	if m == 'v' or m == 'V' or m == '\22' then
		visual_wrap_subsitute_options()
		return
	end

	local node = getNodeAtCursor()
	if not node then return end

	local node_types = config.treesitter.functions.wrapper.find_types
	local find_node = findNodeOfParentsWithType(node, node_types)
	if not find_node then
		vim.notify(("python.nvim: Could not find ts node of type: %s"):format(vim.inspect(node_types)))
		return
	end

	local node_text = getNodeText(find_node)
	local new_text

	if subtitute_option and subtitute_option ~= "" then
		new_text = subtitute_option:format(node_text)
		replaceNodeText(find_node, new_text)
		return
	end
	vim.ui.select(config.treesitter.functions.wrapper.substitute_options, {
		prompt = ("Wrapping: %s <- with:"):format(node_text),
	}, function(selection)
		if not selection then
			return
		end
		new_text = selection:format(node_text)
		replaceNodeText(find_node, new_text)
		return
	end)
end

function M.load_commands()
	vim.api.nvim_create_user_command("PythonTestTSQueries", function()
		ts.test_ts_queries()
	end, {})

	vim.api.nvim_create_user_command("PythonTSToggleEnumerate", function()
		ts_toggle_enumerate()
	end, {})
	vim.api.nvim_create_user_command("PythonTSWrapWithFunc", function(substitute_option)
		ts_wrap_at_cursor(substitute_option.args)
	end, {
		complete = function()
			return config.treesitter.functions.wrapper.substitute_options
		end,
		nargs = "?",
		range = true
	})
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
