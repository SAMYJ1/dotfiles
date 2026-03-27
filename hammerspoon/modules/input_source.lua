local util = require("modules.util")

local M = {}

local ghostty_watchers = nil
local shift_input_toggle_watcher = nil
local macism_candidates = {
  "/opt/homebrew/bin/macism",
  "/usr/local/bin/macism",
}
local ghostty_input_enforce_suppressed_until = 0

local function resolve_macism_command()
  for _, candidate in ipairs(macism_candidates) do
    if hs.fs.attributes(candidate) then
      return candidate
    end
  end

  return nil
end

local macism_command = resolve_macism_command()

local function trim(value)
  return value and value:gsub("^%s+", ""):gsub("%s+$", "") or value
end

local function run_macism(args)
  if not macism_command then
    return nil, false
  end

  local command = string.format("%q", macism_command)
  for _, arg in ipairs(args or {}) do
    command = command .. " " .. string.format("%q", arg)
  end

  local output, ok, _, rc = hs.execute(command, false)
  local trimmed_output = trim(output or "")
  local succeeded = ok and rc == 0 and not trimmed_output:match("does not exist!")
  return trimmed_output, succeeded
end

local function current_input_source()
  return run_macism({})
end

local function switch_to_input_source(source_id)
  local _, ok = run_macism({ source_id })
  return ok
end

local function setup_shift_input_toggle()
  local source_groups = {
    english = {
      ids = { "com.apple.keylayout.ABC" },
    },
    chinese = {
      ids = { "com.tencent.inputmethod.wetype.pinyin", "com.apple.inputmethod.SCIM.ITABC" },
    },
  }
  local shift_tap_threshold_nanos = 180000000
  local event_types = hs.eventtap.event.types
  local shift_keycodes = {
    [hs.keycodes.map.shift] = true,
    [hs.keycodes.map.rightshift] = true,
  }

  local active_shift_key_code = nil
  local shift_pressed_at = nil
  local shift_chord_used = false
  local shift_forwarded = false

  local function begin_shift_gesture(key_code, timestamp)
    active_shift_key_code = key_code
    shift_pressed_at = timestamp
    shift_chord_used = false
    shift_forwarded = false
  end

  local function clear_shift_gesture()
    active_shift_key_code = nil
    shift_pressed_at = nil
    shift_chord_used = false
    shift_forwarded = false
  end

  local function ensure_shift_forwarded()
    if active_shift_key_code ~= nil and not shift_forwarded then
      shift_forwarded = true
      return { hs.eventtap.event.newKeyEvent(active_shift_key_code, true) }
    end

    return nil
  end

  local function source_group_for(source_id)
    for group_name, group in pairs(source_groups) do
      for _, candidate_id in ipairs(group.ids) do
        if source_id == candidate_id then
          return group_name
        end
      end
    end

    return nil
  end

  local function switch_to_group(group)
    for _, candidate_id in ipairs(group.ids) do
      if hs.keycodes.currentSourceID(candidate_id) then
        return true
      end
    end

    return false
  end

  local function toggle_input_source()
    local source_id = hs.keycodes.currentSourceID()
    local current_group_name = source_group_for(source_id)
    local next_group = current_group_name == "english" and source_groups.chinese or source_groups.english
    ghostty_input_enforce_suppressed_until = hs.timer.secondsSinceEpoch() + 0.5

    if not switch_to_group(next_group) then
      util.notify("Shift IME toggle failed")
    end
  end

  local watcher = hs.eventtap.new({
    event_types.flagsChanged,
    event_types.keyDown,
    event_types.leftMouseDragged,
    event_types.leftMouseDown,
    event_types.rightMouseDragged,
    event_types.rightMouseDown,
    event_types.otherMouseDragged,
    event_types.otherMouseDown,
    event_types.scrollWheel,
  }, function(event)
    local event_type = event:getType()

    if event_type == event_types.flagsChanged then
      local key_code = event:getKeyCode()

      if shift_keycodes[key_code] then
        local flags = event:getFlags()

        if flags.shift then
          if active_shift_key_code == nil then
            begin_shift_gesture(key_code, event:timestamp())
            return true
          elseif active_shift_key_code ~= key_code then
            shift_chord_used = true
            local synthetic_events = ensure_shift_forwarded()
            return false, synthetic_events
          end

          return true
        elseif active_shift_key_code == key_code and shift_pressed_at then
          local hold_duration = event:timestamp() - shift_pressed_at
          local should_toggle = not shift_chord_used and hold_duration <= shift_tap_threshold_nanos
          local synthetic_events = nil

          if should_toggle then
            hs.timer.doAfter(0, toggle_input_source)
          elseif shift_forwarded then
            synthetic_events = { hs.eventtap.event.newKeyEvent(active_shift_key_code, false) }
          end

          clear_shift_gesture()
          return true, synthetic_events
        elseif active_shift_key_code ~= nil then
          shift_chord_used = true
          local synthetic_events = ensure_shift_forwarded()
          return false, synthetic_events
        end
      elseif active_shift_key_code ~= nil then
        shift_chord_used = true
        local synthetic_events = ensure_shift_forwarded()
        return false, synthetic_events
      end
    elseif active_shift_key_code ~= nil then
      shift_chord_used = true
      local synthetic_events = ensure_shift_forwarded()
      return false, synthetic_events
    end

    return false
  end)

  watcher:start()
  return watcher
end

local function setup_ghostty_input_source_rules()
  local ghostty_bundle_id = "com.mitchellh.ghostty"
  local english_source_ids = { "com.apple.keylayout.ABC" }

  local function switch_to_english()
    for _, source_id in ipairs(english_source_ids) do
      if switch_to_input_source(source_id) then
        return true
      end
    end

    return false
  end

  local function is_ghostty_frontmost()
    local app = hs.application.frontmostApplication()
    return app ~= nil and app:bundleID() == ghostty_bundle_id
  end

  local app_watcher = hs.application.watcher.new(function(_, event_type, app)
    if event_type ~= hs.application.watcher.activated or not app then
      return
    end

    if app:bundleID() ~= ghostty_bundle_id then
      return
    end

    if hs.timer.secondsSinceEpoch() < ghostty_input_enforce_suppressed_until then
      return
    end

    switch_to_english()
  end)

  app_watcher:start()

  return {
    app = app_watcher,
  }
end

function M.setup()
  if not macism_command then
    util.notify("macism not found")
    return nil
  end

  shift_input_toggle_watcher = setup_shift_input_toggle()
  ghostty_watchers = setup_ghostty_input_source_rules()

  return {
    shift = shift_input_toggle_watcher,
    ghostty = ghostty_watchers,
  }
end

return M
