return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            vtsls = {
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
              tsserver = {
                globalPlugins = {},
                maxTsServerMemory = 8192,
              },
            },
            typescript = {
              tsserver = {
                maxTsServerMemory = 8192,
                watchOptions = {
                  watchFile = "useFsEventsOnParentDirectory",
                  watchDirectory = "useFsEvents",
                  fallbackPolling = "dynamicPriorityPolling",
                  excludeDirectories = {
                    "**/node_modules",
                    "**/dist",
                    "**/.worktree",
                    "**/.git",
                    "**/build",
                    "**/.next",
                    "**/coverage",
                  },
                },
                exclude = {
                  "**/node_modules",
                  "**/dist",
                  "**/.worktree",
                  "**/build",
                  "**/.next",
                  "**/coverage",
                },
              },
              preferences = {
                includePackageJsonAutoImports = "off",
              },
              suggest = {
                completeFunctionCalls = false,
              },
              updateImportsOnFileMove = { enabled = "never" },
            },
            javascript = {
              preferences = {
                includePackageJsonAutoImports = "off",
              },
            },
          },
        },
      },
    },
  },
}
