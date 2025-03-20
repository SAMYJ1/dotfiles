return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>fw",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        -- Open in the current working directory
        "<leader>fm",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
      },
      {
        -- Open in the current working directory
        "<leader>f,",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
      },
    },
    opts = {
      open_for_directories = false,
    },
  },
}
