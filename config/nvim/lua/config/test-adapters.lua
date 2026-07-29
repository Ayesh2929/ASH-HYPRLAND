-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🧪 TEST ADAPTERS — ASH CONFIG v5.0 OMEGA                                 ║
-- ║   neotest adapters · per-language test runners · discovery settings            ║
-- ║   pytest · jest · vitest · go · rust · bash · elixir · zig                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function exe(name)
  return vim.fn.executable(name) == 1
end

-- Detect npm/yarn/pnpm/bun package manager
local function detect_pm()
  local cwd = vim.fn.getcwd()
  if vim.fn.filereadable(cwd .. "/pnpm-lock.yaml") == 1 then return "pnpm" end
  if vim.fn.filereadable(cwd .. "/yarn.lock")      == 1 then return "yarn" end
  if vim.fn.filereadable(cwd .. "/bun.lockb")      == 1 then return "bun"  end
  return "npm"
end

-- Find test runner in local node_modules or system
local function find_runner(runner)
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. "/node_modules/.bin/" .. runner,
    cwd .. "/node_modules/." .. runner .. "/bin/" .. runner .. ".mjs",
  }
  for _, c in ipairs(candidates) do
    if vim.fn.executable(c) == 1 or vim.fn.filereadable(c) == 1 then return c end
  end
  return runner
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📋 ADAPTER BUILDER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---Build the list of available neotest adapters
---@return table[]
function M.build_adapters()
  local adapters = {}

  -- ── Python: pytest ─────────────────────────────────────────────────────────
  local ok_py, neotest_python = pcall(require, "neotest-python")
  if ok_py then
    table.insert(adapters, neotest_python({
      dap          = { justMyCode = false },
      args         = { "--log-level=DEBUG", "-v", "--tb=short" },
      runner       = "pytest",
      python       = (function()
        for _, venv in ipairs({
          os.getenv("VIRTUAL_ENV"), os.getenv("CONDA_PREFIX"),
          vim.fn.getcwd() .. "/.venv",
          vim.fn.getcwd() .. "/venv",
        }) do
          if venv and venv ~= "" then
            local py = venv .. "/bin/python"
            if exe(py) then return py end
          end
        end
        return vim.fn.exepath("python3") or "python3"
      end)(),
      is_test_file = function(file)
        return file:match("test_.*%.py$") ~= nil
          or file:match(".*_test%.py$") ~= nil
          or file:match("tests/.*%.py$") ~= nil
      end,
    }))
  end

  -- ── Go: neotest-go ─────────────────────────────────────────────────────────
  local ok_go, neotest_go = pcall(require, "neotest-go")
  if ok_go then
    table.insert(adapters, neotest_go({
      experimental = { test_table = true },
      args         = { "-count=1", "-timeout=60s", "-v" },
    }))
  end

  -- ── Jest ──────────────────────────────────────────────────────────────────
  local ok_jest, neotest_jest = pcall(require, "neotest-jest")
  if ok_jest then
    table.insert(adapters, neotest_jest({
      jestCommand    = function()
        local pm = detect_pm()
        return pm .. " test --"
      end,
      jestConfigFile = function()
        local configs = {
          "jest.config.ts", "jest.config.js", "jest.config.mjs", "jest.config.cjs",
        }
        for _, cfg in ipairs(configs) do
          local path = vim.fn.getcwd() .. "/" .. cfg
          if vim.fn.filereadable(path) == 1 then return path end
        end
      end,
      env        = { CI = true },
      cwd        = function() return vim.fn.getcwd() end,
      ignore_dirs= { "node_modules", ".git", "dist", "build" },
      filter_dir = function(name) return name ~= "node_modules" end,
    }))
  end

  -- ── Vitest ────────────────────────────────────────────────────────────────
  local ok_vt, neotest_vitest = pcall(require, "neotest-vitest")
  if ok_vt then
    table.insert(adapters, neotest_vitest({
      filter_dir = function(name) return name ~= "node_modules" end,
      is_test_file = function(file)
        return file:match("%.test%.[jt]sx?$") ~= nil
          or file:match("%.spec%.[jt]sx?$") ~= nil
          or file:match("__tests__/") ~= nil
      end,
    }))
  end

  -- ── Rust: neotest-rust ─────────────────────────────────────────────────────
  local ok_rs, neotest_rust = pcall(require, "neotest-rust")
  if ok_rs then
    table.insert(adapters, neotest_rust({
      args     = { "--no-capture" },
      dap      = { adapter = "codelldb" },
    }))
  end

  -- ── Bash: neotest-bash ────────────────────────────────────────────────────
  local ok_bash, neotest_bash = pcall(require, "neotest-bash")
  if ok_bash then
    table.insert(adapters, neotest_bash())
  end

  -- ── Elixir ────────────────────────────────────────────────────────────────
  local ok_ex, neotest_elixir = pcall(require, "neotest-elixir")
  if ok_ex then
    table.insert(adapters, neotest_elixir())
  end

  -- ── Zig ───────────────────────────────────────────────────────────────────
  local ok_zig, neotest_zig = pcall(require, "neotest-zig")
  if ok_zig then
    table.insert(adapters, neotest_zig())
  end

  -- ── Deno ──────────────────────────────────────────────────────────────────
  local ok_deno, neotest_deno = pcall(require, "neotest-deno")
  if ok_deno then
    table.insert(adapters, neotest_deno())
  end

  -- ── Plenary (Neovim plugin tests) ─────────────────────────────────────────
  local ok_pl, neotest_plenary = pcall(require, "neotest-plenary")
  if ok_pl then
    table.insert(adapters, neotest_plenary())
  end

  return adapters
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  NEOTEST CORE CONFIG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Nerd Font v3 test icons
local ICONS = {
  passed    = " ",
  failed    = " ",
  running   = "󰔟 ",
  skipped   = "󰒉 ",
  unknown   = "󰋖 ",
  running_animated = { "⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏" },
}

