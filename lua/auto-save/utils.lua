local M = {}

function M.notify(msg, level)
	vim.notify("AutoSave: " .. msg, level or vim.log.levels.INFO)
end

function M.check_file_size(filename)
	local size = vim.fn.getfsize(filename)
	if size == -2 then
		return false, "File does not exist"
	elseif size == -1 then
		return false, "Cannot read file size"
	elseif size > vim.b.auto_save_config.max_size then
		return false, "File too large"
	end

	return true
end
