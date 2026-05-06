local tmux = require("modules.hyper.tmux")

local TERMINAL_BUNDLE_IDS = {
	["com.mitchellh.ghostty"] = true,
	["com.apple.Terminal"] = true,
	["net.kovidgoyal.kitty"] = true,
}

local function is_terminal_focused()
	local app = hs.application.frontmostApplication()
	return app ~= nil and TERMINAL_BUNDLE_IDS[app:bundleID()] == true
end

local function terminal_only(action)
	if type(action) == "function" then
		return function()
			if not is_terminal_focused() then
				return
			end
			action()
		end
	end
	return action
end

local M = {}

M.map = {
	[hs.keycodes.map.h] = terminal_only(tmux.switch_window("previous-window")),
	[hs.keycodes.map.l] = terminal_only(tmux.switch_window("next-window")),
	[hs.keycodes.map.j] = terminal_only(tmux.switch_session("-n")),
	[hs.keycodes.map.k] = terminal_only(tmux.switch_session("-p")),
}

return M
