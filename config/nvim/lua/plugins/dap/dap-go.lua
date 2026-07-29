-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐹 DAP-GO — ULTRA GOLANG DEBUGGER v5.0 OMEGA                             ║
-- ║   Delve · test debugging · benchmark · remote attach · goroutine inspection    ║
-- ║   module-aware · multi-package · race detector · ASH theme-synced              ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Goroutine-specific indicators
    hl(0, "DapGoGoroutine",         { bold = true, fg = "#00ADD8"    })
    hl(0, "DapGoGoroutineBlocked",  { bold = true, fg = "#f38ba8"    })
    hl(0, "DapGoGoroutineRunning",  { bold = true, fg = "#9ece6a"    })
    hl(0, "DapGoGoroutineWaiting",  { bold = true, fg = "#f9e2af"    })
    hl(0, "DapGoTestPass",          { bold = true, fg = "#9ece6a"    })
    hl(0, "DapGoTestFail",          { bold = true, fg = "#f38ba8"    })
    hl(0, "DapGoTestSkip",          { fg = "#9399b2"                 })
    hl(0, "DapGoPackage",           { italic = true, fg = "#89b4fa"  })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "DapGoTestPass",         { bold = true, fg = p.green })
        hl(0, "DapGoGoroutineRunning", { bold = true, fg = p.green })
      end
      if p.red    then
        hl(0, "DapGoTestFail",           { bold = true, fg = p.red })
        hl(0, "DapGoGoroutineBlocked",   { bold = true, fg = p.red })
      end
      if p.yellow then hl(0, "DapGoGoroutineWaiting", { bold = true, fg = p.yellow }) end
      if p.blue   then hl(0, "DapGoPackage",           { italic = true, fg = p.blue }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 GO ENVIRONMENT DETECTION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_delve()
    local mason_dlv = vim.fn.stdpath("data") .. "/mason/packages/delve/delve"
    if vim.fn.executable(mason_dlv) == 1 then return mason_dlv end
  
    local gopath_dlv = (os.getenv("GOPATH") or (os.getenv("HOME") .. "/go"))
      .. "/bin/dlv"
    if vim.fn.executable(gopath_dlv) == 1 then return gopath_dlv end
  
    local which = vim.fn.trim(vim.fn.system("which dlv 2>/dev/null"))
    if which ~= "" then return which end
  
    return "dlv"
  end
  
  -- Get Go module name from go.mod
  local function get_module_name()
    local gomod = vim.fn.getcwd() .. "/go.mod"
    local f     = io.open(gomod, "r")
    if not f then return nil end
  
    for line in f:lines() do
      local mod = line:match("^module%s+(.+)$")
      if mod then
        f:close()
        return vim.fn.trim(mod)
      end
    end
    f:close()
    return nil
  end
  
  -- Get function name under cursor (for test debugging)
  local function get_func_name_at_cursor()
    local node = vim.treesitter.get_node()
    while node do
      if node:type() == "function_declaration" or node:type() == "method_declaration" then
        for child in node:iter_children() do
          if child:type() == "identifier" then
            return vim.treesitter.get_node_text(child, 0)
          end
        end
      end
      node = node:parent()
    end
    return nil
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DEBUG ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function debug_test_at_cursor()
    local dap = require("dap")
    local fn   = get_func_name_at_cursor()
  
    if not fn then
      vim.notify("🐹 No test function at cursor", vim.log.levels.WARN, { title = "DAP Go" })
      return
    end
  
    if not fn:match("^Test") then
      vim.notify(
        string.format("🐹 '%s' is not a test function (must start with Test)", fn),
        vim.log.levels.WARN,
        { title = "DAP Go" }
      )
      return
    end
  
    vim.notify(
      string.format("🐹 Debugging test: %s", fn),
      vim.log.levels.INFO,
      { title = "DAP Go", timeout = 1500 }
    )
  
    dap.run({
      name       = "🐹 Test: " .. fn,
      type       = "go",
      request    = "launch",
      mode       = "test",
      program    = "${fileDirname}",
      args       = { "-test.run", "^" .. fn .. "$", "-test.v" },
      buildFlags = "",
      env        = {},
    })
  end
  
  local function debug_benchmark_at_cursor()
    local dap = require("dap")
    local fn   = get_func_name_at_cursor()
  
    if not fn or not fn:match("^Benchmark") then
      vim.notify("🐹 No benchmark function at cursor", vim.log.levels.WARN, { title = "DAP Go" })
      return
    end
  
    dap.run({
      name    = "🐹 Benchmark: " .. fn,
      type    = "go",
      request = "launch",
      mode    = "test",
      program = "${fileDirname}",
      args    = { "-test.bench", "^" .. fn .. "$", "-test.benchmem", "-test.run", "^$" },
    })
  end
  
  local function debug_all_tests_in_file()
    local dap  = require("dap")
    local file = vim.api.nvim_buf_get_name(0)
    local pkg  = vim.fn.fnamemodify(file, ":h")
  
    vim.notify(
      "🐹 Running all tests in package…",
      vim.log.levels.INFO,
      { title = "DAP Go", timeout = 1000 }
    )
  
    dap.run({
      name    = "🐹 Test package",
      type    = "go",
      request = "launch",
      mode    = "test",
      program = pkg,
      args    = { "-test.v", "-test.count=1" },
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      -- Use leoluz/nvim-dap-go for enhanced Go DAP support
      "leoluz/nvim-dap-go",
      ft           = { "go" },
      dependencies = { "mfussenegger/nvim-dap" },
  
      keys = {
        {
          "<leader>dgt",
          debug_test_at_cursor,
          ft     = "go",
          desc   = "🐹 DAP Go: Debug test at cursor",
          silent = true,
        },
        {
          "<leader>dgT",
          debug_all_tests_in_file,
          ft     = "go",
          desc   = "🐹 DAP Go: Debug package tests",
          silent = true,
        },
        {
          "<leader>dgb",
          debug_benchmark_at_cursor,
          ft     = "go",
          desc   = "🐹 DAP Go: Benchmark at cursor",
          silent = true,
        },
        {
          "<leader>dgr",
          function()
            local dap = require("dap")
            dap.run({
              name    = "🐹 Run main",
              type    = "go",
              request = "launch",
              mode    = "debug",
              program = "${workspaceFolder}",
            })
          end,
          ft     = "go",
          desc   = "🐹 DAP Go: Run main",
          silent = true,
        },
        {
          "<leader>dgi",
          function()
            local dlv  = find_delve()
            local mod  = get_module_name()
            vim.notify(
              table.concat({
                "🐹 Go Debug Info",
                "──────────────────────────────────",
                string.format("  Delve:   %s", dlv),
                string.format("  Module:  %s", mod or "(not in module)"),
                string.format("  GOPATH:  %s", os.getenv("GOPATH") or "unset"),
                string.format("  GOROOT:  %s", vim.fn.trim(vim.fn.system("go env GOROOT 2>/dev/null"))),
                string.format("  Version: %s", vim.fn.trim(vim.fn.system("go version 2>/dev/null"))),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "DAP Go" }
            )
          end,
          ft     = "go",
          desc   = "🐹 DAP Go: Debug info",
          silent = true,
        },
      },
  
      opts = {
        -- Path to delve executable
        delve = {
          path              = find_delve(),
          initialize_timeout_sec = 20,
          port              = "${port}",
          args              = {},
          build_flags       = "",
          detached          = vim.fn.has("linux") == 1,
          cwd               = nil,
        },
        -- DAP configurations to install
        dap_configurations = {
          {
            type    = "go",
            name    = "🐹 Attach (remote)",
            mode    = "remote",
            request = "attach",
            connect = {
              host = "127.0.0.1",
              port = "38697",
            },
          },
        },
        -- Test configurations
        tests = {
          verbose = true,
        },
      },
  
      config = function(_, opts)
        require("dap-go").setup(opts)
  
        setup_highlights()
  
        -- Extend DAP configurations with our custom ones
        local dap = require("dap")
  
        -- Additional Go launch configs
        local extra_configs = {
          {
            name       = "🐹 Launch: with race detector",
            type       = "go",
            request    = "launch",
            mode       = "debug",
            program    = "${workspaceFolder}",
            buildFlags = "-race",
            env        = { GORACE = "log_path=stderr" },
          },
          {
            name    = "🐹 Launch: with args",
            type    = "go",
            request = "launch",
            mode    = "debug",
            program = "${workspaceFolder}",
            args    = function()
              return vim.split(vim.fn.input("Go args: "), " ", { trimempty = true })
            end,
          },
          {
            name    = "🐹 Attach: local process",
            type    = "go",
            request = "attach",
            mode    = "local",
            processId = require("dap.utils").pick_process,
          },
          {
            name    = "🐹 Attach: remote Delve",
            type    = "go",
            request = "attach",
            mode    = "remote",
            connect = {
              host = function() return vim.fn.input("Host [127.0.0.1]: ", "127.0.0.1") end,
              port = function() return vim.fn.input("Port [2345]: ", "2345") end,
            },
            substitutePath = {
              { from = "${workspaceFolder}", to = "/app" },
            },
          },
          {
            name       = "🐹 Test: with coverage",
            type       = "go",
            request    = "launch",
            mode       = "test",
            program    = "${fileDirname}",
            args       = { "-test.v", "-test.count=1", "-coverprofile=/tmp/go-coverage.out" },
            buildFlags = "-covermode=atomic",
          },
        }
  
        for _, cfg in ipairs(extra_configs) do
          table.insert(dap.configurations.go, cfg)
        end
  
        local aug = vim.api.nvim_create_augroup("AshDapGo", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🐹 DAP Go highlights synced", vim.log.levels.INFO,
              { title = "ASH DAP Go", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🐹 DAP Go loaded — Delve: %s", find_delve()),
            vim.log.levels.DEBUG,
            { title = "ASH DAP Go" }
          )
        end
      end,
    },
  }