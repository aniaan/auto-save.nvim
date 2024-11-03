local Config = require("auto-save.config")

local M = {}

function M.notify(msg, level)
	vim.notify("AutoSave: " .. msg, level or vim.log.levels.INFO)
end

function M.check_filetype(buf)
	local ft = vim.bo[buf].filetype

	for _, ignored in ipairs(Config.ignore_filetypes) do
		if ft == ignored then
			return false
		end
	end

	return true
end

---@param trigger_events TriggerEvent[]?
M.create_autocmd_for_trigger_events = function(trigger_events, autocmd_opts)
	if trigger_events ~= nil then
		for _, event in pairs(trigger_events) do
			vim.api.nvim_create_autocmd(event, autocmd_opts)
		end
	end
end

return M
