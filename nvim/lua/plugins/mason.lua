return {

  -- Ensure GitUI tool is installed
  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "gitui" } },
    keys = {
      {
        "<leader>gG",
        function()
          LazyVim.terminal.open({ "gitui" }, { esc_esc = false, env = { EDITOR = "nvim" }, ctrl_hjkl = false })
        end,
        desc = "GitUi (cwd)",
      },
      {
        "<leader>gg",
        function()
          LazyVim.terminal.open(
            { "gitui" },
            { cwd = LazyVim.root.get(), env = { EDITOR = "nvim" }, esc_esc = false, ctrl_hjkl = false }
          )
        end,
        desc = "GitUi (Root Dir)",
      },
    },
  },
}
