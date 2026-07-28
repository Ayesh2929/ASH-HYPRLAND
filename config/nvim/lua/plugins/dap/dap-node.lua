-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📘 DAP-NODE — ULTRA NODE.JS/TYPESCRIPT DEBUGGER v5.0 OMEGA               ║
-- ║   pwa-node · Chrome DevTools · Jest · Vitest · NestJS · Next.js               ║
-- ║   tsx · ts-node · source maps · remote · ASH theme-synced                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "DapNodeRuntime",       { bold = true, italic = true, fg = "#68A063" })
    hl(0, "DapNodeSourceMap",     { italic = true, fg = "#89b4fa"              })
    hl(0, "DapNodeBreakpoint",    { bold = true, fg = "#f38ba8"                })
    hl(0, "DapNodeConsoleLog",    { fg = "#a6e3a1"                             })
    hl(0, "DapNodeConsoleError",  { fg = "#f38ba8"                             })
    hl(0, "DapNodeConsoleWarn",   { fg = "#f9e2af"                             })
    hl(0, "DapNodeException",     { bold = true, fg = "#f38ba8", bg = "#2d1b1e" })
    hl(0, "DapNodePromise",       { italic = true, fg = "#cba6f7"              })
    hl(0, "DapNodeAsync",         { italic = true, fg = "#94e2d5"              })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "DapNodeRuntime",     { bold = true, italic = true, fg = p.green })
        hl(0, "DapNodeConsoleLog",  { fg = p.green })
      end
      if p.blue   then hl(0, "DapNodeSourceMap",  { italic = true, fg = p.blue  }) end
      if p.red    then
        hl(0, "DapNodeBreakpoint",   { bold = true, fg = p.red })
        hl(0, "DapNodeConsoleError", { fg = p.red })
        hl(0, "DapNodeException",    { bold = true, fg = p.red, bg = p.surface0 or "#2d1b1e" })
      end
      if p.yellow then hl(0, "DapNodeConsoleWarn", { fg = p.yellow }) end
      if p.mauve  then hl(0, "DapNodePromise",     { italic = true, fg = p.mauve }) end
      if p.teal   then hl(0, "DapNodeAsync",       { italic = true, fg = p.teal  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ENVIRONMENT DETECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_js_debug()
    local mason_path = vim.fn.stdpath("data")
      .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
    if vim.fn.filereadable(mason_path) == 1 then return mason_path end
    return nil
  end
  
  local function get_node_version()
    return vim.fn.trim(vim.fn.system("node --version 2>/dev/null"))
  end
  
  local function detect_package_manager()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/pnpm-lock.yaml") == 1 then return "pnpm" end
    if vim.fn.filereadable(cwd .. "/yarn.lock")      == 1 then return "yarn" end
    if vim.fn.filereadable(cwd .. "/bun.lockb")      == 1 then return "bun"  end
    return "npm"
  end
  
  -- Detect project type from package.json
  local function detect_project_type()
    local pkg_file = vim.fn.getcwd() .. "/package.json"
    local f = io.open(pkg_file, "r")
    if not f then return "node" end
  
    local content = f:read("*a")
    f:close()
  
    local ok, pkg = pcall(vim.fn.json_decode, content)
    if not ok then return "node" end
  
    local deps = vim.tbl_extend("force",
      pkg.dependencies     or {},
      pkg.devDependencies  or {}
    )
  
    if deps["@nestjs/core"]      then return "nestjs"   end
    if deps["next"]              then return "nextjs"   end
    if deps["nuxt"]              then return "nuxt"     end
    if deps["@remix-run/node"]   then return "remix"    end
    if deps["react-scripts"]     then return "cra"      end
    if deps["vite"]              then return "vite"     end
  
    return "node"
  end
  
  -- Find test runner executable
  local function find_test_runner(runner)
    local cwd = vim.fn.getcwd()
    local candidates = {
      cwd .. "/node_modules/.bin/" .. runner,
      cwd .. "/node_modules/." .. runner .. "/bin/" .. runner .. ".mjs",
    }
    for _, c in ipairs(candidates) do
      if vim.fn.filereadable(c) == 1 or vim.fn.executable(c) == 1 then return c end
    end
    return runner
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DEBUG ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function debug_jest_file()
    local dap  = require("dap")
    local file = vim.api.nvim_buf_get_name(0)
    local jest = find_test_runner("jest")
  
    dap.run({
      name    = "📘 Jest: " .. vim.fn.fnamemodify(file, ":t"),
      type    = "pwa-node",
      request = "launch",
      runtimeExecutable = "node",
      runtimeArgs = {
        jest,
        "--runInBand",
        "--testPathPattern", file,
        "--forceExit",
        "--no-coverage",
      },
      rootPath = "${workspaceFolder}",
      cwd      = "${workspaceFolder}",
      console  = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
      sourceMaps = true,
      resolveSourceMapLocations = {
        "${workspaceFolder}/**",
        "!**/node_modules/**",
      },
    })
  end
  
  local function debug_vitest_file()
    local dap    = require("dap")
    local file   = vim.api.nvim_buf_get_name(0)
    local vitest = find_test_runner("vitest")
  
    dap.run({
      name    = "📘 Vitest: " .. vim.fn.fnamemodify(file, ":t"),
      type    = "pwa-node",
      request = "launch",
      cwd     = "${workspaceFolder}",
      program = vitest,
      args    = { "run", file },
      console = "integratedTerminal",
      smartStep    = true,
      sourceMaps   = true,
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-dap",
      ft = {
        "javascript", "typescript", "javascriptreact", "typescriptreact",
        "vue", "svelte",
      },
  
      keys = {
        {
          "<leader>dnjt",
          debug_jest_file,
          ft     = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
          desc   = "📘 DAP Node: Jest current file",
          silent = true,
        },
        {
          "<leader>dnvt",
          debug_vitest_file,
          ft     = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
          desc   = "📘 DAP Node: Vitest current file",
          silent = true,
        },
        {
          "<leader>dni",
          function()
            local js_debug = find_js_debug()
            vim.notify(
              table.concat({
                "📘 Node.js Debug Info",
                "──────────────────────────────────",
                string.format("  Node:     %s", get_node_version()),
                string.format("  js-debug: %s", js_debug or "(not installed)"),
                string.format("  PM:       %s", detect_package_manager()),
                string.format("  Project:  %s", detect_project_type()),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "DAP Node" }
            )
          end,
          ft     = { "javascript", "typescript" },
          desc   = "📘 DAP Node: Debug info",
          silent = true,
        },
      },
  
      config = function()
        local dap      = require("dap")
        local js_debug = find_js_debug()
  
        -- ── Register pwa-node adapter ─────────────────────────────────────────
        if js_debug then
          dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "node",
              args    = { js_debug, "${port}" },
            },
          }
        end
  
        -- Chrome/Edge adapter
        dap.adapters["pwa-chrome"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args    = js_debug and { js_debug, "${port}" } or {},
          },
        }
  
        -- Alias
        dap.adapters.node = dap.adapters["pwa-node"]
  
        -- ── Common source map config ──────────────────────────────────────────
        local source_maps = {
          sourceMaps = true,
          resolveSourceMapLocations = {
            "${workspaceFolder}/**",
            "!**/node_modules/**",
          },
        }
  
        -- ── JavaScript / TypeScript launch configs ────────────────────────────
        local js_configs = {
          -- Launch current file
          {
            name    = "📘 Launch: current file",
            type    = "pwa-node",
            request = "launch",
            program = "${file}",
            cwd     = "${workspaceFolder}",
            console = "integratedTerminal",
            skipFiles = { "<node_internals>/**", "node_modules/**" },
            vim.tbl_extend("force", source_maps, {}),
          },
  
          -- Launch with ts-node
          {
            name    = "📘 Launch: ts-node",
            type    = "pwa-node",
            request = "launch",
            runtimeExecutable = "node",
            runtimeArgs       = {
              "--loader", "ts-node/esm",
              "--no-experimental-warnings",
            },
            program = "${file}",
            cwd     = "${workspaceFolder}",
            console = "integratedTerminal",
            sourceMaps = true,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
          },
  
          -- Launch with tsx
          {
            name    = "📘 Launch: tsx",
            type    = "pwa-node",
            request = "launch",
            runtimeExecutable = "tsx",
            program = "${file}",
            cwd     = "${workspaceFolder}",
            console = "integratedTerminal",
            sourceMaps = true,
          },
  
          -- npm start
          {
            name    = "📘 npm start",
            type    = "pwa-node",
            request = "launch",
            cwd     = "${workspaceFolder}",
            runtimeExecutable = "npm",
            runtimeArgs       = { "run", "start" },
            console = "integratedTerminal",
            skipFiles = { "<node_internals>/**" },
            sourceMaps = true,
          },
  
          -- Attach to running process
          {
            name    = "📘 Attach: --inspect",
            type    = "pwa-node",
            request = "attach",
            processId = require("dap.utils").pick_process,
            cwd     = "${workspaceFolder}",
            sourceMaps = true,
            resolveSourceMapLocations = {
              "${workspaceFolder}/**",
              "!**/node_modules/**",
            },
          },
  
          -- Attach by port
          {
            name    = "📘 Attach: port",
            type    = "pwa-node",
            request = "attach",
            port    = function()
              return tonumber(vim.fn.input("Port [9229]: ", "9229"))
            end,
            hostname = "localhost",
            cwd      = "${workspaceFolder}",
            sourceMaps = true,
          },
  
          -- Jest: current file
          {
            name    = "📘 Jest: current file",
            type    = "pwa-node",
            request = "launch",
            runtimeExecutable = "node",
            runtimeArgs       = {
              find_test_runner("jest"),
              "--runInBand",
              "--testPathPattern", "${file}",
              "--forceExit",
            },
            rootPath = "${workspaceFolder}",
            cwd      = "${workspaceFolder}",
            console  = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            sourceMaps = true,
          },
  
          -- Vitest: current file
          {
            name    = "📘 Vitest: current file",
            type    = "pwa-node",
            request = "launch",
            cwd     = "${workspaceFolder}",
            program = find_test_runner("vitest"),
            args    = { "run", "${file}" },
            console = "integratedTerminal",
            sourceMaps = true,
          },
  
          -- NestJS
          {
            name    = "📘 NestJS: debug",
            type    = "pwa-node",
            request = "launch",
            runtimeExecutable = "node",
            runtimeArgs       = { "--nolazy", "-r", "ts-node/register" },
            args              = { "--inspect", "${workspaceFolder}/src/main.ts" },
            cwd     = "${workspaceFolder}",
            console = "integratedTerminal",
            sourceMaps = true,
          },
  
          -- Next.js
          {
            name    = "📘 Next.js: debug server",
            type    = "pwa-node",
            request = "launch",
            cwd     = "${workspaceFolder}",
            runtimeExecutable = "npm",
            runtimeArgs       = { "run", "dev" },
            console = "integratedTerminal",
            serverReadyAction = {
              pattern     = "- Local: .*",
              uriFormat   = "%s",
              action      = "debugWithChrome",
            },
          },
  
          -- Chrome: attach
          {
            name    = "📘 Chrome: attach",
            type    = "pwa-chrome",
            request = "attach",
            port    = 9222,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
  
          -- Chrome: launch
          {
            name    = "📘 Chrome: launch",
            type    = "pwa-chrome",
            request = "launch",
            url     = function()
              return vim.fn.input("URL [http://localhost:3000]: ", "http://localhost:3000")
            end,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
        }
  
        -- Apply to all JS/TS filetypes
        local js_fts = {
          "javascript", "typescript",
          "javascriptreact", "typescriptreact",
          "vue", "svelte",
        }
        for _, ft in ipairs(js_fts) do
          dap.configurations[ft] = js_configs
        end
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDapNode", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📘 DAP Node highlights synced", vim.log.levels.INFO,
              { title = "ASH DAP Node", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "📘 DAP Node loaded — Node %s | js-debug: %s",
              get_node_version(),
              js_debug and "✅" or "⭕"
            ),
            vim.log.levels.DEBUG,
            { title = "ASH DAP Node" }
          )
        end
      end,
    },
  }