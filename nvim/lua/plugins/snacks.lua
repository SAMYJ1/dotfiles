local function update_preview_title(picker, item)
  if item and item.file and picker.preview then
    vim.schedule(function()
      local filename = vim.fn.fnamemodify(item.file, ":t")
      local fullpath = vim.fn.fnamemodify(item.file, ":p:~:.")

      -- 优先级1：检查预览窗口宽度是否足够显示完整路径
      local preview_win = picker.preview.win
      local preview_width = preview_win and preview_win.win and vim.api.nvim_win_get_width(preview_win.win) or 80
      local max_path_width = preview_width - 4

      if #fullpath > max_path_width then
        -- 预览窗口宽度不够，只显示文件名
        picker.preview:set_title(filename)
        picker:update_titles()
        return
      end

      -- 优先级2：检查左侧路径是否被折叠
      local list_win = picker.list and picker.list.win
      local list_width = list_win and list_win.win and vim.api.nvim_win_get_width(list_win.win) or 60
      local available_width = math.max(list_width - 8, 20)

      local path = Snacks.picker.util.path(item) or item.file
      local formatted = Snacks.picker.util.truncpath(
        path,
        available_width,
        { cwd = picker:cwd(), kind = picker.opts.formatters.file.truncate }
      )
      local is_truncated = formatted:find("…") ~= nil

      -- 宽度够且被折叠时显示完整路径，否则显示文件名
      local title = is_truncated and fullpath or filename
      picker.preview:set_title(title)
      picker:update_titles()
    end)
  end
end

return {
  {
    "snacks.nvim",
    opts = {
      scroll = { enabled = false },
      image = { enabled = true },
      dashboard = {
        preset = {
          header = [[
██╗   ██╗ ███████╗  ██████╗  ██████╗  ██████╗  ███████╗
██║   ██║ ██╔════╝ ██╔════╝ ██╔═══██╗ ██╔══██╗ ██╔════╝
██║   ██║ ███████╗ ██║      ██║   ██║ ██║  ██║ █████╗  
╚██╗ ██╔╝ ╚════██║ ██║      ██║   ██║ ██║  ██║ ██╔══╝  
 ╚████╔╝  ███████║ ╚██████╗ ╚██████╔╝ ██████╔╝ ███████╗
  ╚═══╝   ╚══════╝  ╚═════╝  ╚═════╝  ╚═════╝  ╚══════╝
 ]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        },
      },
      picker = {
        win = {
          input = {
            keys = {
              ["<c-l>"] = { "loclist", mode = { "i", "n" } },
              ["<Esc>"] = { "close", mode = { "n", "i" } },
              ["<c-/>"] = { "toggle_help_input", mode = { "n", "i" } },
              ["<c-_>"] = { "toggle_help_input", mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["<c-l>"] = { "loclist", mode = { "i", "n" } },
            },
          },
        },
        matcher = {
          history_bonus = true,
        },
        -- 在预览显示后更新标题
        on_change = update_preview_title,
        sources = {
          grep = { on_change = update_preview_title },
          grep_buffers = { on_change = update_preview_title },
          grep_word = { on_change = update_preview_title },
          live_grep = { on_change = update_preview_title },
        },
      },
      scratch = {
        win_by_ft = {
          typescript = {
            keys = {
              ["source"] = {
                "<cr>",
                function()
                  vim.api.nvim_command("w")
                  local file = vim.api.nvim_buf_get_name(0)

                  -- TSX only accepts .ts files, not .typescript
                  local tsFile = file:gsub("%.typescript$", ".ts")
                  os.rename(file, tsFile)

                  local shell_command = {
                    "ts-node",
                    "--transpile-only",
                    "--compiler-options",
                    '{"module":"CommonJS","esModuleInterop":true}',
                    tsFile,
                  }

                  local res = vim.system(shell_command, { text = true }):wait()

                  -- os.rename(tsFile, file)
                  if res.code ~= 0 then
                    Snacks.notify.error(res.stderr or "Unknown error.")
                    return
                  end

                  Snacks.notify(res.stdout)
                end,
                desc = "Source buffer",
                mode = { "n", "x" },
              },
            },
          },
          javascript = {
            keys = {
              ["source"] = {
                "<cr>",
                function()
                  vim.api.nvim_command("w")
                  local file = vim.api.nvim_buf_get_name(0)
                  local jsFile = file:gsub("%.javascript$", ".js")
                  os.rename(file, jsFile)
                  local shell_command = {
                    "node",
                    jsFile,
                  }

                  local res = vim.system(shell_command, { text = true }):wait()

                  os.rename(jsFile, file)
                  if res.code ~= 0 then
                    Snacks.notify.error(res.stderr or "Unknown error.")
                    return
                  end

                  Snacks.notify(res.stdout)
                end,
                desc = "Source buffer",
                mode = { "n", "x" },
              },
            },
          },
        },
      },
    },
    keys = {
      {
        "<leader>bd",
        function()
          local bufname = vim.api.nvim_buf_get_name(0) -- Get the current buffer's name
          local scratch_dir = vim.fn.stdpath("data") .. "/scratch" -- Default scratch directory

          Snacks.bufdelete()
          if bufname and bufname:sub(1, #scratch_dir) == scratch_dir then
            -- Buffer is a saved scratch buffer
            os.remove(bufname) -- Delete the file from disk
            print("Deleted scratch buffer and file: " .. bufname)
          end
        end,
        desc = "Delete (Scratch) Buffer",
      },
    },
  },
  {
    "folke/trouble.nvim",
    optional = true,
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
            win = {
              input = {
                keys = {
                  ["<c-t>"] = {
                    "trouble_open",
                    mode = { "n", "i" },
                  },
                },
              },
            },
          },
        })
      end,
    },
  },
}
