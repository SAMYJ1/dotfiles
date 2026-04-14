local function load_local_configs()
  local local_dir = hs.configdir .. "/local"
  local attributes = hs.fs.attributes(local_dir)

  if not attributes or attributes.mode ~= "directory" then
    return
  end

  local files = {}
  for entry in hs.fs.dir(local_dir) do
    if entry ~= "." and entry ~= ".." and entry:match("%.lua$") then
      table.insert(files, entry)
    end
  end

  table.sort(files)

  for _, file in ipairs(files) do
    local path = string.format("%s/%s", local_dir, file)
    local ok, err = xpcall(function()
      dofile(path)
    end, debug.traceback)

    if not ok then
      hs.printf("Failed to load local Hammerspoon config %s: %s", file, err)
    end
  end
end

require("hs.ipc")
require("modules.keymaps").setup()
require("modules.hyper").setup()
require("modules.paperwm").setup()
require("modules.input_source").setup()

load_local_configs()
