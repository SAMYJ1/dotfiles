return {
  -- markview.nvim: in-buffer markdown rendering
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },

  -- disable spell checking for markdown (override LazyVim's wrap_spell autocmd)
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        pattern = { "markdown", "*.md" },
        callback = function()
          if vim.bo.filetype == "markdown" then
            vim.opt_local.spell = false
          end
        end,
      })
    end,
  },

  -- disable markdownlint diagnostics for markdown files
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft["markdown"] = {}
    end,
  },
}