---Build neotest options table
---@return table
function M.build_opts()
  return {
    adapters = M.build_adapters(),

    -- ── Status ────────────────────────────────────────────────────────────────
    status = {
      virtual_text = true,
      signs        = true,
      enabled      = true,
    },

    -- ── Output ────────────────────────────────────────────────────────────────
    output = {
      enabled     = true,
      open_on_run = "short",
    },

    -- ── Output panel ──────────────────────────────────────────────────────────
    output_panel = {
      enabled = true,
      open    = "botright split | resize 14",
    },

    -- ── Summary ───────────────────────────────────────────────────────────────
    summary = {
      enabled       = true,
      animated      = true,
      follow        = true,
      expand_errors = true,
      open          = "botright vsplit | vertical resize 45",
      mappings      = {
        attach       = "a",
        clear_marked = "M",
        clear_target = "T",
        debug        = "d",
        debug_marked = "D",
        expand       = { "<cr>", "<2-LeftMouse>" },
        expand_all   = "e",
        help         = "?",
        jump         = "i",
        mark         = "m",
        next_failed  = "J",
        output       = "o",
        prev_failed  = "K",
        run          = "r",
        run_marked   = "R",
        short        = "O",
        stop         = "u",
        target       = "t",
        watch        = "w",
      },
    },

    -- ── Icons ──────────────────────────────────────────────────────────────────
    icons = {
      child_indent    = "│",
      child_prefix    = "├",
      collapsed       = "",
      expanded        = "",
      failed          = ICONS.failed,
      final_child_indent = " ",
      final_child_prefix = "└",
      non_collapsible = "─",
      notify          = "󰵆",
      passed          = ICONS.passed,
      running         = ICONS.running,
      running_animated= ICONS.running_animated,
      skipped         = ICONS.skipped,
      unknown         = ICONS.unknown,
      watching        = "󰈈",
    },

    -- ── Highlight groups ───────────────────────────────────────────────────────
    highlights = {
      adapter_name    = "NeotestAdapterName",
      border          = "NeotestBorder",
      dir             = "NeotestDir",
      expand_marker   = "NeotestExpandMarker",
      failed          = "NeotestFailed",
      file            = "NeotestFile",
      focused         = "NeotestFocused",
      indent          = "NeotestIndent",
      marked          = "NeotestMarked",
      namespace       = "NeotestNamespace",
      passed          = "NeotestPassed",
      running         = "NeotestRunning",
      select_win      = "NeotestWinSelect",
      skipped         = "NeotestSkipped",
      target          = "NeotestTarget",
      test            = "NeotestTest",
      unknown         = "NeotestUnknown",
      watching        = "NeotestWatching",
    },

    -- ── State ─────────────────────────────────────────────────────────────────
    state      = { enabled = true },

    -- ── Discovery ─────────────────────────────────────────────────────────────
    discovery  = {
      concurrent  = 10,
      enabled     = true,
      filter_dir  = function(name)
        return not vim.tbl_contains({
          "node_modules", ".git", "dist", "build",
          "target", ".venv", "venv", "__pycache__",
          ".next", ".turbo", ".cache",
        }, name)
      end,
    },

    -- ── Running ───────────────────────────────────────────────────────────────
    running    = { concurrent = true },

    -- ── Diagnostic ────────────────────────────────────────────────────────────
    diagnostic = { enabled = true, severity = vim.diagnostic.severity.ERROR },

    -- ── Quickfix ─────────────────────────────────────────────────────────────
    quickfix   = { enabled = false, open = false },

    -- ── Log ──────────────────────────────────────────────────────────────────
    log_level  = vim.log.levels.WARN,

    -- ── Watch ────────────────────────────────────────────────────────────────
    watch      = { enabled = true },

    -- ── Consumers ────────────────────────────────────────────────────────────
    consumers  = {},
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 RUNNER-SPECIFIC SETTINGS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Per-language test patterns for quick detection
M.test_patterns = {
  python      = { "test_*.py", "*_test.py", "tests/**/*.py" },
  go          = { "*_test.go" },
  rust        = { "src/**/*.rs", "tests/**/*.rs" },
  javascript  = { "*.test.{js,jsx,ts,tsx}", "*.spec.{js,jsx,ts,tsx}", "__tests__/**" },
  typescript  = { "*.test.{ts,tsx}", "*.spec.{ts,tsx}", "__tests__/**" },
  lua         = { "*_spec.lua", "spec/**/*.lua" },
  elixir      = { "*_test.exs", "test/**/*_test.exs" },
  haskell     = { "test/**/*Spec.hs", "test/**/*Test.hs" },
  java        = { "src/test/**/*.java" },
  kotlin      = { "src/test/**/*.kt" },
  bash        = { "*.bats", "test/**/*.sh" },
  ruby        = { "*_spec.rb", "spec/**/*.rb" },
  php         = { "*Test.php", "tests/**/*.php" },
  zig         = { "src/**/*.zig" },
}

-- Coverage configuration per language
M.coverage_config = {
  python = {
    file    = ".coverage",
    command = { "pytest", "--cov", "--cov-report=lcov" },
  },
  go = {
    file    = "coverage.out",
    command = { "go", "test", "-coverprofile=coverage.out", "./..." },
  },
  javascript = {
    file    = "coverage/lcov.info",
    command = function()
      local pm = detect_pm()
      return { pm, "run", "test", "--coverage" }
    end,
  },
  typescript = {
    file    = "coverage/lcov.info",
    command = function()
      local pm = detect_pm()
      return { pm, "run", "test", "--coverage" }
    end,
  },
  rust = {
    -- Uses cargo-tarpaulin
    file    = "tarpaulin-report.lcov",
    command = { "cargo", "tarpaulin", "--out", "Lcov" },
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 MASON ENSURE INSTALLED (test adapter packages)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.mason_ensure = {
  "debugpy",  -- Python DAP (used by neotest-python)
  "delve",    -- Go DAP     (used by neotest-go)
}

return M