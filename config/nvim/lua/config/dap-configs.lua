-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐛 DAP CONFIGURATIONS — ASH CONFIG v5.0 OMEGA                            ║
-- ║   Adapters · launch configs · per-language settings · mason paths              ║
-- ║   codelldb · debugpy · delve · js-debug · bash · all languages                ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📁 MASON PATHS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local mason = vim.fn.stdpath("data") .. "/mason"

local paths = {
  codelldb   = mason .. "/packages/codelldb/extension/adapter/codelldb",
  liblldb    = mason .. "/packages/codelldb/extension/lldb/lib/liblldb"
               .. (vim.fn.has("mac") == 1 and ".dylib" or ".so"),
  debugpy    = mason .. "/packages/debugpy/venv/bin/python",
  delve      = mason .. "/packages/delve/delve",
  js_debug   = mason .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
  bash_debug = mason .. "/packages/bash-debug-adapter/bash-debug-adapter",
  bash_pkg   = mason .. "/packages/bash-debug-adapter",
  java_debug = vim.fn.glob(
    mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
    false, true
  ),
  java_test  = vim.fn.glob(
    mason .. "/packages/java-test/extension/server/*.jar",
    false, true
  ),
  netcoredbg = mason .. "/packages/netcoredbg/netcoredbg",
  codelldb_php = mason .. "/packages/php-debug-adapter/extension/out/phpDebug.js",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 ADAPTER DEFINITIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@return table
function M.get_adapters()
  return {
    -- ── CodeLLDB (Rust / C / C++) ────────────────────────────────────────────
    codelldb = {
      type = "server",
      port = "${port}",
      host = "127.0.0.1",
      executable = {
        command = paths.codelldb,
        args    = { "--port", "${port}" },
      },
    },

    -- ── debugpy (Python) ──────────────────────────────────────────────────────
    python = function(cb, config)
      if config.request == "attach" then
        local port = (config.connect or config).port
        local host = (config.connect or config).host or "127.0.0.1"
        cb({
          type    = "server",
          port    = assert(port, "`connect.port` required for Python attach"),
          host    = host,
          options = { source_filetype = "python" },
        })
      else
        cb({
          type    = "executable",
          command = (function()
            -- Prefer venv
            for _, v in ipairs({
              os.getenv("VIRTUAL_ENV"), os.getenv("CONDA_PREFIX"),
              vim.fn.getcwd() .. "/.venv",
              vim.fn.getcwd() .. "/venv",
            }) do
              if v and v ~= "" then
                local p = v .. "/bin/python"
                if vim.fn.executable(p) == 1 then return p end
              end
            end
            return paths.debugpy
          end)(),
          args    = { "-m", "debugpy.adapter" },
          options = { source_filetype = "python" },
        })
      end
    end,

    -- ── Delve (Go) ────────────────────────────────────────────────────────────
    go = {
      type = "server",
      port = "${port}",
      executable = {
        command = paths.delve,
        args    = { "dap", "-l", "127.0.0.1:${port}" },
      },
    },

    -- ── js-debug (Node / TypeScript) ─────────────────────────────────────────
    ["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args    = { paths.js_debug, "${port}" },
      },
    },

    -- ── Bash ──────────────────────────────────────────────────────────────────
    bash = {
      type    = "executable",
      command = paths.bash_debug,
      args    = {},
    },

    -- ── Java ──────────────────────────────────────────────────────────────────
    java = {
      type = "server",
      host = "127.0.0.1",
      port = 5005,
    },

    -- ── .NET ─────────────────────────────────────────────────────────────────
    coreclr = {
      type    = "executable",
      command = paths.netcoredbg,
      args    = { "--interpreter=vscode" },
    },

    -- ── PHP ───────────────────────────────────────────────────────────────────
    php = {
      type    = "executable",
      command = "node",
      args    = { paths.codelldb_php },
    },

    -- ── Chrome ────────────────────────────────────────────────────────────────
    ["pwa-chrome"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args    = { paths.js_debug, "${port}" },
      },
    },
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🚀 LAUNCH CONFIGURATIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local pick_process = function()
  return require("dap.utils").pick_process()
