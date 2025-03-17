local js_based_languages = {
  "typescript",
  "javascript",
  "typescriptreact",
  "javascriptreact",
  "vue",
}

return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local Config = require("lazyvim.config")
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      for name, sign in pairs(Config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }

      dap.adapters["pwa-chrome"] = {
        type = "executable",
        command = "node",
        args = { require("mason-core.path").package_prefix("chrome-debug-adapter") .. "/out/src/chromeDebug.js" },
      }

      for _, lang in ipairs(js_based_languages) do
        dap.configurations[lang] = {
          string.match(lang, "typescript")
              and {
                type = "pwa-node",
                request = "launch",
                name = "Launch file",
                cwd = vim.fn.getcwd(),
                sourceMaps = true,
                -- runtimeExecutable = "node",
                runtimeExecutable = "ts-node",
                -- runtimeArgs = { "--no-warnings=ExperimentalWarning", "--loader", "ts-node/esm" },
                runtimeArgs = {
                  "--transpile-only",
                  "--compiler-options",
                  '{"module":"CommonJS","esModuleInterop":true}',
                },
                -- outFiles = { "${workspaceFolder}/bin/**/*.js" },
                program = "${file}",
                protocol = "inspector",
                skipFiles = { "<node_internals>/**", "node_modules/**" },
                resolveSourceMapLocations = {
                  "${workspaceFolder}/**",
                  "!**/node_modules/**",
                },
              }
            or {
              type = "pwa-node",
              request = "launch",
              name = "Launch file",
              program = "${file}",
              cwd = vim.fn.getcwd(),
              sourceMaps = true,
            },
          -- Debug nodejs processes (make sure to add --inspect when you run the process)
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch & Debug Chrome",
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({
                  prompt = "Enter URL: ",
                  default = "http://localhost:3333",
                }, function(url)
                  if url == nil or url == "" then
                    return
                  else
                    coroutine.resume(co, url)
                  end
                end)
              end)
            end,
            webRoot = vim.fn.getcwd(),
            protocol = "inspector",
            sourceMaps = true,
            userDataDir = false,
          },
        }
      end
    end,
    dependencies = {
      {
        "Joakker/lua-json5",
        build = "./install.sh",
      },
    },
  },
}
