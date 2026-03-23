local function bindArrowRepeat(key)
	return function()
		hs.eventtap.keyStroke({}, key, 0)
	end
end

hs.hotkey.bind({ "alt" }, "h", bindArrowRepeat("left"), nil, bindArrowRepeat("left"))
hs.hotkey.bind({ "alt" }, "j", bindArrowRepeat("down"), nil, bindArrowRepeat("down"))
hs.hotkey.bind({ "alt" }, "k", bindArrowRepeat("up"), nil, bindArrowRepeat("up"))
hs.hotkey.bind({ "alt" }, "l", bindArrowRepeat("right"), nil, bindArrowRepeat("right"))

local paperwm = nil
local paperwmEnabled = false
local warpMouse = nil

local function notify(message)
	hs.alert.show(message, 1.5)
end

local function isLittleArcWindow(window)
	if not window then
		return false
	end

	local okApp, app = pcall(window.application, window)
	if not okApp or not app or app:name() ~= "Arc" then
		return false
	end

	local okAX, axWindow = pcall(hs.axuielement.windowElement, window)
	if not okAX or not axWindow then
		return false
	end

	local identifier = axWindow:attributeValue("AXIdentifier")
	return type(identifier) == "string" and identifier:match("^littleBrowserWindow%-") ~= nil
end

local function wrapWindowFilterForLittleArc(windowFilter)
	local originalIsWindowAllowed = windowFilter.isWindowAllowed
	local originalGetWindows = windowFilter.getWindows
	local originalSubscribe = windowFilter.subscribe

	function windowFilter:isWindowAllowed(window)
		return originalIsWindowAllowed(self, window) and not isLittleArcWindow(window)
	end

	function windowFilter:getWindows(sortOrder)
		local windows = originalGetWindows(self, sortOrder)
		return hs.fnutils.filter(windows, function(window)
			return not isLittleArcWindow(window)
		end)
	end

	function windowFilter:subscribe(event, fn, immediate)
		if type(fn) == "function" then
			local originalFn = fn
			fn = function(window, appName, triggeredEvent)
				if isLittleArcWindow(window) then
					return
				end

				return originalFn(window, appName, triggeredEvent)
			end
		end

		return originalSubscribe(self, event, fn, immediate)
	end

	return windowFilter
end

local function stopPaperWM(showNotice)
	if paperwm and paperwmEnabled then
		paperwm:stop()
		paperwmEnabled = false
		if showNotice then
			notify("PaperWM stopped")
		end
	end
end

