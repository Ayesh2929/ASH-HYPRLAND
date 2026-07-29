-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐍 DAP-PYTHON — ULTRA PYTHON DEBUGGER v5.0 OMEGA                         ║
-- ║   debugpy · pytest · Django · FastAPI · virtualenv · conda · pipenv            ║
-- ║   test runners · profiling · remote attach · ASH theme-synced                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 PYTHON ENVIRONMENT DETECTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Find the best Python executable for the current project
local function find_python()
    local cwd = vim.fn.getcwd()
  
    -- Priority order: project venv → conda → pyenv → system
    local candidates = {
      -- Virtual environment
      cwd .. "/.venv/bin/python",
      cwd .. "/venv/bin/python",
      cwd .. "/.env/bin/python",
  
      -- Conda
      (os.getenv("CONDA_PREFIX") or "") .. "/bin/python",
  
      -- Pyenv
      (os.getenv("PYENV_ROOT") or (os.getenv("HOME") or "") .. "/.pyenv")
        .. "/shims/python",
  
      -- Mason debugpy venv
      vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
  
      -- System
      "/usr/bin/python3",
      "/usr/local/bin/python3",
    }
  
    for _, candidate in ipairs(candidates) do
      if candidate ~= "" and vim.fn.executable(candidate) == 1 then
        return candidate
      end
    end
  
    -- Last resort: which python3
    local which = vim.fn.trim(vim.fn.system("which python3 2>/dev/null"))
    if which ~= "" then return which end
  
    return "python3"
  end
  
  -- Find debugpy path
  local function find_debugpy()
    local mason_debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
    if vim.fn.executable(mason_debugpy) == 1 then
      return mason_debugpy
    end
  
    -- Try to find debugpy in current venv
    local python = find_python()
    local check  = vim.fn.system(python .. " -c 'import debugpy; print(debugpy.__file__)' 2>/dev/null")
    if vim.v.shell_error == 0 and check ~= "" then
      return python
    end
  
    return mason_debugpy
  end
  
  -- Detect test framework
  local function detect_test_framework()
    local cwd = vim.fn.getcwd()
  
    -- Check config files
    if vim.fn.filereadable(cwd .. "/pytest.ini")     == 1 then return "pytest" end
    if vim.fn.filereadable(cwd .. "/setup.cfg")      == 1 then
      local content = io.open(cwd .. "/setup.cfg", "r"):read("*a")
      if content:find("%[tool:pytest%]") then return "pytest" end
    end
    if vim.fn.filereadable(cwd .. "/pyproject.toml") == 1 then
      local content = io.open(cwd .. "/pyproject.toml", "r"):read("*a")
      if content:find("%[tool%.pytest") then return "pytest" end
      if content:find("%[tool%.unittest") then return "unittest" end
    end
  
    -- Default to pytest
    return "pytest"
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART DEBUG ACTIONS — Python-specific
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Debug current pytest test under cursor
  local function debug_test_at_cursor()
    local ok, dap_python = pcall(require, "dap-python")
    if not ok then
      vim.notify("🐍 dap-python not available", vim.log.levels.WARN, { title = "DAP Python" })
      return
    end
  
    dap_python.test_method({
      config = {
        justMyCode = false,
        env        = {
          PYTHONPATH = vim.fn.getcwd(),
        },
      },
    })
  end
  
  -- Debug entire test class
  local function debug_test_class()
    local ok, dap_python = pcall(require, "dap-python")
    if not ok then return end
    dap_python.test_class()
  end
  
  -- Debug test file
  local function debug_test_file()
    local ok, dap = pcall(require, "dap")
    if not ok then return end
  
    local file = vim.api.nvim_buf_get_name(0)
    dap.run({
      name       = "🐍 Debug test file",
      type       = "python",
      request    = "launch",
      module     = "pytest",
      args       = { file, "-v", "--no-header", "-rN" },
      cwd        = vim.fn.getcwd(),
      justMyCode = false,
      env        = { PYTHONPATH = vim.fn.getcwd() },
      console    = "integratedTerminal",
    })
  end
  
  -- Quick debug: run current file
  local function debug_current_file()
    local ok, dap = pcall(require, "dap")
    if not ok then return end
  
    local file   = vim.api.nvim_buf_get_name(0)
    local python = find_python()
  
    dap.run({
      name       = "🐍 " .. vim.fn.fnamemodify(file, ":t"),
      type       = "python",
      request    = "launch",
      program    = file,
      python     = python,
      cwd        = vim.fn.getcwd(),
      args       = function()
        return vim.split(vim.fn.input("Args: "), " ", { trimempty = true })
      end,
      justMyCode  = true,
      console    = "integratedTerminal",
      env        = {
        PYTHONPATH  = vim.fn.getcwd(),
        PYTHONUNBUFFERED = "1",
      },
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-dap-python",
      ft           = { "python" },
      dependencies = {
        "mfussenegger/nvim-dap",
        { "rcarriga/nvim-dap-ui", optional = true },
      },
  
      keys = {
        -- ── Test runner shortcuts ──────────────────────────────────────────────
        {
          "<leader>dtm",
          debug_test_at_cursor,
          ft     = "python",
          desc   = "🐍 DAP: Debug test method",
          silent = true,
        },
        {
          "<leader>dtC",
          debug_test_class,
          ft     = "python",
          desc   = "🐍 DAP: Debug test class",
          silent = true,
        },
        {
          "<leader>dtf",
          debug_test_file,
          ft     = "python",
          desc   = "🐍 DAP: Debug test file",
          silent = true,
        },
        {
          "<leader>dpy",
          debug_current_file,
          ft     = "python",
          desc   = "🐍 DAP: Debug current file",
          silent = true,
        },
        -- Show detected python info
        {
          "<leader>dpi",
          function()
            local python  = find_python()
            local debugpy = find_debugpy()
            local fw      = detect_test_framework()
            vim.notify(
              table.concat({
                "🐍 Python Debug Info",
                "─────────────────────────────────",
                string.format("  Python:     %s", python),
                string.format("  debugpy:    %s", debugpy),
                string.format("  Framework:  %s", fw),
                string.format("  PYTHONPATH: %s", vim.fn.getcwd()),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "DAP Python" }
            )
          end,
          ft     = "python",
          desc   = "🐍 DAP: Python debug info",
          silent = true,
        },
      },
  
      config = function()
        local dap_python = require("dap-python")
  
        -- Setup with the best available debugpy
        local debugpy_python = find_debugpy()
        dap_python.setup(debugpy_python)
  
        -- ── Test runner configuration ─────────────────────────────────────────
        dap_python.test_runner = detect_test_framework()
  
        -- ── Custom launch configurations ──────────────────────────────────────
        local dap     = require("dap")
        local python  = find_python()
        local cwd     = vim.fn.getcwd()
  
        -- Extend the default python configurations
        dap.configurations.python = vim.list_extend(
          dap.configurations.python or {},
          {
            -- ── Run current file ─────────────────────────────────────────────
            {
              name       = "🐍 Launch: current file",
              type       = "python",
              request    = "launch",
              program    = "${file}",
              python     = python,
              cwd        = "${workspaceFolder}",
              justMyCode = true,
              env        = {
                PYTHONPATH       = "${workspaceFolder}",
                PYTHONUNBUFFERED = "1",
              },
              console    = "integratedTerminal",
            },
  
            -- ── Run with arguments ────────────────────────────────────────────
            {
              name       = "🐍 Launch: with args",
              type       = "python",
              request    = "launch",
              program    = "${file}",
              python     = python,
              args       = function()
                return vim.split(
                  vim.fn.input("Arguments: "),
                  " ",
                  { trimempty = true }
                )
              end,
              cwd        = "${workspaceFolder}",
              justMyCode = true,
              env        = { PYTHONPATH = "${workspaceFolder}" },
              console    = "integratedTerminal",
            },
  
            -- ── pytest ────────────────────────────────────────────────────────
            {
              name       = "🐍 pytest: current file",
              type       = "python",
              request    = "launch",
              module     = "pytest",
              args       = { "${file}", "-v", "--no-header", "-rN" },
              cwd        = "${workspaceFolder}",
              justMyCode = false,
              env        = {
                PYTHONPATH       = "${workspaceFolder}",
                PYTHONUNBUFFERED = "1",
              },
              console    = "integratedTerminal",
            },
            {
              name       = "🐍 pytest: all tests",
              type       = "python",
              request    = "launch",
              module     = "pytest",
              args       = { "-v", "--no-header", "-rN" },
              cwd        = "${workspaceFolder}",
              justMyCode = false,
              env        = { PYTHONPATH = "${workspaceFolder}" },
              console    = "integratedTerminal",
            },
            {
              name       = "🐍 pytest: with args",
              type       = "python",
              request    = "launch",
              module     = "pytest",
              args       = function()
                return vim.split(
                  vim.fn.input("pytest args: ", "-v "),
                  " ",
                  { trimempty = true }
                )
              end,
              cwd        = "${workspaceFolder}",
              justMyCode = false,
              console    = "integratedTerminal",
            },
  
            -- ── FastAPI / Uvicorn ─────────────────────────────────────────────
            {
              name       = "🐍 FastAPI: uvicorn",
              type       = "python",
              request    = "launch",
              module     = "uvicorn",
              args       = function()
                local module = vim.fn.input(
                  "App module [app.main:app]: ", "app.main:app"
                )
                return { module, "--reload", "--host", "0.0.0.0", "--port", "8000" }
              end,
              cwd        = "${workspaceFolder}",
              justMyCode = false,
              env        = {
                PYTHONPATH       = "${workspaceFolder}",
                PYTHONUNBUFFERED = "1",
              },
              console    = "integratedTerminal",
            },
  
            -- ── Django ────────────────────────────────────────────────────────
            {
              name       = "🐍 Django: runserver",
              type       = "python",
              request    = "launch",
              program    = "${workspaceFolder}/manage.py",
              args       = { "runserver", "--noreload" },
              django     = true,
              cwd        = "${workspaceFolder}",
              justMyCode = true,
              env        = {
                DJANGO_SETTINGS_MODULE = function()
                  return vim.fn.input(
                    "Settings module: ", "config.settings.local"
                  )
                end,
                PYTHONPATH       = "${workspaceFolder}",
                PYTHONUNBUFFERED = "1",
              },
              console    = "integratedTerminal",
            },
  
            -- ── Flask ─────────────────────────────────────────────────────────
            {
              name       = "🐍 Flask: run",
              type       = "python",
              request    = "launch",
              module     = "flask",
              args       = { "run", "--no-debugger", "--port", "5000" },
              env        = {
                FLASK_APP        = function()
                  return vim.fn.input("FLASK_APP [app.py]: ", "app.py")
                end,
                FLASK_ENV        = "development",
                PYTHONUNBUFFERED = "1",
                PYTHONPATH       = "${workspaceFolder}",
              },
              cwd        = "${workspaceFolder}",
              justMyCode = true,
              console    = "integratedTerminal",
            },
  
            -- ── Remote attach ─────────────────────────────────────────────────
            {
              name    = "🐍 Attach: remote debugpy",
              type    = "python",
              request = "attach",
              connect = {
                host = function()
                  return vim.fn.input("Host [localhost]: ", "localhost")
                end,
                port = function()
                  return tonumber(vim.fn.input("Port [5678]: ", "5678"))
                end,
              },
              justMyCode = false,
              pathMappings = {
                {
                  localRoot  = "${workspaceFolder}",
                  remoteRoot = function()
                    return vim.fn.input("Remote root [/app]: ", "/app")
                  end,
                },
              },
            },
  
            -- ── Module run ────────────────────────────────────────────────────
            {
              name    = "🐍 Launch: module",
              type    = "python",
              request = "launch",
              module  = function()
                return vim.fn.input("Module name: ")
              end,
              cwd     = "${workspaceFolder}",
              env     = { PYTHONPATH = "${workspaceFolder}" },
              console = "integratedTerminal",
            },
  
            -- ── Script with profiling ─────────────────────────────────────────
            {
              name       = "🐍 Profile: cProfile",
              type       = "python",
              request    = "launch",
              module     = "cProfile",
              args       = function()
                local file = vim.fn.input("Script: ", "${file}")
                local out  = vim.fn.input("Output [/tmp/profile.stats]: ", "/tmp/profile.stats")
                return { "-o", out, file }
              end,
              cwd        = "${workspaceFolder}",
              justMyCode = true,
              console    = "integratedTerminal",
            },
          }
        )
  
        -- ── Notify on successful setup ────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshDapPython", { clear = true })
  
        -- Re-detect Python when switching to a new project directory
        vim.api.nvim_create_autocmd("DirChanged", {
          group    = aug,
          callback = function()
            -- Re-setup with new venv if available
            local new_python = find_debugpy()
            pcall(dap_python.setup, new_python)
            dap_python.test_runner = detect_test_framework()
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "🐍 DAP Python loaded\n  Python:    %s\n  debugpy:   %s\n  Runner:    %s",
              find_python(),
              find_debugpy(),
              detect_test_framework()
            ),
            vim.log.levels.DEBUG,
            { title = "ASH DAP Python" }
          )
        end
      end,
    },
  }