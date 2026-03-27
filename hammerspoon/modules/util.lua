local M = {}

function M.notify(message)
  hs.alert.show(message, 1.5)
end

return M