local function configurePaperWM()
	if paperwm then
		return paperwm
	end

	local ok, loaded = pcall(hs.loadSpoon, "PaperWM")
	if not ok or not loaded then
		notify("PaperWM.spoon failed to load")
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
	loaded.window_filter = wrapWindowFilterForLittleArc(loaded.window_filter)
	loaded.window_filter:rejectApp("Feishu")
	loaded:bindHotkeys({
		stop_events = { { "alt", "cmd", "shift" }, "q" },
		refresh_windows = { { "alt", "cmd", "shift" }, "r" },
		dump_state = { { "alt", "cmd", "shift" }, "d" },
		toggle_floating = { { "alt" }, "'" },
		focus_floating = { { "alt", "cmd", "shift" }, "f" },

		-- Keep Option+h/j/k/l for plain arrow behavior; use Option+Command+h/j/k/l for PaperWM focus.
		focus_left = { { "alt", "cmd" }, "h" },
		focus_down = { { "alt", "cmd" }, "j" },
		focus_up = { { "alt", "cmd" }, "k" },
		focus_right = { { "alt", "cmd" }, "l" },
		swap_left = { { "alt", "cmd", "shift" }, "h" },
		swap_down = { { "alt", "cmd", "shift" }, "j" },
		swap_up = { { "alt", "cmd", "shift" }, "k" },
		swap_right = { { "alt", "cmd", "shift" }, "l" },

		center_window = { { "alt", "cmd" }, "c" },
		full_width = { { "alt", "cmd" }, "f" },
		cycle_width = { { "alt", "cmd" }, "r" },
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
		focus_window_6 = { { "alt" }, "6" },
		focus_window_7 = { { "alt" }, "7" },
		focus_window_8 = { { "alt" }, "8" },
		focus_window_9 = { { "alt" }, "9" },

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

local function configureWarpMouse()
	if warpMouse then
		return warpMouse
	end

	local ok, loaded = pcall(hs.loadSpoon, "WarpMouse")
	if not ok or not loaded then
		notify("WarpMouse.spoon failed to load")
		return nil
	end

	loaded.margin = 8
	loaded.y_mapping = "bottom"
	loaded.allow_vertical_mouse_crossing = false
	warpMouse = loaded
	return warpMouse
end

local function startPaperWM()
	paperwm = configurePaperWM()
	if not paperwm then
		return
	end

	paperwm:start()
	paperwmEnabled = true

	if hs.spaces.screensHaveSeparateSpaces() then
		notify("PaperWM started")
	else
		notify("PaperWM started. Enable 'Displays have separate Spaces' before serious testing.")
	end
end

local function togglePaperWM()
	if paperwmEnabled then
		stopPaperWM(true)
	else
		startPaperWM()
	end
end

local function startWarpMouse()
	warpMouse = configureWarpMouse()
	if warpMouse then
		warpMouse:start()
	end
end

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "p", togglePaperWM)
startPaperWM()
startWarpMouse()

local function setupShiftInputToggle()
	local sourceGroups = {
		english = {
			ids = { "com.apple.keylayout.US", "com.apple.keylayout.ABC" },
		},
		chinese = {
			ids = { "com.tencent.inputmethod.wetype.pinyin", "com.apple.inputmethod.SCIM.ITABC" },
		},
	}
	local shiftTapThresholdNanos = 180000000
	local eventTypes = hs.eventtap.event.types
	local shiftKeycodes = {
		[hs.keycodes.map.shift] = true,
		[hs.keycodes.map.rightshift] = true,
	}

	local activeShiftKeyCode = nil
	local shiftPressedAt = nil
	local shiftChordUsed = false
	local shiftForwarded = false

	local function beginShiftGesture(keyCode, timestamp)
		activeShiftKeyCode = keyCode
		shiftPressedAt = timestamp
		shiftChordUsed = false
		shiftForwarded = false
	end

	local function clearShiftGesture()
		activeShiftKeyCode = nil
		shiftPressedAt = nil
		shiftChordUsed = false
		shiftForwarded = false
	end

	local function ensureShiftForwarded()
		if activeShiftKeyCode ~= nil and not shiftForwarded then
			shiftForwarded = true
			return { hs.eventtap.event.newKeyEvent(activeShiftKeyCode, true) }
		end

		return nil
	end

	local function sourceGroupFor(sourceID)
		for groupName, group in pairs(sourceGroups) do
			for _, candidateID in ipairs(group.ids) do
				if sourceID == candidateID then
					return groupName
				end
			end
		end

		return nil
	end

	local function switchToGroup(group)
		for _, candidateID in ipairs(group.ids) do
			if hs.keycodes.currentSourceID(candidateID) then
				return true
			end
		end

		return false
	end

	local function toggleInputSource()
		local currentGroupName = sourceGroupFor(hs.keycodes.currentSourceID())
		local nextGroup = currentGroupName == "english" and sourceGroups.chinese or sourceGroups.english

		if not switchToGroup(nextGroup) then
			notify("Shift IME toggle failed")
		end
	end

	-- Decide on release based on hold time and whether Shift participated in another gesture.
	local watcher = hs.eventtap.new({
		eventTypes.flagsChanged,
		eventTypes.keyDown,
		eventTypes.leftMouseDragged,
		eventTypes.leftMouseDown,
		eventTypes.rightMouseDragged,
		eventTypes.rightMouseDown,
		eventTypes.otherMouseDragged,
		eventTypes.otherMouseDown,
		eventTypes.scrollWheel,
	}, function(event)
		local eventType = event:getType()

		if eventType == eventTypes.flagsChanged then
			local keyCode = event:getKeyCode()

			if shiftKeycodes[keyCode] then
				local flags = event:getFlags()

				if flags.shift then
					if activeShiftKeyCode == nil then
						beginShiftGesture(keyCode, event:timestamp())
						return true
					elseif activeShiftKeyCode ~= keyCode then
						shiftChordUsed = true
						local syntheticEvents = ensureShiftForwarded()
						return false, syntheticEvents
					end

					return true
				elseif activeShiftKeyCode == keyCode and shiftPressedAt then
					local holdDuration = event:timestamp() - shiftPressedAt
					local shouldToggle = not shiftChordUsed and holdDuration <= shiftTapThresholdNanos
					local syntheticEvents = nil

					if shouldToggle then
						toggleInputSource()
					elseif shiftForwarded then
						syntheticEvents = { hs.eventtap.event.newKeyEvent(activeShiftKeyCode, false) }
					end

					clearShiftGesture()
					return true, syntheticEvents
				elseif activeShiftKeyCode ~= nil then
					shiftChordUsed = true
					local syntheticEvents = ensureShiftForwarded()
					return false, syntheticEvents
				end
			elseif activeShiftKeyCode ~= nil then
				shiftChordUsed = true
				local syntheticEvents = ensureShiftForwarded()
				return false, syntheticEvents
			end
		elseif activeShiftKeyCode ~= nil then
			shiftChordUsed = true
			local syntheticEvents = ensureShiftForwarded()
			return false, syntheticEvents
		end

		return false
	end)

	watcher:start()
	return watcher
end

ShiftInputToggleWatcher = setupShiftInputToggle()
