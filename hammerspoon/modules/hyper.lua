local M = {}

local HYPER_MODS = { "cmd", "ctrl", "alt" }
local TAP_THRESHOLD_NS = 150000000 -- 150ms

local hyper_watcher = nil

local function has_all_hyper_flags(event)
  local flags = event:getFlags()
  return flags.cmd and flags.ctrl and flags.alt
end

local function setup_hyper_eventtap(action_map)
  local escape_keycode = hs.keycodes.map.escape
  local event_types = hs.eventtap.event.types

  local escape_down = false
  local escape_pressed_at = nil
  local chord_used = false
  local passthrough_mode = false

  local function clear_state()
    escape_down = false
    escape_pressed_at = nil
    chord_used = false
  end

  local watcher = hs.eventtap.new({
    event_types.keyDown,
    event_types.keyUp,
    event_types.flagsChanged,
    event_types.leftMouseDown,
    event_types.rightMouseDown,
    event_types.otherMouseDown,
    event_types.leftMouseDragged,
    event_types.rightMouseDragged,
    event_types.otherMouseDragged,
    event_types.scrollWheel,
  }, function(event)
    local event_type = event:getType()
    local key_code = event:getKeyCode()

    -- Passthrough mode: let synthetic Escape events through
    if passthrough_mode then
      if event_type == event_types.keyUp and key_code == escape_keycode then
        passthrough_mode = false
      end
      return false
    end

    -- Escape keyDown: begin tracking
    if event_type == event_types.keyDown and key_code == escape_keycode then
      if not escape_down then
        escape_down = true
        escape_pressed_at = event:timestamp()
        chord_used = false
      end
      return true
    end

    -- Escape keyUp: decide tap vs hold
    if event_type == event_types.keyUp and key_code == escape_keycode then
      if escape_down then
        if not chord_used and escape_pressed_at then
          local duration = event:timestamp() - escape_pressed_at
          if duration < TAP_THRESHOLD_NS then
            clear_state()
            hs.timer.doAfter(0, function()
              passthrough_mode = true
              hs.eventtap.event.newKeyEvent({}, escape_keycode, true):post()
              hs.eventtap.event.newKeyEvent({}, escape_keycode, false):post()
            end)
            return true
          end
        end
        clear_state()
        return true
      end
      return false
    end

    -- Other keyDown while escape is held
    if event_type == event_types.keyDown and escape_down then
      if has_all_hyper_flags(event) then
        return false
      end
      chord_used = true
      local action = action_map[key_code]
      if type(action) == "table" then
        return true, {
          hs.eventtap.event.newKeyEvent(action.mods, action.keycode, true),
        }
      elseif type(action) == "function" then
        action()
        return true
      end
      return true, {
        hs.eventtap.event.newKeyEvent(HYPER_MODS, key_code, true),
      }
    end

    -- Other keyUp while escape is held and chord was used
    if event_type == event_types.keyUp and escape_down and chord_used then
      if has_all_hyper_flags(event) then
        return false
      end
      if action_map[key_code] then
        local action = action_map[key_code]
        if type(action) == "table" then
          return true, {
            hs.eventtap.event.newKeyEvent(action.mods, action.keycode, false),
          }
        end
        return true
      end
      return true, {
        hs.eventtap.event.newKeyEvent(HYPER_MODS, key_code, false),
      }
    end

    -- flagsChanged while escape is held: mark chord
    if event_type == event_types.flagsChanged and escape_down then
      chord_used = true
      return false
    end

    -- Mouse events while escape is held: mark chord
    if escape_down then
      chord_used = true
      return false
    end

    return false
  end)

  watcher:start()
  return watcher
end

function M.setup(action_map)
  hyper_watcher = setup_hyper_eventtap(action_map or {})

  return {
    watcher = hyper_watcher,
  }
end

return M
