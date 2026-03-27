local M = {}

local function bind_arrow_repeat(key)
  return function()
    hs.eventtap.keyStroke({}, key, 0)
  end
end

function M.setup()
  hs.hotkey.bind({ "alt" }, "h", bind_arrow_repeat("left"), nil, bind_arrow_repeat("left"))
  hs.hotkey.bind({ "alt" }, "j", bind_arrow_repeat("down"), nil, bind_arrow_repeat("down"))
  hs.hotkey.bind({ "alt" }, "k", bind_arrow_repeat("up"), nil, bind_arrow_repeat("up"))
  hs.hotkey.bind({ "alt" }, "l", bind_arrow_repeat("right"), nil, bind_arrow_repeat("right"))
end

return M
