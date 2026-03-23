local WarpMouse             = {}
WarpMouse.__index           = WarpMouse

-- Metadata
WarpMouse.name              = "WarpMouse"
WarpMouse.version           = "0.3"
WarpMouse.author            = "Michael Mogenson"
WarpMouse.homepage          = "https://github.com/mogenson/WarpMouse.spoon"
WarpMouse.license           = "MIT - https://opensource.org/licenses/MIT"

local eventTypes <const>    = hs.eventtap.event.types
local isPointInRect <const> = hs.geometry.isPointInRect
local newMouseEvent <const> = hs.eventtap.event.newMouseEvent
WarpMouse.logger            = hs.logger.new(WarpMouse.name)
WarpMouse.margin            = 2
WarpMouse.y_mapping         = "relative"
WarpMouse.allow_vertical_mouse_crossing = true

-- a global variable that PaperWM can use to disable the eventtap while Mission Control is open
_WarpMouseEventTap          = nil

--- Calculates the relative y position of the cursor on a new screen.
--- @param y number the y position of the cursor on the current screen
--- @param current_frame table the frame of the current screen
--- @param new_frame table the frame of the new screen
--- @return number the y position of the cursor on the new screen
local function relative_y(y, current_frame, new_frame)
    return new_frame.h * (y - current_frame.y) / current_frame.h + new_frame.y
end

--- Calculates the y position of the cursor on a new screen while preserving the
--- offset from the bottom edge. This matches the feel of bottom-aligned side-by-side
--- displays when the physical display arrangement is stacked vertically.
--- @param y number the y position of the cursor on the current screen
--- @param current_frame table the frame of the current screen
--- @param new_frame table the frame of the new screen
--- @return number the y position of the cursor on the new screen
local function bottom_aligned_y(y, current_frame, new_frame)
    return new_frame.y2 - (current_frame.y2 - y)
end

local function map_y(self, y, current_frame, new_frame)
    if self.y_mapping == "bottom" then
        return bottom_aligned_y(y, current_frame, new_frame)
    end

    return relative_y(y, current_frame, new_frame)
end

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end

    return value
end

local function clamp_to_frame(point, frame, margin)
    return {
        x = clamp(point.x, frame.x + margin, frame.x2 - margin),
        y = clamp(point.y, frame.y + margin, frame.y2 - margin),
    }
end

--- Warps the mouse from one position to another.
--- @param from table the position to warp from
--- @param to table the position to warp to
local function warp(from, to)
    _WarpMouseEventTap:stop()
    newMouseEvent(eventTypes.mouseMoved, to):post();
    _WarpMouseEventTap:start()
    if WarpMouse.logger.getLogLevel() < 5 then
        WarpMouse.logger.df("Warping mouse from %s to %s", hs.inspect(from), hs.inspect(to))
    end
end

--- Gets the screen that the cursor is currently on.
--- @param cursor table the position of the cursor
--- @param frames table a list of screen frames
--- @return number the index of the screen that the cursor is on
--- @return table the frame of the screen that the cursor is on
local function get_screen(cursor, frames)
    for index, frame in ipairs(frames) do
        if isPointInRect(cursor, frame) then
            return index, frame
        end
    end
    error("cursor is not in any screen")
end

--- Starts the WarpMouse spoon.
function WarpMouse:start()
    self.screens = hs.screen.allScreens()

    table.sort(self.screens, function(a, b)
        -- sort list by screen postion top to bottom
        return select(2, a:position()) < select(2, b:position())
    end)

    for i, screen in ipairs(self.screens) do
        self.screens[i] = screen:fullFrame()
    end

    self.logger.f("Starting with screens from left to right: %s",
        hs.inspect(self.screens))

    _WarpMouseEventTap = hs.eventtap.new({
        eventTypes.mouseMoved,
        eventTypes.leftMouseDragged,
        eventTypes.rightMouseDragged,
    }, function(event)
        local cursor = event:location()
        local index, frame = get_screen(cursor, self.screens)
        local event_type = event:getType()

        if event_type == eventTypes.mouseMoved
            and not self.allow_vertical_mouse_crossing
            and self.last_index ~= nil
            and self.last_index ~= index
        then
            local previous_frame = self.screens[self.last_index]
            if previous_frame then
                local blocked = clamp_to_frame({
                    x = cursor.x,
                    y = self.last_index < index and (previous_frame.y2 - self.margin) or (previous_frame.y + self.margin),
                }, previous_frame, self.margin)
                self.last_cursor = blocked
                warp(cursor, blocked)
                return
            end
        end

        if cursor.x == frame.x then
            local left_frame = self.screens[index - 1]
            if left_frame then
                local target_y = map_y(self, cursor.y, frame, left_frame)
                if target_y >= left_frame.y and target_y < left_frame.y2 then
                    local target = { x = left_frame.x2 - self.margin, y = target_y }
                    self.last_index = index - 1
                    self.last_cursor = target
                    warp(cursor, target)
                    return
                end
            end
        elseif cursor.x > frame.x2 - 0.5 and cursor.x <= frame.x2 then
            local right_frame = self.screens[index + 1]
            if right_frame then
                local target_y = map_y(self, cursor.y, frame, right_frame)
                if target_y >= right_frame.y and target_y < right_frame.y2 then
                    local target = { x = right_frame.x + self.margin, y = target_y }
                    self.last_index = index + 1
                    self.last_cursor = target
                    warp(cursor, target)
                    return
                end
            end
        end

        self.last_index = index
        self.last_cursor = cursor
    end):start()

    self.screen_watcher = hs.screen.watcher.new(function()
        self.logger.d("Screen layout change")
        self:stop()
        self:start()
    end):start()
end

--- Stops the WarpMouse spoon.
function WarpMouse:stop()
    self.logger.i("Stopping")

    if _WarpMouseEventTap then
        _WarpMouseEventTap:stop()
        _WarpMouseEventTap = nil
    end

    if self.screen_watcher then
        self.screen_watcher:stop()
        self.screen_watcher = nil
    end

    self.screens = nil
    self.last_cursor = nil
    self.last_index = nil
end

return WarpMouse
