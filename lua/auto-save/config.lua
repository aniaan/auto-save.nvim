local M = {}

M.defaults = {
	enabled = false,
	delay = 1000,
	events = { "InsertLeave", "TextChanged" },
	conditions = {
		exists = true,
		modifiable = true,
		modified = true,
	},
	ingore_filetypes = {
		"TelescopePrompt",
		"neo-tree",
		"dashboard",
		"lazy",
		"mason",
		"terminal",
	},

	max_size = 100 * 1024,

	callbacks = {
		before_saving = nil,
		after_saving = nil,
	},
}

return M
