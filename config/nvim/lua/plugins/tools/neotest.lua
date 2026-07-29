-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🧪 NEOTEST — ULTRA TEST RUNNER v5.0 OMEGA                                ║
-- ║   multi-language · inline results · coverage · watch mode · summary panel     ║
-- ║   pytest · jest · vitest · go · rust · plenary · ASH theme-synced            ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — premium test status indicators
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Test status icons ─────────────────────────────────────────────────────
    hl(0, "NeotestPassed",          { bold = true,   fg = "#9ece6a" })
    hl(0, "NeotestFailed",          { bold = true,   fg = "#f38ba8" })
    hl(0, "NeotestRunning",         { bold = true,   fg = "#f9e2af" })
    hl(0, "NeotestSkipped",         { fg = "#9399b2"                })
    hl(0, "NeotestUnknown",         { fg = "#9399b2"                })
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "NeotestNormal",          { link = "NormalFloat"   })
    hl(0, "NeotestBorder",          { link = "FloatBorder"   })
    hl(0, "NeotestNormalNC",        { link = "NormalFloat"   })
  
    -- ── Summary tree ──────────────────────────────────────────────────────────
    hl(0, "NeotestDir",             { bold = true,   fg = "#89b4fa" })
    hl(0, "NeotestFile",            { fg = "#cdd6f4"                })
    hl(0, "NeotestNamespace",       { bold = true,   fg = "#cba6f7" })
    hl(0, "NeotestIndent",          { fg = "#313244"                })
    hl(0, "NeotestExpandMarker",    { fg = "#9399b2"                })
    hl(0, "NeotestWinSelect",       { bold = true,   fg = "#7aa2f7" })
    hl(0, "NeotestFocused",         { bold = true,   underline = true })
    hl(0, "NeotestMarked",          { bold = true,   fg = "#f9e2af" })
    hl(0, "NeotestTarget",          { bold = true,   fg = "#f38ba8" })
  
    -- ── Inline virtualtext ─────────────────────────────────────────────────────
    hl(0, "NeotestPassedSign",      { bold = true,   fg = "#9ece6a" })
    hl(0, "NeotestFailedSign",      { bold = true,   fg = "#f38ba8" })
    hl(0, "NeotestRunningSign",     { bold = true,   fg = "#f9e2af" })
    hl(0, "NeotestSkippedSign",     { fg = "#9399b2"                })
    hl(0, "NeotestPassedText",      { italic = true, fg = "#9ece6a" })
    hl(0, "NeotestFailedText",      { italic = true, fg = "#f38ba8" })
    hl(0, "NeotestRunningText",     { italic = true, fg = "#f9e2af" })
    hl(0, "NeotestSkippedText",     { italic = true, fg = "#9399b2" })
  
    -- ── Output panel ──────────────────────────────────────────────────────────
    hl(0, "NeotestOutput",          { link = "Normal"         })
    hl(0, "NeotestOutputFloat",     { link = "NormalFloat"    })
    hl(0, "NeotestOutputBorder",    { link = "FloatBorder"    })
    hl(0, "NeotestTest",            { fg = "#cdd6f4"          })
    hl(0, "NeotestAdapterName",     { bold = true, fg = "#7aa2f7" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then
        hl(0, "NeotestPassed",     { bold = true, fg = p.green })
        hl(0, "NeotestPassedSign", { bold = true, fg = p.green })
        hl(0, "NeotestPassedText", { italic = true, fg = p.green })
      end
      if p.red    then
        hl(0, "NeotestFailed",     { bold = true, fg = p.red })
        hl(0, "NeotestFailedSign", { bold = true, fg = p.red })
        hl(0, "NeotestFailedText", { italic = true, fg = p.red })
      end
      if p.yellow then
        hl(0, "NeotestRunning",     { bold = true, fg = p.yellow })
        hl(0, "NeotestRunningSign", { bold = true, fg = p.yellow })
        hl(0, "NeotestMarked",      { bold = true, fg = p.yellow })
      end
      if p.blue   then
        hl(0, "NeotestDir",         { bold = true, fg = p.blue })
        hl(0, "NeotestAdapterName", { bold = true, fg = p.blue })
      end
      if p.mauve  then hl(0, "NeotestNamespace", { bold = true, fg = p.mauve }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "NeotestSkipped",     { fg = dim })
      hl(0, "NeotestSkippedSign", { fg = dim })
      hl(0, "NeotestSkippedText", { italic = true, fg = dim })
      hl(0, "NeotestExpandMarker",{ fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 ICONS — Nerd Font v3
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local ICONS = {
    passed    = " ",
    failed    = " ",
    running   = "󰔟 ",
    skipped   = "󰒉 ",
    unknown   = "󰋖 ",
    running_animated = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART TEST ACTIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function run_and_notify(fn, label)
    return function()
      vim.notify(
        "🧪 Running: " .. label .. "…",
        vim.log.levels.INFO,
        { title = "Neotest", timeout = 800 }
      )
      fn()
    end
  end
  
  local function show_test_summary()
    local ok, neotest = pcall(require, "neotest")
    if not ok then return end
  
    local summary = neotest.summary
    if summary then
      summary.toggle()
    end
  end
  
  local function jump_to_failed()
    local ok, neotest = pcall(require, "neotest")
    if not ok then return end
    neotest.jump.next({ status = "failed" })
  end
  
  local function jump_to_prev_failed()
    local ok, neotest = pcall(require, "neotest")
    if not ok then return end
    neotest.jump.prev({ status = "failed" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-neotest/neotest",
      version      = false,
      event        = { "BufReadPre" },
      dependencies = {
        -- ── Core ──────────────────────────────────────────────────────────────
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-neotest/nvim-nio",
  
        -- ── Adapters ──────────────────────────────────────────────────────────
        { "nvim-neotest/neotest-python",           optional = true },
        { "nvim-neotest/neotest-go",               optional = true },
        { "nvim-neotest/neotest-jest",             optional = true },
        { "nvim-neotest/neotest-plenary",          optional = true },
        { "marilari88/neotest-vitest",             optional = true },
        { "rouge8/neotest-rust",                   optional = true },
        { "rcasia/neotest-bash",                   optional = true },
        { "jfpedroza/neotest-elixir",              optional = true },
        { "olimorris/neotest-phpunit",             optional = true },
        { "sidlatau/neotest-dart",                 optional = true },
        { "MarkEmmons/neotest-deno",               optional = true },
        { "lawrence-laz/neotest-zig",              optional = true },
  
        -- ── Coverage ──────────────────────────────────────────────────────────
        { "andythigpen/nvim-coverage",             optional = true },
      },
  
      keys = {
        -- ── Run ────────────────────────────────────────────────────────────────
        {
          "<leader>tt",
          run_and_notify(function()
            require("neotest").run.run()
          end, "nearest test"),
          desc = "🧪 Test: Run nearest",
        },
        {
          "<leader>tf",
          run_and_notify(function()
            require("neotest").run.run(vim.fn.expand("%"))
          end, "file"),
          desc = "🧪 Test: Run file",
        },
        {
          "<leader>ta",
          run_and_notify(function()
            require("neotest").run.run({ suite = true })
          end, "all tests"),
          desc = "🧪 Test: Run suite",
        },
        {
          "<leader>tl",
          run_and_notify(function()
            require("neotest").run.run_last()
          end, "last test"),
          desc = "🧪 Test: Run last",
        },
  
        -- ── Debug ─────────────────────────────────────────────────────────────
        {
          "<leader>td",
          function()
            require("neotest").run.run({ strategy = "dap" })
          end,
          desc = "🧪 Test: Debug nearest",
        },
  
        -- ── Watch ─────────────────────────────────────────────────────────────
        {
          "<leader>tw",
          function()
            require("neotest").watch.toggle(vim.fn.expand("%"))
          end,
          desc = "🧪 Test: Watch file",
        },
        {
          "<leader>tW",
          function() require("neotest").watch.stop() end,
          desc = "🧪 Test: Stop watch",
        },
  
        -- ── Stop ──────────────────────────────────────────────────────────────
        {
          "<leader>tS",
          function() require("neotest").run.stop() end,
          desc = "🧪 Test: Stop",
        },
  
        -- ── Output ────────────────────────────────────────────────────────────
        {
          "<leader>to",
          function()
            require("neotest").output.open({
              enter    = true,
              auto_close = true,
            })
          end,
          desc = "🧪 Test: Output",
        },
        {
          "<leader>tO",
          function()
            require("neotest").output_panel.toggle()
          end,
          desc = "🧪 Test: Output panel",
        },
        {
          "<leader>tq",
          function() require("neotest").output_panel.clear() end,
          desc = "🧪 Test: Clear output",
        },
  
        -- ── Summary ────────────────────────────────────────────────────────────
        {
          "<leader>ts",
          show_test_summary,
          desc = "🧪 Test: Summary",
        },
  
        -- ── Navigation ────────────────────────────────────────────────────────
        {
          "]t",
          function() require("neotest").jump.next({ status = "failed" }) end,
          desc = "🧪 Test: Next failed",
        },
        {
          "[t",
          function() require("neotest").jump.prev({ status = "failed" }) end,
          desc = "🧪 Test: Prev failed",
        },
        {
          "]T",
          function() require("neotest").jump.next() end,
          desc = "🧪 Test: Next test",
        },
        {
          "[T",
          function() require("neotest").jump.prev() end,
          desc = "🧪 Test: Prev test",
        },
  
        -- ── Coverage ──────────────────────────────────────────────────────────
        {
          "<leader>tc",
          function()
            local ok, coverage = pcall(require, "coverage")
            if ok then
              coverage.load(true)
            else
              vim.notify("🧪 nvim-coverage not installed", vim.log.levels.WARN,
                { title = "Neotest" })
            end
          end,
          desc = "🧪 Test: Coverage",
        },
        {
          "<leader>tC",
          function()
            local ok, coverage = pcall(require, "coverage")
            if ok then coverage.toggle() end
          end,
          desc = "🧪 Test: Coverage toggle",
        },
      },
  
      opts = function()
        local adapters = {}
  
        -- ── Python: pytest ─────────────────────────────────────────────────────
        local ok_py, neotest_python = pcall(require, "neotest-python")
        if ok_py then
          table.insert(adapters, neotest_python({
            dap          = { justMyCode = false },
            args         = { "--log-level=DEBUG", "-v" },
            runner       = "pytest",
            is_test_file = function(file)
              return file:match("test_.*%.py$") or file:match(".*_test%.py$")
            end,
          }))
        end
  
        -- ── Go: neotest-go ─────────────────────────────────────────────────────
        local ok_go, neotest_go = pcall(require, "neotest-go")
        if ok_go then
          table.insert(adapters, neotest_go({
            experimental = {
              test_table = true,
            },
            args         = { "-count=1", "-timeout=60s", "-v" },
          }))
        end
  
        -- ── Jest: neotest-jest ─────────────────────────────────────────────────
        local ok_jest, neotest_jest = pcall(require, "neotest-jest")
        if ok_jest then
          table.insert(adapters, neotest_jest({
            jestCommand = function()
              local pm = vim.fn.filereadable(vim.fn.getcwd() .. "/pnpm-lock.yaml") == 1
                and "pnpm" or (vim.fn.filereadable(vim.fn.getcwd() .. "/yarn.lock") == 1 and "yarn" or "npm")
              return pm .. " test --"
            end,
            jestConfigFile = function()
              local configs = {
                "jest.config.ts", "jest.config.js", "jest.config.mjs",
                "jest.config.cjs",
              }
              for _, cfg in ipairs(configs) do
                if vim.fn.filereadable(vim.fn.getcwd() .. "/" .. cfg) == 1 then
                  return vim.fn.getcwd() .. "/" .. cfg
                end
              end
            end,
            env              = { CI = true },
            cwd              = function() return vim.fn.getcwd() end,
            ignore_dirs      = { "node_modules", ".git", "dist", "build" },
            filter_dir       = function(name, _rel, _root)
              return name ~= "node_modules"
            end,
          }))
        end
  
        -- ── Vitest: neotest-vitest ─────────────────────────────────────────────
        local ok_vitest, neotest_vitest = pcall(require, "neotest-vitest")
        if ok_vitest then
          table.insert(adapters, neotest_vitest({
            filter_dir = function(name)
              return name ~= "node_modules"
            end,
          }))
        end
  
        -- ── Rust: neotest-rust ─────────────────────────────────────────────────
        local ok_rust, neotest_rust = pcall(require, "neotest-rust")
        if ok_rust then
          table.insert(adapters, neotest_rust({
            args     = { "--no-capture" },
            dap      = { adapter = "codelldb" },
          }))
        end
  
        -- ── Bash: neotest-bash ─────────────────────────────────────────────────
        local ok_bash, neotest_bash = pcall(require, "neotest-bash")
        if ok_bash then
          table.insert(adapters, neotest_bash())
        end
  
        -- ── Elixir: neotest-elixir ─────────────────────────────────────────────
        local ok_ex, neotest_elixir = pcall(require, "neotest-elixir")
        if ok_ex then
          table.insert(adapters, neotest_elixir())
        end
  
        -- ── Zig: neotest-zig ───────────────────────────────────────────────────
        local ok_zig, neotest_zig = pcall(require, "neotest-zig")
        if ok_zig then
          table.insert(adapters, neotest_zig())
        end
  
        -- ── Plenary: Neovim plugin tests ───────────────────────────────────────
        local ok_plenary, neotest_plenary = pcall(require, "neotest-plenary")
        if ok_plenary then
          table.insert(adapters, neotest_plenary())
        end
  
        return {
          -- ── Adapters ──────────────────────────────────────────────────────────
          adapters = adapters,
  
          -- ── Status ────────────────────────────────────────────────────────────
          status = {
            virtual_text    = true,
            signs           = true,
            enabled         = true,
          },
  
          -- ── Output ────────────────────────────────────────────────────────────
          output = {
            enabled         = true,
            open_on_run     = "short",
          },
  
          -- ── Output panel ──────────────────────────────────────────────────────
          output_panel = {
            enabled         = true,
            open            = "botright split | resize 14",
          },
  
          -- ── Summary ────────────────────────────────────────────────────────────
          summary = {
            enabled         = true,
            animated        = true,
            follow          = true,
            expand_errors   = true,
            open            = "botright vsplit | vertical resize 45",
            mappings        = {
              attach         = "a",
              clear_marked   = "M",
              clear_target   = "T",
              debug          = "d",
              debug_marked   = "D",
              expand         = { "<cr>", "<2-LeftMouse>" },
              expand_all     = "e",
              help           = "?",
              jump           = "i",
              mark           = "m",
              next_failed    = "J",
              output         = "o",
              prev_failed    = "K",
              run            = "r",
              run_marked     = "R",
              short          = "O",
              stop           = "u",
              target         = "t",
              watch          = "w",
            },
          },
  
          -- ── Icons ──────────────────────────────────────────────────────────────
          icons = {
            child_indent   = "│",
            child_prefix   = "├",
            collapsed      = "",
            expanded       = "",
            failed         = ICONS.failed,
            final_child_indent = " ",
            final_child_prefix = "└",
            non_collapsible = "─",
            notify         = "󰵆",
            passed         = ICONS.passed,
            running        = ICONS.running,
            running_animated = ICONS.running_animated,
            skipped        = ICONS.skipped,
            unknown        = ICONS.unknown,
            watching       = "󰈈",
          },
  
          -- ── Highlighting ────────────────────────────────────────────────────
          highlights = {
            adapter_name   = "NeotestAdapterName",
            border         = "NeotestBorder",
            dir            = "NeotestDir",
            expand_marker  = "NeotestExpandMarker",
            failed         = "NeotestFailed",
            file           = "NeotestFile",
            focused        = "NeotestFocused",
            indent         = "NeotestIndent",
            marked         = "NeotestMarked",
            namespace      = "NeotestNamespace",
            passed         = "NeotestPassed",
            running        = "NeotestRunning",
            select_win     = "NeotestWinSelect",
            skipped        = "NeotestSkipped",
            target         = "NeotestTarget",
            test           = "NeotestTest",
            unknown        = "NeotestUnknown",
            watching       = "NeotestWatching",
          },
  
          -- ── State ─────────────────────────────────────────────────────────────
          state = {
            enabled        = true,
          },
  
          -- ── Discovery ─────────────────────────────────────────────────────────
          discovery = {
            concurrent     = 10,
            enabled        = true,
            filter_dir     = function(name, _rel, _root)
              return not vim.tbl_contains({
                "node_modules", ".git", "dist", "build",
                "target", ".venv", "venv", "__pycache__",
                ".next", ".turbo", ".cache",
              }, name)
            end,
          },
  
          -- ── Running ───────────────────────────────────────────────────────────
          running = {
            concurrent     = true,
          },
  
          -- ── Consumers ─────────────────────────────────────────────────────────
          consumers = {},
  
          -- ── Diagnostic ────────────────────────────────────────────────────────
          diagnostic = {
            enabled        = true,
            severity       = vim.diagnostic.severity.ERROR,
          },
  
          -- ── Log ───────────────────────────────────────────────────────────────
          log_level = vim.log.levels.WARN,
  
          -- ── Watch ─────────────────────────────────────────────────────────────
          watch = {
            enabled        = true,
          },
  
          -- ── Quickfix ──────────────────────────────────────────────────────────
          quickfix = {
            enabled        = false,
            open           = false,
          },
        }
      end,
  
      config = function(_, opts)
        -- Lazy-load adapters
        local neotest = require("neotest")
        neotest.setup(opts)
  
        setup_highlights()
  
        -- ── Expose statusline component ────────────────────────────────────────
        _G.AshNeotestStatus = function()
          local ok, nt = pcall(require, "neotest")
          if not ok then return "" end
  
          local ok2, status = pcall(function()
            return nt.state.status_counts(vim.api.nvim_buf_get_name(0), {})
          end)
  
          if not ok2 or not status then return "" end
  
          local parts = {}
          if (status.passed  or 0) > 0 then
            table.insert(parts, "✅ " .. status.passed)
          end
          if (status.failed  or 0) > 0 then
            table.insert(parts, "❌ " .. status.failed)
          end
          if (status.running or 0) > 0 then
            table.insert(parts, "🧪 " .. status.running)
          end
          if (status.skipped or 0) > 0 then
            table.insert(parts, "⏭ " .. status.skipped)
          end
  
          return #parts > 0 and (" " .. table.concat(parts, " ") .. " ") or ""
        end
  
        local aug = vim.api.nvim_create_augroup("AshNeotest", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🧪 Neotest highlights synced", vim.log.levels.INFO,
              { title = "ASH Neotest", timeout = 1200 })
          end,
        })
  
        -- Disable mini plugins in neotest panes
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "neotest-summary", "neotest-output", "neotest-output-panel", "neotest-attach" },
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
            vim.opt_local.spell          = false
            vim.opt_local.foldcolumn     = "0"
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🧪 Neotest loaded — %d adapters", #opts.adapters),
            vim.log.levels.DEBUG,
            { title = "ASH Neotest" }
          )
        end
      end,
    },
  
    -- ── nvim-coverage — visual coverage overlay ───────────────────────────────────
    {
      "andythigpen/nvim-coverage",
      version      = "*",
      lazy         = true,
      dependencies = { "nvim-lua/plenary.nvim" },
  
      opts = {
        commands    = true,
        highlights  = {
          covered   = { fg = "#9ece6a" },
          uncovered = { fg = "#f38ba8" },
        },
        signs       = {
          covered   = { hl = "CoverageCovered",   text = "▎" },
          uncovered = { hl = "CoverageUncovered",  text = "▎" },
          partial   = { hl = "CoveragePartial",    text = "▎" },
        },
        lang        = {
          python    = { coverage_file = ".coverage" },
          javascript= { coverage_file = "coverage/lcov.info" },
          typescript= { coverage_file = "coverage/lcov.info" },
          go        = {},
          rust      = {},
        },
        lcov_file   = nil,
        load_coverage_cb = function(ftype)
          vim.notify("🧪 Loading " .. ftype .. " coverage…", vim.log.levels.INFO,
            { title = "Coverage", timeout = 1200 })
        end,
      },
  
      config = function(_, opts)
        require("coverage").setup(opts)
  
        local hl = vim.api.nvim_set_hl
        hl(0, "CoverageCovered",  { bold = true, fg = "#9ece6a" })
        hl(0, "CoverageUncovered",{ bold = true, fg = "#f38ba8" })
        hl(0, "CoveragePartial",  { bold = true, fg = "#f9e2af" })
  
        local ok, ash = pcall(require, "ash.theme")
        if ok and ash.palette then
          local p = ash.palette
          if p.green  then hl(0, "CoverageCovered",  { bold = true, fg = p.green  }) end
          if p.red    then hl(0, "CoverageUncovered", { bold = true, fg = p.red    }) end
          if p.yellow then hl(0, "CoveragePartial",   { bold = true, fg = p.yellow }) end
        end
      end,
    },
  }