return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = function()
      local tsc = require("treesitter-context")
      Snacks.toggle({
        name = "Treesitter Context",
        get = tsc.enabled,
        set = function(state)
          if state then
            tsc.enable()
          else
            tsc.disable()
          end
        end,
      }):map("<leader>ut")
      return { mode = "cursor", max_lines = 3 }
    end,
    keys = {
      {
        "[u",
        function()
          require("treesitter-context").go_to_context(1)
        end,
        mode = { "n" },
        desc = "Jumping to context (upwards)",
      },
    },
  },
}
