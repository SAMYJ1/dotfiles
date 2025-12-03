return {
  {
    "snacks.nvim",
    opts = {
      scroll = { enabled = false },
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
