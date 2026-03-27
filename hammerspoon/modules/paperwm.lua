local util = require("modules.util")

local M = {}

local paperwm = nil
local paperwm_enabled = false
local warp_mouse = nil

local function is_little_arc_window(window)
	if not window then
		return false
	end

	local ok_app, app = pcall(window.application, window)
	if not ok_app or not app or app:name() ~= "Arc" then
		return false
	end

	local ok_ax, ax_window = pcall(hs.axuielement.windowElement, window)
	if not ok_ax or not ax_window then
		return false
	end

	local identifier = ax_window:attributeValue("AXIdentifier")
	return type(identifier) == "string" and identifier:match("^littleBrowserWindow%-") ~= nil
end

local function wrap_window_filter_for_little_arc(window_filter)
	local original_is_window_allowed = window_filter.isWindowAllowed
	local original_get_windows = window_filter.getWindows
	local original_subscribe = window_filter.subscribe

	function window_filter:isWindowAllowed(window)
		return original_is_window_allowed(self, window) and not is_little_arc_window(window)
	end

	function window_filter:getWindows(sort_order)
		local windows = original_get_windows(self, sort_order)
		return hs.fnutils.filter(windows, function(window)
			return not is_little_arc_window(window)
		end)
	end

	function window_filter:subscribe(event, fn, immediate)
		if type(fn) == "function" then
			local original_fn = fn
			fn = function(window, app_name, triggered_event)
				if is_little_arc_window(window) then
					return
				end

				return original_fn(window, app_name, triggered_event)
			end
		end

		return original_subscribe(self, event, fn, immediate)
	end

	return window_filter
end

local function stop_paperwm(show_notice)
	if paperwm and paperwm_enabled then
		paperwm:stop()
		paperwm_enabled = false
		if show_notice then
			util.notify("PaperWM stopped")
		end
	end
end

local function configure_paperwm()
	if paperwm then
		return paperwm
	end

	local ok, loaded = pcall(hs.loadSpoon, "PaperWM")
	if not ok or not loaded then
		util.notify("PaperWM.spoon failed to load")
		return nil
	end

	loaded.window_gap = { top = 8, bottom = 8, left = 10, right = 10 }
	loaded.screen_margin = 12
	loaded.window_ratios = { 0.4, 0.5, 0.6, 0.7 }
	loaded.center_mouse = false
	loaded.infinite_loop_window = false
	loaded.drag_window = { "alt", "cmd" }
	loaded.lift_window = { "alt", "cmd", "shift" }
	loaded.scroll_window = { "alt", "cmd" }
	loaded.scroll_gain = 6
	loaded.swipe_fingers = 0
	loaded.window_filter = wrap_window_filter_for_little_arc(loaded.window_filter)
	loaded.window_filter:rejectApp("Feishu")
	loaded:bindHotkeys({
		stop_events = { { "alt", "cmd", "shift" }, "q" },
		refresh_windows = { { "alt", "cmd", "shift" }, "r" },
		dump_state = { { "alt", "cmd", "shift" }, "d" },
		toggle_floating = { { "alt" }, "'" },
		focus_floating = { { "alt", "cmd", "shift" }, "f" },
		focus_left = { { "alt", "cmd" }, "h" },
		focus_down = { { "alt", "cmd" }, "j" },
		focus_up = { { "alt", "cmd" }, "k" },
		focus_right = { { "alt", "cmd" }, "l" },
		swap_left = { { "cmd", "shift" }, "h" },
		swap_down = { { "cmd", "shift" }, "j" },
		swap_up = { { "cmd", "shift" }, "k" },
		swap_right = { { "cmd", "shift" }, "l" },
		center_window = { { "alt", "cmd" }, "c" },
		full_width = { { "shift", "cmd" }, "f" },
		cycle_width = { { "shift", "cmd" }, "r" },
		cycle_height = { { "alt", "cmd", "shift" }, "r" },
		reverse_cycle_width = { { "ctrl", "alt", "cmd" }, "r" },
		reverse_cycle_height = { { "ctrl", "alt", "cmd", "shift" }, "r" },
		slurp_in = { { "shift", "cmd" }, "i" },
		barf_out = { { "shift", "cmd" }, "o" },
		split_screen = { { "shift", "cmd" }, "s" },
		switch_space_l = { { "alt", "cmd" }, "," },
		switch_space_r = { { "alt", "cmd" }, "." },
		focus_window_1 = { { "alt" }, "1" },
		focus_window_2 = { { "alt" }, "2" },
		focus_window_3 = { { "alt" }, "3" },
		focus_window_4 = { { "alt" }, "4" },
		focus_window_5 = { { "alt" }, "5" },
		move_window_l = { { "ctrl", "alt", "cmd" }, "left" },
		move_window_r = { { "ctrl", "alt", "cmd" }, "right" },
		move_window_u = { { "ctrl", "alt", "cmd" }, "up" },
		move_window_d = { { "ctrl", "alt", "cmd" }, "down" },
		move_window_1 = { { "alt", "cmd", "shift" }, "1" },
		move_window_2 = { { "alt", "cmd", "shift" }, "2" },
		move_window_3 = { { "alt", "cmd", "shift" }, "3" },
		move_window_4 = { { "alt", "cmd", "shift" }, "4" },
		move_window_5 = { { "alt", "cmd", "shift" }, "5" },
		move_window_6 = { { "alt", "cmd", "shift" }, "6" },
		move_window_7 = { { "alt", "cmd", "shift" }, "7" },
		move_window_8 = { { "alt", "cmd", "shift" }, "8" },
		move_window_9 = { { "alt", "cmd", "shift" }, "9" },
	})

	paperwm = loaded
	return paperwm
end

local function configure_warp_mouse()
	if warp_mouse then
		return warp_mouse
	end

	local ok, loaded = pcall(hs.loadSpoon, "WarpMouse")
	if not ok or not loaded then
		util.notify("WarpMouse.spoon failed to load")
		return nil
	end

	loaded.margin = 8
	loaded.y_mapping = "bottom"
	-- loaded.allow_vertical_mouse_crossing = false
	warp_mouse = loaded
	return warp_mouse
end

local function start_paperwm()
	paperwm = configure_paperwm()
	if not paperwm then
		return
	end

	paperwm:start()
	paperwm_enabled = true

	if hs.spaces.screensHaveSeparateSpaces() then
		util.notify("PaperWM started")
	else
		util.notify("PaperWM started. Enable 'Displays have separate Spaces' before serious testing.")
	end
end

local function toggle_paperwm()
	if paperwm_enabled then
		stop_paperwm(true)
	else
		start_paperwm()
	end
end

local function start_warp_mouse()
	warp_mouse = configure_warp_mouse()
	if warp_mouse then
		warp_mouse:start()
	end
end

function M.setup()
	hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "p", toggle_paperwm)
	start_paperwm()
	start_warp_mouse()
end

return M
