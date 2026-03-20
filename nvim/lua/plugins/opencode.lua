return {
  {
    "nickjvandyke/opencode.nvim",
    dependencies = {
      { "folke/snacks.nvim" },
    },
    config = function()
      -- Required for opts.events.reload
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>oa", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })

      vim.keymap.set({ "n", "x" }, "<leader>os", function()
        require("opencode").select()
      end, { desc = "Select opencode action" })

      vim.keymap.set({ "n", "t" }, "<leader>ot", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "<leader>oo", function()
        return require("opencode").operator("@this ")
      end, { desc = "Add range to opencode", expr = true })

      vim.keymap.set("n", "<leader>ol", function()
        return require("opencode").operator("@this ") .. "_"
      end, { desc = "Add line to opencode", expr = true })
    end,
  },
  -- Enable snacks input and terminal (required by opencode.nvim snacks provider)
  {
    "folke/snacks.nvim",
    opts = {
      input = {},
      terminal = {},
    },
  },
}