end

local function prompt(msg, default)
  return function()
    return vim.fn.input(msg, default or "")
  end
end

---@return table<string, table[]>
function M.get_configurations()
  -- Shared source map options for JS/TS
  local js_source_maps = {
    sourceMaps = true,
    resolveSourceMapLocations = {
      "${workspaceFolder}/**",
      "!**/node_modules/**",
    },
  }

  -- JS / TS config set
  local js_configs = {
    {
      name    = "⚡ Launch file",
      type    = "pwa-node",
      request = "launch",
      program = "${file}",
      cwd     = "${workspaceFolder}",
      vim.tbl_extend("force", js_source_maps, {}),
    },
    {
      name    = "⚡ Attach (inspect)",
      type    = "pwa-node",
      request = "attach",
      processId = pick_process,
      cwd     = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      name    = "⚡ Jest: current file",
      type    = "pwa-node",
      request = "launch",
      runtimeExecutable = "node",
      runtimeArgs = {
        "${workspaceFolder}/node_modules/jest/bin/jest.js",
        "--runInBand", "--testPathPattern", "${fileBasename}",
        "--forceExit",
      },
      rootPath = "${workspaceFolder}",
      cwd      = "${workspaceFolder}",
      console  = "integratedTerminal",
      sourceMaps = true,
    },
    {
      name    = "⚡ Vitest: current file",
      type    = "pwa-node",
      request = "launch",
      cwd     = "${workspaceFolder}",
      program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
      args    = { "run", "${file}" },
      console = "integratedTerminal",
      smartStep   = true,
      sourceMaps  = true,
    },
    {
      name    = "⚡ Chrome: launch",
      type    = "pwa-chrome",
      request = "launch",
      url     = prompt("URL [http://localhost:3000]: ", "http://localhost:3000"),
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
  }

  return {
    -- ── Rust ─────────────────────────────────────────────────────────────────
    rust = {
      {
        name    = "🦀 Launch binary",
        type    = "codelldb",
        request = "launch",
        program = function()
          local bins = vim.fn.glob(vim.fn.getcwd() .. "/target/debug/*", false, true)
          bins = vim.tbl_filter(function(f)
            return vim.fn.getfperm(f):sub(3,3) == "x"
              and vim.fn.isdirectory(f) == 0
          end, bins)
          if #bins == 1 then return bins[1] end
          return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
        end,
        cwd         = "${workspaceFolder}",
        stopOnEntry = false,
        args        = function()
          return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
        end,
      },
      {
        name    = "🦀 Attach process",
        type    = "codelldb",
        request = "attach",
        pid     = pick_process,
        cwd     = "${workspaceFolder}",
      },
    },

    -- ── C / C++ ────────────────────────────────────────────────────────────
    c   = {
      {
        name    = "⚙️  Launch",
        type    = "codelldb",
        request = "launch",
        program = prompt("Binary: ", vim.fn.getcwd() .. "/build/"),
        cwd     = "${workspaceFolder}",
        stopOnEntry = false,
      },
      {
        name    = "⚙️  Attach",
        type    = "codelldb",
        request = "attach",
        pid     = pick_process,
        cwd     = "${workspaceFolder}",
      },
    },
    cpp = nil,  -- filled below

    -- ── Python ────────────────────────────────────────────────────────────────
    python = {
      {
        name       = "🐍 Launch file",
        type       = "python",
        request    = "launch",
        program    = "${file}",
        pythonPath = function()
          local venv = os.getenv("VIRTUAL_ENV")
          if venv then return venv .. "/bin/python" end
          return vim.fn.exepath("python3") or "python3"
        end,
        cwd        = "${workspaceFolder}",
        justMyCode = true,
        console    = "integratedTerminal",
        env        = {
          PYTHONPATH       = "${workspaceFolder}",
          PYTHONUNBUFFERED = "1",
        },
      },
      {
        name   = "🐍 pytest: current file",
        type   = "python",
        request= "launch",
        module = "pytest",
        args   = { "${file}", "-v", "--no-header", "-rN" },
        cwd    = "${workspaceFolder}",
        justMyCode = false,
        console    = "integratedTerminal",
        env        = { PYTHONPATH = "${workspaceFolder}" },
      },
      {
        name    = "🐍 Attach remote",
        type    = "python",
        request = "attach",
        connect = {
          host = prompt("Host [localhost]: ", "localhost"),
          port = function() return tonumber(vim.fn.input("Port [5678]: ", "5678")) end,
        },
        justMyCode = false,
      },
      {
        name    = "🐍 FastAPI: uvicorn",
        type    = "python",
        request = "launch",
        module  = "uvicorn",
        args    = function()
          local m = vim.fn.input("App module [app.main:app]: ", "app.main:app")
          return { m, "--reload", "--host", "0.0.0.0", "--port", "8000" }
        end,
        cwd    = "${workspaceFolder}",
        justMyCode = false,
        console    = "integratedTerminal",
        env        = { PYTHONPATH = "${workspaceFolder}", PYTHONUNBUFFERED = "1" },
      },
    },

    -- ── Go ────────────────────────────────────────────────────────────────────
    go = {
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
        args    = { "-test.v" },
      },
      {
        name    = "🐹 Attach process",
        type    = "go",
        request = "attach",
        mode    = "local",
        processId = pick_process,
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
    },

    -- ── JavaScript / TypeScript ────────────────────────────────────────────
    javascript      = js_configs,
    typescript      = js_configs,
    javascriptreact = js_configs,
    typescriptreact = js_configs,

    -- ── Bash ──────────────────────────────────────────────────────────────────
    sh = {
      {
        name            = "🐚 Launch script",
        type            = "bash",
        request         = "launch",
        program         = "${file}",
        cwd             = "${fileDirname}",
        pathBashDebug   = paths.bash_pkg,
        pathBash        = vim.fn.exepath("bash") or "bash",
        pathCat         = "cat",
        pathMkfifo      = "mkfifo",
        pathPkill       = "pkill",
        args            = {},
        env             = {},
        terminalKind    = "integrated",
        showDebugOutput = false,
      },
    },

    -- ── Java ──────────────────────────────────────────────────────────────────
    java = {
      {
        name    = "☕ Debug (attach 5005)",
        type    = "java",
        request = "attach",
        hostName= "localhost",
        port    = 5005,
      },
    },

    -- ── .NET ─────────────────────────────────────────────────────────────────
    cs = {
      {
        name    = "🔷 Launch .NET",
        type    = "coreclr",
        request = "launch",
        program = prompt("DLL: ", vim.fn.getcwd() .. "/bin/Debug/"),
      },
    },

    -- ── PHP ───────────────────────────────────────────────────────────────────
    php = {
      {
        name    = "🐘 Listen for Xdebug",
        type    = "php",
        request = "launch",
        port    = 9003,
      },
    },
  }
end

-- Post-process: C++ inherits C
local function finalize(configs)
  configs.cpp  = configs.c
  configs.bash = configs.sh
  return configs
end

---Setup DAP adapters and configurations
function M.setup()
  local ok, dap = pcall(require, "dap")
  if not ok then return end

  -- Adapters
  local adapters = M.get_adapters()
  for name, cfg in pairs(adapters) do
    dap.adapters[name] = cfg
  end
  -- Node alias
  dap.adapters.node = dap.adapters["pwa-node"]

  -- Configurations
  local configs = finalize(M.get_configurations())
  for ft, cfgs in pairs(configs) do
    if cfgs then
      dap.configurations[ft] = cfgs
    end
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 MASON ENSURE INSTALLED (DAP adapters)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.mason_ensure = {
  "codelldb",           -- Rust / C / C++
  "debugpy",            -- Python
  "delve",              -- Go
  "js-debug-adapter",   -- Node / TypeScript
  "bash-debug-adapter", -- Bash
  "java-debug-adapter", -- Java
  "java-test",          -- Java tests
  "netcoredbg",         -- .NET
  "php-debug-adapter",  -- PHP
  "kotlin-debug-adapter",
}

return M