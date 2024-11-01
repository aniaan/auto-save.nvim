---@class Config: Options
local M = {}

---@alias TriggerEvent string

--- @class Options
M.defaults = {
	enabled = false,
	delay = 1000,
	trigger_events = {
		---@type TriggerEvent[]?
		immediate_save = { "BufLeave", "FocusLost" },

		---@type TriggerEvent[]?
		defer_save = { "InsertLeave", "TextChanged" },

		---@type TriggerEvent[]?
		cancel_defered_save = { "InsertEnter" },
	},
	events = { "InsertLeave", "TextChanged" },
	ingore_filetypes = {
		"TelescopePrompt",
		"neo-tree",
		"dashboard",
		"lazy",
		"mason",
		"terminal",
	},

	max_size = 100 * 1024,
}

---@type Options
M.options = {}

---@param opts? Options
function M.setup(opts)
	vim.validate({ opts = { opts, "table", true } })
	M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

---@param opts? Options
function M.override(opts)
	vim.validate({ opts = { opts, "table", true } })
	M.options = vim.tbl_deep_extend("force", M.options, opts)
end

M = setmetatable(M, {
	__index = function(_, key)
		return M.options[key]
	end,
})

return M
