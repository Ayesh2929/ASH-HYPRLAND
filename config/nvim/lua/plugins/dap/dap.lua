-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐛 DAP — ULTRA DEBUG ADAPTER PROTOCOL ENGINE v5.0 OMEGA                  ║
-- ║   Multi-language · breakpoints · step · inspect · conditional · logpoints      ║
-- ║   exception filters · REPL · persistent breakpoints · ASH theme-synced         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — ASH premium debug indicators
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Breakpoint signs ──────────────────────────────────────────────────────
    hl(0, "DapBreakpoint",          { bold = true, fg = "#f38ba8"             })
    hl(0, "DapBreakpointCondition", { bold = true, fg = "#f9e2af"             })
    hl(0, "DapBreakpointRejected",  { bold = true, fg = "#6e738d"             })
    hl(0, "DapLogPoint",            { bold = true, fg = "#89b4fa"             })
    hl(0, "DapStopped",             {
      bold      = true,
      fg        = "#9ece6a",
      bg        = "#1a2b1a",
    })
  
    -- ── Line highlights ───────────────────────────────────────────────────────
    hl(0, "DapStoppedLine",         { bg = "#1a2b1a"                          })
    hl(0, "DapBreakpointLine",      { bg = "#2d1b1e"                          })
  
    -- ── REPL / console ───────────────────────────────────────────────────────
    hl(0, "DapReplNormal",          { link = "NormalFloat"                    })
    hl(0, "DapReplBorder",          { link = "FloatBorder"                    })
  
    -- ── Status indicators ─────────────────────────────────────────────────────
    hl(0, "DapStatusRunning",       { bold = true, fg = "#9ece6a"             })
    hl(0, "DapStatusStopped",       { bold = true, fg = "#f9e2af"             })
    hl(0, "DapStatusError",         { bold = true, fg = "#f38ba8"             })
    hl(0, "DapStatusPaused",        { bold = true, fg = "#89b4fa"             })
    hl(0, "DapStatusExited",        { bold = true, fg = "#9399b2"             })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.red    then hl(0, "DapBreakpoint",          { bold = true, fg = p.red    }) end
      if p.yellow then hl(0, "DapBreakpointCondition", { bold = true, fg = p.yellow }) end
      if p.green  then
        hl(0, "DapStopped",      { bold = true, fg = p.green, bg = p.surface0 or "#1a2b1a" })
        hl(0, "DapStatusRunning",{ bold = true, fg = p.green })
      end
      if p.blue   then
        hl(0, "DapLogPoint",     { bold = true, fg = p.blue })
        hl(0, "DapStatusPaused", { bold = true, fg = p.blue })
      end
      if p.yellow then hl(0, "DapStatusStopped", { bold = true, fg = p.yellow }) end
      if p.red    then hl(0, "DapStatusError",   { bold = true, fg = p.red    }) end
      local dim = p.overlay0 or "#6e738d"
      hl(0, "DapBreakpointRejected", { bold = true, fg = dim })
      hl(0, "DapStatusExited",       { bold = true, fg = dim })
      if p.surface0 then
        hl(0, "DapStoppedLine",    { bg = p.surface0 })
        hl(0, "DapBreakpointLine", { bg = p.surface0 })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 SIGN DEFINITIONS — premium Nerd Font v3 debug icons
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local SIGNS = {
    DapBreakpoint          = { text = " ",  hl = "DapBreakpoint"          },
    DapBreakpointCondition = { text = " ",  hl = "DapBreakpointCondition" },
    DapBreakpointRejected  = { text = " ",  hl = "DapBreakpointRejected"  },
    DapLogPoint            = { text = "󰐍 ", hl = "DapLogPoint"            },
    DapStopped             = { text = "󰁕 ", hl = "DapStopped", linehl = "DapStoppedLine" },
  }
  
  local function register_signs()
    for name, cfg in pairs(SIGNS) do
      vim.fn.sign_define(name, {
        text      = cfg.text,
        texthl    = cfg.hl,
        linehl    = cfg.linehl or "",
        numhl     = cfg.numhl  or "",
      })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 BREAKPOINT PERSISTENCE — save/restore across sessions
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local BP_STORE = vim.fn.stdpath("data") .. "/dap_breakpoints.json"
  
  local function save_breakpoints()
    local ok, dap = pcall(require, "dap")
    if not ok then return end
  
    local bps = dap.list_breakpoints()
    local data = {}
  
    for _, bp in ipairs(bps) do
      local key = vim.fn.fnamemodify(bp.source.path or "", ":~:.")
      data[key] = data[key] or {}
      table.insert(data[key], {
        line      = bp.line,
        condition = bp.condition,
        hit_condition = bp.hitCondition,
        log_message   = bp.logMessage,
      })
    end
  
    local json = vim.fn.json_encode(data)
    local f    = io.open(BP_STORE, "w")
    if f then
      f:write(json)
      f:close()
    end
  end
  
  local function load_breakpoints()
    local f = io.open(BP_STORE, "r")
    if not f then return end
  
    local content = f:read("*a")
    f:close()
  
    local ok_json, data = pcall(vim.fn.json_decode, content)
    if not ok_json or type(data) ~= "table" then return end
  
    local ok_dap, dap = pcall(require, "dap")
    if not ok_dap then return end
  
    for rel_path, bps in pairs(data) do
      local abs_path = vim.fn.fnamemodify(rel_path, ":p")
      for _, bp in ipairs(bps) do
        dap.set_breakpoint(bp.condition, bp.hit_condition, bp.log_message)
        -- Place at the correct line
        vim.fn.sign_place(
          0, "dap", "DapBreakpoint", abs_path,
          { lnum = bp.line, priority = 11 }
        )
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DAP ACTIONS — ergonomic wrappers
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Toggle breakpoint with notification
  local function toggle_breakpoint()
    local dap = require("dap")
    local bp  = dap.list_breakpoints()
    local buf  = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1]
  
    -- Check if breakpoint already exists at this line
    local has_bp = false
    for _, b in ipairs(bp) do
      if b.source and b.source.path == vim.api.nvim_buf_get_name(buf)
        and b.line == line
      then
        has_bp = true
        break
      end
    end
  
    dap.toggle_breakpoint()
  
    vim.notify(
      has_bp
        and string.format("🐛  Breakpoint removed at line %d", line)
        or  string.format("🐛  Breakpoint set at line %d", line),
      vim.log.levels.INFO,
      { title = "DAP", timeout = 1200 }
    )
  end
  
  -- Set conditional breakpoint via input
  local function set_conditional_breakpoint()
    vim.ui.input(
      { prompt = "🐛  Condition: " },
      function(cond)
        if not cond or cond == "" then return end
        require("dap").set_breakpoint(cond)
        vim.notify(
          string.format("🐛  Conditional breakpoint: %s", cond),
          vim.log.levels.INFO,
          { title = "DAP", timeout = 1500 }
        )
      end
    )
  end
  
  -- Set logpoint
  local function set_logpoint()
    vim.ui.input(
      { prompt = "📋 Log message (use {expr} for interpolation): " },
      function(msg)
        if not msg or msg == "" then return end
        require("dap").set_breakpoint(nil, nil, msg)
        vim.notify(
          string.format("📋 Logpoint: %s", msg),
          vim.log.levels.INFO,
          { title = "DAP", timeout = 1500 }
        )
      end
    )
  end
  
  -- Set hit-count breakpoint
  local function set_hit_breakpoint()
    vim.ui.input(
      { prompt = "🔢 Hit count: " },
      function(count)
        if not count or count == "" then return end
        require("dap").set_breakpoint(nil, count, nil)
        vim.notify(
          string.format("🔢 Hit breakpoint: %s", count),
          vim.log.levels.INFO,
          { title = "DAP", timeout = 1500 }
        )
      end
    )
  end
  
  -- Smart continue: start or continue depending on session state
  local function smart_continue()
    local dap = require("dap")
    if dap.session() then
      dap.continue()
    else
      -- No active session — show config picker or start most recent
      vim.notify(
        "🐛  Starting debug session…",
        vim.log.levels.INFO,
        { title = "DAP", timeout = 800 }
      )
      dap.continue()
    end
  end
  
  -- Show breakpoints in quickfix
  local function breakpoints_to_qf()
    local dap = require("dap")
    local bps  = dap.list_breakpoints()
  
    if #bps == 0 then
      vim.notify("🐛  No breakpoints set", vim.log.levels.INFO, { title = "DAP" })
      return
    end
  
    local qf = vim.tbl_map(function(bp)
      return {
        filename = bp.source and bp.source.path or "",
        lnum     = bp.line or 0,
        col      = 1,
        text     = string.format(
          "[BP]%s%s",
          bp.condition    and (" cond:" .. bp.condition)   or "",
          bp.logMessage   and (" log:"  .. bp.logMessage)  or ""
        ),
      }
    end, bps)
  
    vim.fn.setqflist(qf)
    vim.cmd("copen")
  end
  
  -- DAP status for statusline
  local _dap_status = ""
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🌍 ADAPTER CONFIGURATIONS — per-language debug adapters
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function configure_adapters(dap)
    -- ── 🦀 Rust / C / C++ — CodeLLDB ──────────────────────────────────────────
    local codelldb_path = vim.fn.stdpath("data")
      .. "/mason/packages/codelldb/extension/adapter/codelldb"
    local liblldb_path  = vim.fn.stdpath("data")
      .. "/mason/packages/codelldb/extension/lldb/lib/liblldb"
  
    -- Detect platform
    local os_ext = vim.fn.has("mac") == 1 and ".dylib" or ".so"
    liblldb_path = liblldb_path .. os_ext
  
    dap.adapters.codelldb = {
      type    = "server",
      port    = "${port}",
      host    = "127.0.0.1",
      executable = {
        command = codelldb_path,
        args    = { "--port", "${port}" },
      },
    }
  
    -- ── 🐍 Python — debugpy ───────────────────────────────────────────────────
    dap.adapters.python = function(cb, config)
      if config.request == "attach" then
        local port = (config.connect or config).port
        local host = (config.connect or config).host or "127.0.0.1"
        cb({
          type = "server",
          port = assert(port, "`connect.port` is required for a python `attach` configuration"),
          host = host,
          options = { source_filetype = "python" },
        })
      else
        cb({
          type = "executable",
          command = (function()
            -- Find debugpy in active virtualenv
            local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
            if venv then
              return venv .. "/bin/python"
            end
            -- Fall back to Mason-installed debugpy
            return vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
          end)(),
          args  = { "-m", "debugpy.adapter" },
          options = { source_filetype = "python" },
        })
      end
    end
  
    -- ── 🐹 Go — Delve ─────────────────────────────────────────────────────────
    dap.adapters.go = {
      type = "server",
      port = "${port}",
      executable = {
        command = vim.fn.stdpath("data") .. "/mason/packages/delve/delve",
        args    = { "dap", "-l", "127.0.0.1:${port}" },
      },
    }
  
    -- ── 📘 Node.js / TypeScript ───────────────────────────────────────────────
    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          vim.fn.stdpath("data")
            .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      },
    }
  
    -- Alias for convenience
    dap.adapters.node  = dap.adapters["pwa-node"]
    dap.adapters.chrome= {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js",
      args    = {},
    }
  
    -- ── 🐚 Bash ───────────────────────────────────────────────────────────────
    dap.adapters.bash = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
      args    = {},
    }
  
    -- ── ☕ Java — java-debug ──────────────────────────────────────────────────
    dap.adapters.java = {
      type = "server",
      host = "127.0.0.1",
      port = 5005,
    }
  
    -- ── 🔷 C# / .NET — netcoredbg ────────────────────────────────────────────
    dap.adapters.coreclr = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/netcoredbg",
      args    = { "--interpreter=vscode" },
    }
  
    -- ── 🦩 Kotlin — kotlin-debug-adapter ─────────────────────────────────────
    dap.adapters.kotlin = {
      type = "executable",
      command = vim.fn.stdpath("data") .. "/mason/packages/kotlin-debug-adapter/adapter/bin/kotlin-debug-adapter",
      args    = {},
    }
  
    -- ── 🐘 PHP ────────────────────────────────────────────────────────────────
    dap.adapters.php = {
      type = "executable",
      command = "node",
      args    = {
        vim.fn.stdpath("data") .. "/mason/packages/php-debug-adapter/extension/out/phpDebug.js",
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗺️  LAUNCH CONFIGURATIONS — per-language debug configs
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function configure_launch(dap)
    -- ── 🦀 Rust ───────────────────────────────────────────────────────────────
    dap.configurations.rust = {
      {
        name    = "🦀 Launch binary",
        type    = "codelldb",
        request = "launch",
        program = function()
          local root = vim.fn.getcwd()
          -- Try to find the binary in target/debug
          local result = vim.fn.glob(root .. "/target/debug/*", false, true)
          local bins   = vim.tbl_filter(function(f)
            return vim.fn.getfperm(f):sub(3, 3) == "x"
          end, result)
          if #bins == 1 then return bins[1] end
          return vim.fn.input("Path to binary: ", root .. "/target/debug/", "file")
        end,
        cwd             = "${workspaceFolder}",
        stopOnEntry     = false,
        args            = function()
          local args_str = vim.fn.input("Args: ")
          return vim.split(args_str, " ", { trimempty = true })
        end,
      },
      {
        name    = "🦀 Attach to process",
        type    = "codelldb",
        request = "attach",
        pid     = require("dap.utils").pick_process,
        cwd     = "${workspaceFolder}",
      },
    }
  
    -- ── ⚙️  C / C++ ──────────────────────────────────────────────────────────
    dap.configurations.c   = dap.configurations.rust
    dap.configurations.cpp = dap.configurations.rust
  
    -- ── 🐹 Go ─────────────────────────────────────────────────────────────────
    dap.configurations.go = {
      {
        name    = "🐹 Debug package",
        type    = "go",
        request = "launch",
        program = "${fileDirname}",
      },
      {
        name    = "🐹 Debug test",
        type    = "go",
        request = "launch",
        mode    = "test",
        program = "${fileDirname}",
      },
      {
        name    = "🐹 Debug test (go.mod)",
        type    = "go",
        request = "launch",
        mode    = "test",
        program = "./${relativeFileDirname}",
      },
      {
        name    = "🐹 Attach to process",
        type    = "go",
        request = "attach",
        mode    = "local",
        processId = require("dap.utils").pick_process,
      },
      {
        name      = "🐹 Debug with args",
        type      = "go",
        request   = "launch",
        program   = "${fileDirname}",
        args      = function()
          return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
        end,
      },
    }
  
    -- ── 📘 TypeScript / JavaScript ────────────────────────────────────────────
    local js_config = {
      {
        name    = "📘 Launch file",
        type    = "pwa-node",
        request = "launch",
        program = "${file}",
        cwd     = "${workspaceFolder}",
        sourceMaps = true,
        resolveSourceMapLocations = {
          "${workspaceFolder}/**",
          "!**/node_modules/**",
        },
      },
      {
        name    = "📘 Launch index.js",
        type    = "pwa-node",
        request = "launch",
        program = "${workspaceFolder}/index.js",
        cwd     = "${workspaceFolder}",
      },
      {
        name    = "📘 Attach (inspect)",
        type    = "pwa-node",
        request = "attach",
        processId = require("dap.utils").pick_process,
        cwd     = "${workspaceFolder}",
        sourceMaps = true,
      },
      {
        name    = "📘 Jest: current file",
        type    = "pwa-node",
        request = "launch",
        runtimeExecutable = "node",
        runtimeArgs       = {
          "./node_modules/jest/bin/jest.js",
          "--runInBand",
          "--testPathPattern",
          "${fileBasename}",
        },
        rootPath = "${workspaceFolder}",
        cwd      = "${workspaceFolder}",
        console  = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      {
        name    = "📘 Vitest: current file",
        type    = "pwa-node",
        request = "launch",
        cwd     = "${workspaceFolder}",
        program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
        args    = { "run", "${file}" },
        console = "integratedTerminal",
        smartStep    = true,
        sourceMaps   = true,
      },
    }
  
    dap.configurations.javascript       = js_config
    dap.configurations.typescript       = js_config
    dap.configurations.javascriptreact  = js_config
    dap.configurations.typescriptreact  = js_config
    dap.configurations.vue              = js_config
    dap.configurations.svelte           = js_config
  
    -- ── 🐚 Bash ───────────────────────────────────────────────────────────────
    dap.configurations.sh = {
      {
        name            = "🐚 Launch bash script",
        type            = "bash",
        request         = "launch",
        program         = "${file}",
        cwd             = "${workspaceFolder}",
        pathBashDebug   = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter",
        pathBash        = "bash",
        pathCat         = "cat",
        pathMkfifo      = "mkfifo",
        pathPkill       = "pkill",
        env             = {},
        args            = {},
        terminalKind    = "integrated",
      },
    }
    dap.configurations.bash = dap.configurations.sh
  
    -- ── ☕ Java ────────────────────────────────────────────────────────────────
    dap.configurations.java = {
      {
        name    = "☕ Debug (attach 5005)",
        type    = "java",
        request = "attach",
        hostName= "localhost",
        port    = 5005,
      },
      {
        name    = "☕ Debug (attach custom)",
        type    = "java",
        request = "attach",
        hostName= function()
          return vim.fn.input("Host [localhost]: ", "localhost")
        end,
        port    = function()
          return tonumber(vim.fn.input("Port [5005]: ", "5005"))
        end,
      },
    }
  
    -- ── 🔷 C# ─────────────────────────────────────────────────────────────────
    dap.configurations.cs = {
      {
        name    = "🔷 Launch .NET project",
        type    = "coreclr",
        request = "launch",
        program = function()
          return vim.fn.input(
            "Path to dll: ",
            vim.fn.getcwd() .. "/bin/Debug/",
            "file"
          )
        end,
      },
    }
  
    -- ── 🐘 PHP ────────────────────────────────────────────────────────────────
    dap.configurations.php = {
      {
        name    = "🐘 PHP: Listen for Xdebug",
        type    = "php",
        request = "launch",
        port    = 9003,
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-dap",
      event        = "VeryLazy",
      dependencies = {
        "williamboman/mason.nvim",
        { "rcarriga/nvim-dap-ui",             optional = true },
        { "theHamsta/nvim-dap-virtual-text",  optional = true },
        { "nvim-telescope/telescope-dap.nvim",optional = true },
        { "jbyuki/one-small-step-for-vimkind",optional = true }, -- Lua DAP
      },
  
      -- ── Keys ────────────────────────────────────────────────────────────────
      keys = {
        -- ── Execution ──────────────────────────────────────────────────────────
        {
          "<F5>",
          smart_continue,
          desc   = "🐛 DAP: Continue / Start",
          silent = true,
        },
        {
          "<F17>",  -- Shift+F5
          function() require("dap").terminate() end,
          desc   = "🐛 DAP: Terminate",
          silent = true,
        },
        {
          "<F29>",  -- Ctrl+F5
          function() require("dap").restart() end,
          desc   = "🐛 DAP: Restart",
          silent = true,
        },
        {
          "<F6>",
          function() require("dap").pause() end,
          desc   = "🐛 DAP: Pause",
          silent = true,
        },
        {
          "<F10>",
          function() require("dap").step_over() end,
          desc   = "🐛 DAP: Step Over",
          silent = true,
        },
        {
          "<F11>",
          function() require("dap").step_into() end,
          desc   = "🐛 DAP: Step Into",
          silent = true,
        },
        {
          "<F23>",  -- Shift+F11
          function() require("dap").step_out() end,
          desc   = "🐛 DAP: Step Out",
          silent = true,
        },
        {
          "<F12>",
          function() require("dap").run_to_cursor() end,
          desc   = "🐛 DAP: Run to Cursor",
          silent = true,
        },
  
        -- ── Breakpoints ────────────────────────────────────────────────────────
        {
          "<leader>db",
          toggle_breakpoint,
          desc   = "🐛 DAP: Toggle Breakpoint",
          silent = true,
        },
        {
          "<leader>dB",
          set_conditional_breakpoint,
          desc   = "🐛 DAP: Conditional Breakpoint",
          silent = true,
        },
        {
          "<leader>dl",
          set_logpoint,
          desc   = "🐛 DAP: Logpoint",
          silent = true,
        },
        {
          "<leader>dh",
          set_hit_breakpoint,
          desc   = "🐛 DAP: Hit Count Breakpoint",
          silent = true,
        },
        {
          "<leader>dx",
          function() require("dap").clear_breakpoints() end,
          desc   = "🐛 DAP: Clear All Breakpoints",
          silent = true,
        },
        {
          "<leader>dq",
          breakpoints_to_qf,
          desc   = "🐛 DAP: Breakpoints → Quickfix",
          silent = true,
        },
  
        -- ── Session ────────────────────────────────────────────────────────────
        {
          "<leader>dc",
          function() require("dap").continue() end,
          desc   = "🐛 DAP: Continue",
          silent = true,
        },
        {
          "<leader>dC",
          function() require("dap").run_to_cursor() end,
          desc   = "🐛 DAP: Run to Cursor",
          silent = true,
        },
        {
          "<leader>do",
          function() require("dap").step_over() end,
          desc   = "🐛 DAP: Step Over",
          silent = true,
        },
        {
          "<leader>di",
          function() require("dap").step_into() end,
          desc   = "🐛 DAP: Step Into",
          silent = true,
        },
        {
          "<leader>dO",
          function() require("dap").step_out() end,
          desc   = "🐛 DAP: Step Out",
          silent = true,
        },
        {
          "<leader>dX",
          function() require("dap").terminate() end,
          desc   = "🐛 DAP: Terminate",
          silent = true,
        },
        {
          "<leader>dr",
          function() require("dap").restart() end,
          desc   = "🐛 DAP: Restart",
          silent = true,
        },
  
        -- ── Inspect ────────────────────────────────────────────────────────────
        {
          "<leader>dk",
          function() require("dap.ui.widgets").hover() end,
          mode   = { "n", "v" },
          desc   = "🐛 DAP: Hover / Inspect",
          silent = true,
        },
        {
          "<leader>dp",
          function()
            local widgets = require("dap.ui.widgets")
            widgets.preview()
          end,
          desc   = "🐛 DAP: Preview",
          silent = true,
        },
        {
          "<leader>df",
          function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.frames)
          end,
          desc   = "🐛 DAP: Frames",
          silent = true,
        },
        {
          "<leader>ds",
          function()
            local widgets = require("dap.ui.widgets")
            widgets.centered_float(widgets.scopes)
          end,
          desc   = "🐛 DAP: Scopes",
          silent = true,
        },
  
        -- ── REPL ───────────────────────────────────────────────────────────────
        {
          "<leader>dR",
          function() require("dap").repl.toggle({ height = 15 }) end,
          desc   = "🐛 DAP: Toggle REPL",
          silent = true,
        },
        {
          "<leader>dL",
          function() require("dap").run_last() end,
          desc   = "🐛 DAP: Run Last",
          silent = true,
        },
  
        -- ── Telescope ──────────────────────────────────────────────────────────
        {
          "<leader>dtc",
          function()
            local ok, tele = pcall(require, "telescope")
            if ok then tele.extensions.dap.commands() end
          end,
          desc   = "🐛 DAP: Commands (Telescope)",
          silent = true,
        },
        {
          "<leader>dtb",
          function()
            local ok, tele = pcall(require, "telescope")
            if ok then tele.extensions.dap.list_breakpoints() end
          end,
          desc   = "🐛 DAP: Breakpoints (Telescope)",
          silent = true,
        },
        {
          "<leader>dtv",
          function()
            local ok, tele = pcall(require, "telescope")
            if ok then tele.extensions.dap.variables() end
          end,
          desc   = "🐛 DAP: Variables (Telescope)",
          silent = true,
        },
        {
          "<leader>dtt",
          function()
            local ok, tele = pcall(require, "telescope")
            if ok then tele.extensions.dap.frames() end
          end,
          desc   = "🐛 DAP: Frames (Telescope)",
          silent = true,
        },
  
        -- ── Persistence ────────────────────────────────────────────────────────
        {
          "<leader>dw",
          function()
            save_breakpoints()
            vim.notify("🐛 Breakpoints saved", vim.log.levels.INFO, { title = "DAP" })
          end,
          desc   = "🐛 DAP: Save Breakpoints",
          silent = true,
        },
        {
          "<leader>dW",
          function()
            load_breakpoints()
            vim.notify("🐛 Breakpoints loaded", vim.log.levels.INFO, { title = "DAP" })
          end,
          desc   = "🐛 DAP: Load Breakpoints",
          silent = true,
        },
      },
  
      config = function()
        local dap = require("dap")
  
        -- Apply highlights and signs
        setup_highlights()
        register_signs()
  
        -- Configure adapters and launch configs
        configure_adapters(dap)
        configure_launch(dap)
  
        -- ── DAP event listeners ───────────────────────────────────────────────
  
        -- Session start
        dap.listeners.before.event_initialized["ash"] = function()
          _dap_status = " 🐛 Debugging"
          vim.notify(
            "🐛 Debug session started",
            vim.log.levels.INFO,
            { title = "DAP", timeout = 1500 }
          )
          -- Open DAP UI if available
          local ok, dapui = pcall(require, "dapui")
          if ok then dapui.open() end
        end
  
        -- Session terminated
        dap.listeners.before.event_terminated["ash"] = function()
          _dap_status = ""
          vim.notify(
            "🐛 Debug session terminated",
            vim.log.levels.INFO,
            { title = "DAP", timeout = 1500 }
          )
          local ok, dapui = pcall(require, "dapui")
          if ok then dapui.close() end
        end
  
        -- Session exited
        dap.listeners.before.event_exited["ash"] = function(_, body)
          _dap_status = ""
          local code = body and body.exitCode or 0
          vim.notify(
            string.format("🐛 Debug process exited (code: %d)", code),
            code ~= 0 and vim.log.levels.WARN or vim.log.levels.INFO,
            { title = "DAP", timeout = 2000 }
          )
          local ok, dapui = pcall(require, "dapui")
          if ok then dapui.close() end
        end
  
        -- Stopped (breakpoint hit)
        dap.listeners.after.event_stopped["ash"] = function(_, body)
          if body and body.reason then
            local reason_map = {
              breakpoint   = "🔴 Breakpoint hit",
              step         = "⏸ Stepped",
              exception    = "💥 Exception",
              pause        = "⏸ Paused",
              entry        = "🚀 Entry point",
              goto         = "⏩ Goto",
              ["function breakpoint"] = "🔴 Function breakpoint",
            }
            _dap_status = string.format(" 🐛 %s", reason_map[body.reason] or body.reason)
          end
        end
  
        -- Output (route DAP stdout to dap-repl)
        dap.listeners.after.event_output["ash"] = function(_, body)
          if body.category == "important" then
            vim.notify(
              "🐛 " .. (body.output or ""),
              vim.log.levels.WARN,
              { title = "DAP Output" }
            )
          end
        end
  
        -- ── Telescope extension ───────────────────────────────────────────────
        local ok_tele, tele = pcall(require, "telescope")
        if ok_tele then
          pcall(tele.load_extension, "dap")
        end
  
        -- ── Expose statusline component ────────────────────────────────────────
        _G.AshDapStatus = function()
          return _dap_status
        end
  
        -- ── Autocmds ──────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshDap", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = function()
            setup_highlights()
            register_signs()
          end,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            register_signs()
            vim.notify(
              "🐛 DAP highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH DAP", timeout = 1200 }
            )
          end,
        })
  
        -- Auto-save breakpoints on session end
        vim.api.nvim_create_autocmd("VimLeave", {
          group    = aug,
          callback = save_breakpoints,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🐛 DAP loaded — adapters: codelldb, debugpy, delve, pwa-node, bash",
            vim.log.levels.DEBUG,
            { title = "ASH DAP" }
          )
        end
      end,
    },
  }