return {
  {
    "LunarVim/bigfile.nvim",
    event = "VimEnter",
    opts = {
      pattern = function(buf, filesize)
        buf = buf or vim.api.nvim_get_current_buf()
        local ok, stats = pcall(function()
          return vim.loop.fs_stat(vim.api.nvim_buf_get_name(buf))
        end)
        if not (ok and stats) then
          return
        end
        if stats.size / 1024 > 200 then
          return true
        end
      end,
    },
  },
}
