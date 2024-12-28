return {
  -- {
  --   "folke/tokyonight.nvim",
  --   lazy = true,
  --   opts = {
  --     style = "moon",
  --     transparent = true,
  --     styles = {
  --       sidebars = "transparent",
  --       floats = "transparent",
  --     },
  --     on_highlights = function(hl, colors)
  --       hl.LineNrAbove = {
  --         fg = colors.dark3,
  --       }
  --       hl.LineNrBelow = {
  --         fg = colors.dark3,
  --       }
  --     end,
  --   },
  -- },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    opts = {
      transparent_background = true,
    },
    specs = {
      {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
          end
        end,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
