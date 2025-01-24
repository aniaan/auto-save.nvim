local api = vim.api

local M = {}
M.did_setup = false

M.config = {
	enabled = false,
	delay = 1000,
	keymaps = {
		toggle = "<leader>fat",
		enable = "<leader>fae",
		disable = "<leader>fad",
	},
	events = {
		immediate_save = { "BufLeave", "FocusLost" },
		defer_save = { "InsertLeave", "TextChanged" },
		cancel_deferred_save = { "InsertEnter" },
	},
}

local H = {}
H.enabled = false
H.notify = false
H.default_config = vim.deepcopy(M.config)

local timers = {}
local GROUP_NAME = "AutoSave"

H.clear_timer = function(buf)
	if timers[buf] then
		timers[buf]:close()
		timers[buf] = nil
	end
end

H.should_save = function(buf)
	if not api.nvim_buf_is_valid(buf) then
		return false
	end

	local filename = api.nvim_buf_get_name(buf)
	local buftype = vim.bo[buf].buftype

	if buftype ~= "" or filename == "" then
		return false
	end

	if not vim.bo[buf].modifiable or not vim.bo[buf].modified then
		return false
	end

	return true
end

H.save = vim.schedule_wrap(function(buf)
	if not api.nvim_buf_is_loaded(buf) then
		return
	end

	if not vim.bo[buf].modified then
		return
	end

	api.nvim_buf_call(buf, function()
		vim.cmd("silent! write")
	end)
end)

H.immediate_save = function(buf)
	H.clear_timer(buf)
	H.save(buf)
end

H.defer_save = function(buf)
	H.clear_timer(buf)
	local timer = vim.defer_fn(function()
		H.save(buf)
		timers[buf] = nil
	end, M.config.delay)

	timers[buf] = timer
end

H.create_autocommands = function()
	local gr = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

	local au = function(events, save_func, desc)
		if events ~= nil then
			for _, event in pairs(events) do
				vim.api.nvim_create_autocmd(event, {
					group = gr,
					callback = function(opts)
						if H.should_save(opts.buf) then
							save_func(opts.buf)
						end
					end,
					desc = desc,
				})
			end
		end
	end

	au(M.config.events.immediate_save, H.immediate_save, "Immediate save a buffer")
	au(M.config.events.defer_save, H.defer_save, "Defer save a buffer")
	au(M.config.events.cancel_deferred_save, H.clear_timer, "Cancel defer save a buffer")
	au({ "BufUnload", "BufDelete" }, function(opts)
		H.clear_timer(opts.buf)
	end, "Clear timer on buffer unload")
end

H.clear_autocommands = function()
	vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
end

H.clear_timers = function()
	for buf, _ in pairs(timers) do
		H.clear_timer(buf)
	end
end

H.setup_config = function(config)
	vim.validate({ config = { config, "table", true } })
	config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})
	return config
end

H.apply_config = function(config)
	M.config = config
	H.enabled = config.enabled
end

H.set_keymap = function()
	local keymaps = M.config.keymaps
	vim.keymap.set("n", keymaps.toggle, M.toggle, { noremap = true, silent = true, desc = "Toggle AutoSave" })
	vim.keymap.set("n", keymaps.enable, M.enable, { noremap = true, silent = true, desc = "Enable AutoSave" })
	vim.keymap.set("n", keymaps.disable, M.disable, { noremap = true, silent = true, desc = "Disable AutoSave" })
end

M.enable = function()
	H.enabled = true
	H.create_autocommands()
	if H.notify then
		vim.notify("AutoSave enabled ")
	end
end

M.disable = function()
	H.clear_autocommands()
	H.clear_timers()
	H.enabled = false
	if H.notify then
		vim.notify("AutoSave disabled")
	end
end

M.toggle = function()
	if H.enabled then
		M.disable()
	else
		M.enable()
	end
end

M.setup = function(config)
	if M.did_setup then
		return
	end
	config = H.setup_config(config)
	H.apply_config(config)
	H.set_keymap()
	M.did_setup = true

	if M.config.enabled then
		M.enable()
	end

	H.notify = true
end

return M
