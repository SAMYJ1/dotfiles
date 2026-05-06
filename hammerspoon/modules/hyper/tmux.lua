local TMUX = "/opt/homebrew/bin/tmux"

local overlay_canvas = nil
local overlay_timer = nil
local MARGIN_X = 12
local MARGIN_Y = 24
local PADDING = 12
local DISMISS_SEC = 1.5

local function get_client()
	return hs.execute(TMUX .. " list-clients -F '#{client_name}' | head -1", false):gsub("%s+$", "")
end

local function hide_overlay()
	if overlay_canvas then
		overlay_canvas:delete()
		overlay_canvas = nil
	end
	if overlay_timer then
		overlay_timer:stop()
		overlay_timer = nil
	end
end

local function show_session_overlay()
	hide_overlay()

	local client = get_client()
	if client == "" then
		return
	end

	local sessions_raw = hs.execute(TMUX .. " list-sessions -F '#{session_name}'", false):gsub("%s+$", "")
	local current = hs.execute(TMUX .. " display-message -t " .. client .. " -p '#S'", false):gsub("%s+$", "")
	if sessions_raw == "" then
		return
	end

	local highlight = { red = 0.537, green = 0.706, blue = 0.984, alpha = 1 }
	local normal = { red = 0.67, green = 0.67, blue = 0.67, alpha = 1 }
	local bold_font = { name = "Menlo-Bold", size = 14 }
	local normal_font = { name = "Menlo", size = 14 }

	local parts = {}
	for name in sessions_raw:gmatch("[^\n]+") do
		if name == current then
			table.insert(parts, hs.styledtext.new("▸ " .. name, { color = highlight, font = bold_font }))
		else
			table.insert(parts, hs.styledtext.new("  " .. name, { color = normal, font = normal_font }))
		end
	end

	local styled = parts[1]
	for i = 2, #parts do
		styled = styled .. hs.styledtext.new("\n") .. parts[i]
	end

	local text_size = hs.drawing.getTextDrawingSize(styled)
	local w = math.ceil(text_size.w) + PADDING * 2
	local h = math.ceil(text_size.h) + PADDING * 2

	local win = hs.window.focusedWindow()
	local anchor = win and win:frame() or hs.screen.mainScreen():frame()
	local x = anchor.x + MARGIN_X
	local y = anchor.y + MARGIN_Y

	overlay_canvas = hs.canvas.new({ x = x, y = y, w = w, h = h })
	overlay_canvas:appendElements({
		type = "rectangle",
		fillColor = { red = 0.12, green = 0.12, blue = 0.14, alpha = 1 },
		strokeColor = { alpha = 0 },
		roundedRectRadii = { xRadius = 10, yRadius = 10 },
	}, {
		type = "text",
		text = styled,
		frame = {
			x = PADDING,
			y = PADDING,
			w = math.ceil(text_size.w),
			h = math.ceil(text_size.h),
		},
	})
	overlay_canvas:level(hs.canvas.windowLevels.overlay)
	overlay_canvas:behavior({ hs.canvas.windowBehaviors.canJoinAllSpaces, hs.canvas.windowBehaviors.stationary })
	overlay_canvas:clickActivating(false)
	overlay_canvas:alpha(0.9)
	overlay_canvas:show()

	overlay_timer = hs.timer.doAfter(DISMISS_SEC, hide_overlay)
end

local function switch_window(cmd)
	return function()
		local args = {}
		for w in cmd:gmatch("%S+") do
			table.insert(args, w)
		end
		hs.task.new(TMUX, nil, args):start()
	end
end

local function switch_session(direction_flag)
	return function()
		local client = get_client()
		if client == "" then
			return
		end
		hs.execute(TMUX .. " switch-client -t " .. client .. " " .. direction_flag, false)
		show_session_overlay()
	end
end

return {
	switch_window = switch_window,
	switch_session = switch_session,
}