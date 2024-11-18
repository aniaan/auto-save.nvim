local Config = require("auto-save.config")
local Utils = require("auto-save.utils")
local api = vim.api

local M = {}

local timers = {}

local GROUP_NAME = "AutoSave"

local function clear_timer(buf)
	if timers[buf] then
		timers[buf]:close()
		timers[buf] = nil
	end
end

local function should_save(buf)
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

local function save(buf)
	if not api.nvim_buf_is_loaded(buf) then
		return
	end

	if not vim.bo[buf].modified then
		return
	end

	api.nvim_buf_call(buf, function()
		vim.cmd("silent! write")
	end)
end

local function immediate_save(buf)
	clear_timer(buf)
	save(buf)
end

local function defer_save(buf)
	clear_timer(buf)
	local timer = vim.defer_fn(function()
		save(buf)
		timers[buf] = nil
	end, Config.delay)

	timers[buf] = timer
end

--- @param trigger_notify boolean?
function M.enable(trigger_notify)
	trigger_notify = trigger_notify == nil and true or trigger_notify
	local group = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
	local events = Config.trigger_events
	Config.override({ enabled = true })
	Utils.create_autocmd_for_trigger_events(events.immediate_save, {
		group = group,
		desc = "Immediate save a buffer",
		callback = function(opts)
			if should_save(opts.buf) then
				immediate_save(opts.buf)
			end
		end,
	})

	Utils.create_autocmd_for_trigger_events(events.defer_save, {
		group = group,
		desc = "Defer save a buffer",
		callback = function(opts)
			if should_save(opts.buf) then
				defer_save(opts.buf)
			end
		end,
	})

	Utils.create_autocmd_for_trigger_events(events.cancel_defered_save, {
		group = group,
		desc = "Cancel defer save a buffer",
		callback = function(opts)
			if should_save(opts.buf) then
				clear_timer(opts.buf)
			end
		end,
	})

	if trigger_notify then
		Utils.notify("AutoSave enabled")
	end
end

--- @param trigger_notify boolean?
function M.disable(trigger_notify)
	trigger_notify = trigger_notify == nil and true or trigger_notify
	for buf, _ in pairs(timers) do
		clear_timer(buf)
	end
	vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
	Config.override({ enabled = false })

	if trigger_notify then
		Utils.notify("AutoSave disable")
	end
end

function M.toggle()
	if Config.enabled then
		M.disable()
	else
		M.enable()
	end
end

---@param opts? Options
function M.setup(opts)
	Config.setup(opts)

	vim.api.nvim_create_user_command("AutoSaveToggle", M.toggle, {})
	vim.api.nvim_create_user_command("AutoSaveEnable", M.enable, {})
	vim.api.nvim_create_user_command("AutoSaveDisable", M.disable, {})

	if Config.keymaps.toggle then
		vim.keymap.set("n", Config.keymaps.toggle, M.toggle, {
			desc = "Toggle auto save",
			silent = true,
		})
	end

	if Config.keymaps.enable then
		vim.keymap.set("n", Config.keymaps.enable, M.enable, {
			desc = "Enable auto save",
			silent = true,
		})
	end

	if Config.keymaps.disable then
		vim.keymap.set("n", Config.keymaps.disable, M.disable, {
			desc = "Disable auto save",
			silent = true,
		})
	end

	if Config.enabled then
		M.enable(false)
	else
		M.disable(false)
	end
end

return M
