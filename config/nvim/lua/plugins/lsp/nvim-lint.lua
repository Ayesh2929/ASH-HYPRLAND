-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔬 NVIM-LINT — ULTRA LINTER ENGINE v5.0 OMEGA                            ║
-- ║   60+ linters · async · per-filetype · smart trigger · ASH diagnostics        ║
-- ║   debounced · CursorHold + BufWrite · severity mapping · lint status bar      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 UTILITY HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function exe(name)
    return vim.fn.executable(name) == 1
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHT SETUP — lint status indicators
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_highlights()
    local hl = vim.api.nvim_set_hl
    hl(0, "NvimLintRunning",  { bold = true, fg = "#7aa2f7"  })
    hl(0, "NvimLintOk",       { bold = true, fg = "#9ece6a"  })
    hl(0, "NvimLintError",    { bold = true, fg = "#f38ba8"  })
    hl(0, "NvimLintWarn",     { bold = true, fg = "#f9e2af"  })
    hl(0, "NvimLintDisabled", { italic = true, fg = "#545c7e" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "NvimLintRunning",  { bold = true, fg = p.blue   }) end
      if p.green  then hl(0, "NvimLintOk",       { bold = true, fg = p.green  }) end
      if p.red    then hl(0, "NvimLintError",    { bold = true, fg = p.red    }) end
      if p.yellow then hl(0, "NvimLintWarn",     { bold = true, fg = p.yellow }) end
      if p.overlay0 then hl(0, "NvimLintDisabled", { italic = true, fg = p.overlay0 }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 LINTER REGISTRY — per-filetype linter lists
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function build_linters_by_ft()
    local linters = {}
  
    local function add(ft, linter)
      if not exe(linter) then return end
      linters[ft] = linters[ft] or {}
      -- Avoid duplicates
      if not vim.tbl_contains(linters[ft], linter) then
        table.insert(linters[ft], linter)
      end
    end
  
    -- ── 🐚 Shell ───────────────────────────────────────────────────────────────
    add("sh",           "shellcheck")
    add("bash",         "shellcheck")
    add("zsh",          "zsh")
    add("sh",           "shellharden")
  
    -- ── 🐍 Python ──────────────────────────────────────────────────────────────
    add("python",       "ruff")
    add("python",       "flake8")
    add("python",       "pylint")
    add("python",       "mypy")
    add("python",       "bandit")
    add("python",       "pydocstyle")
    add("python",       "vulture")
  
    -- ── 🌙 Lua ─────────────────────────────────────────────────────────────────
    add("lua",          "luacheck")
    add("lua",          "selene")
  
    -- ── 📘 TypeScript / JavaScript ─────────────────────────────────────────────
    add("javascript",       "eslint_d")
    add("javascript",       "biomejs")
    add("javascriptreact",  "eslint_d")
    add("typescript",       "eslint_d")
    add("typescript",       "biomejs")
    add("typescriptreact",  "eslint_d")
  
    -- ── 🐹 Go ──────────────────────────────────────────────────────────────────
    add("go",           "golangcilint")
    add("go",           "revive")
    add("go",           "staticcheck")
  
    -- ── ⚙️  C / C++ ────────────────────────────────────────────────────────────
    add("c",            "cppcheck")
    add("cpp",          "cppcheck")
    add("c",            "cpplint")
    add("cpp",          "cpplint")
  
    -- ── 🎨 CSS / SCSS ──────────────────────────────────────────────────────────
    add("css",          "stylelint")
    add("scss",         "stylelint")
    add("less",         "stylelint")
    add("sass",         "stylelint")
  
    -- ── 📄 HTML ────────────────────────────────────────────────────────────────
    add("html",         "htmlhint")
    add("html",         "tidy")
  
    -- ── 📋 YAML ────────────────────────────────────────────────────────────────
    add("yaml",         "yamllint")
    add("yaml",         "actionlint")  -- GitHub Actions
  
    -- ── 📄 JSON ────────────────────────────────────────────────────────────────
    add("json",         "jsonlint")
    add("json",         "biomejs")
    add("jsonc",        "biomejs")
  
    -- ── 📝 Markdown ────────────────────────────────────────────────────────────
    add("markdown",     "markdownlint")
    add("markdown",     "vale")
    add("markdown",     "proselint")
  
    -- ── 🐳 Docker ──────────────────────────────────────────────────────────────
    add("dockerfile",   "hadolint")
  
    -- ── 🏗️  Terraform ───────────────────────────────────────────────────────────
    add("terraform",    "tflint")
    add("terraform",    "terraform_validate")
  
    -- ── ❄️  Nix ─────────────────────────────────────────────────────────────────
    add("nix",          "statix")
    add("nix",          "deadnix")
  
    -- ── λ Haskell ──────────────────────────────────────────────────────────────
    add("haskell",      "hlint")
  
    -- ── 🦩 OCaml ───────────────────────────────────────────────────────────────
    -- LSP handles this
  
    -- ── 🌿 Elixir ──────────────────────────────────────────────────────────────
    add("elixir",       "credo")
    add("elixir",       "dialyxir")
  
    -- ── 🔷 GraphQL ─────────────────────────────────────────────────────────────
    add("graphql",      "graphql_doc_gen")
  
    -- ── 🗄️  SQL ─────────────────────────────────────────────────────────────────
    add("sql",          "sqlfluff")
  
    -- ── 🎭 Ansible ─────────────────────────────────────────────────────────────
    add("yaml",         "ansible_lint")
    add("yaml.ansible", "ansible_lint")
  
    -- ── 📐 LaTeX ───────────────────────────────────────────────────────────────
    add("tex",          "chktex")
    add("tex",          "lacheck")
  
    -- ── 🔵 PHP ─────────────────────────────────────────────────────────────────
    add("php",          "phpstan")
    add("php",          "phpcs")
    add("php",          "psalm")
  
    -- ── 💎 Ruby ────────────────────────────────────────────────────────────────
    add("ruby",         "rubocop")
    add("ruby",         "standardrb")
    add("ruby",         "reek")
  
    -- ── 🐘 PHP ─────────────────────────────────────────────────────────────────
    add("php",          "phpmd")
  
    -- ── 🔏 Protobuf ────────────────────────────────────────────────────────────
    add("proto",        "buf_lint")
  
    -- ── 🧬 R ───────────────────────────────────────────────────────────────────
    add("r",            "lintr")
  
    -- ── 🎯 Vim script ──────────────────────────────────────────────────────────
    add("vim",          "vint")
  
    -- ── 🔒 Security ────────────────────────────────────────────────────────────
    add("dockerfile",   "trivy")
    add("terraform",    "checkov")
    add("python",       "semgrep")
    add("javascript",   "semgrep")
    add("typescript",   "semgrep")
  
    -- ── 📝 RST ─────────────────────────────────────────────────────────────────
    add("rst",          "rstcheck")
    add("rst",          "vale")
  
    -- ── 🌊 Svelte ──────────────────────────────────────────────────────────────
    add("svelte",       "eslint_d")
  
    -- ── ✨ Astro ───────────────────────────────────────────────────────────────
    add("astro",        "eslint_d")
  
    -- ── 🌐 Vue ─────────────────────────────────────────────────────────────────
    add("vue",          "eslint_d")
    add("vue",          "stylelint")
  
    -- ── 🎮 GLSL ────────────────────────────────────────────────────────────────
    add("glsl",         "glslc")
  
    -- ── 📦 EditorConfig ────────────────────────────────────────────────────────
    -- Apply to all files via special key
    linters["*"] = linters["*"] or {}
    if exe("editorconfig-checker") then
      table.insert(linters["*"], "editorconfig-checker")
    end
  
    return linters
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 CUSTOM LINTER CONFIGURATIONS — override defaults
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function configure_linters(lint)
    -- ── shellcheck ──────────────────────────────────────────────────────────────
    lint.linters.shellcheck = vim.tbl_extend("force",
      lint.linters.shellcheck or {},
      {
        args = {
          "--format=json",
          "--severity=warning",
          "--shell=auto",
          "-",
        },
      }
    )
  
    -- ── luacheck ───────────────────────────────────────────────────────────────
    lint.linters.luacheck = vim.tbl_extend("force",
      lint.linters.luacheck or {},
      {
        args = {
          "--formatter", "plain",
          "--codes",
          "--ranges",
          "--globals", "vim",
          "--std", "luajit",
          "-",
        },
      }
    )
  
    -- ── flake8 ─────────────────────────────────────────────────────────────────
    lint.linters.flake8 = vim.tbl_extend("force",
      lint.linters.flake8 or {},
      {
        args = {
          "--format=default",
          "--max-line-length=100",
          "--ignore=E501,W503,W504,E203",
          "--stdin-display-name", function() return vim.api.nvim_buf_get_name(0) end,
          "-",
        },
      }
    )
  
    -- ── mypy ───────────────────────────────────────────────────────────────────
    lint.linters.mypy = vim.tbl_extend("force",
      lint.linters.mypy or {},
      {
        args = {
          "--ignore-missing-imports",
          "--show-error-codes",
          "--show-column-numbers",
          "--show-error-context",
          "--pretty",
          "--no-color-output",
          "--no-error-summary",
        },
      }
    )
  
    -- ── pylint ─────────────────────────────────────────────────────────────────
    lint.linters.pylint = vim.tbl_extend("force",
      lint.linters.pylint or {},
      {
        args = {
          "--output-format=json",
          "--disable=C0111,C0114,C0115,C0116,R0903",
          "--max-line-length=100",
        },
      }
    )
  
    -- ── eslint_d ───────────────────────────────────────────────────────────────
    lint.linters.eslint_d = vim.tbl_extend("force",
      lint.linters.eslint_d or {},
      {
        args = {
          "--format", "json",
          "--stdin",
          "--stdin-filename", function() return vim.api.nvim_buf_get_name(0) end,
        },
        -- Only run if eslint config found
        condition = function(ctx)
          local root = vim.fs.find(
            { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json",
              ".eslintrc.yml", ".eslintrc.yaml", "eslint.config.js", "eslint.config.mjs" },
            { upward = true, path = ctx.dirname }
          )[1]
          return root ~= nil
        end,
      }
    )
  
    -- ── markdownlint ────────────────────────────────────────────────────────────
    lint.linters.markdownlint = vim.tbl_extend("force",
      lint.linters.markdownlint or {},
      {
        args = {
          "--disable", "MD013",   -- line length
          "--disable", "MD033",   -- inline HTML
          "--disable", "MD041",   -- first-line header
          "--stdin",
        },
      }
    )
  
    -- ── yamllint ───────────────────────────────────────────────────────────────
    lint.linters.yamllint = vim.tbl_extend("force",
      lint.linters.yamllint or {},
      {
        args = {
          "--format", "parsable",
          "-d", "{extends: relaxed, rules: {line-length: {max: 120}, truthy: disable}}",
          "-",
        },
      }
    )
  
    -- ── golangcilint ───────────────────────────────────────────────────────────
    lint.linters.golangcilint = vim.tbl_extend("force",
      lint.linters.golangcilint or {},
      {
        args = {
          "run",
          "--out-format", "json",
          "--fast",
          "--timeout", "60s",
        },
      }
    )
  
    -- ── hadolint ───────────────────────────────────────────────────────────────
    lint.linters.hadolint = vim.tbl_extend("force",
      lint.linters.hadolint or {},
      {
        args = {
          "--format", "json",
          "--ignore", "DL3008",  -- apt-get pin version
          "-",
        },
      }
    )
  
    -- ── tflint ─────────────────────────────────────────────────────────────────
    lint.linters.tflint = vim.tbl_extend("force",
      lint.linters.tflint or {},
      {
        args = { "--format=json" },
      }
    )
  
    -- ── vale ───────────────────────────────────────────────────────────────────
    lint.linters.vale = vim.tbl_extend("force",
      lint.linters.vale or {},
      {
        args = {
          "--output=JSON",
          "--no-wrap",
        },
      }
    )
  
    -- ── cppcheck ───────────────────────────────────────────────────────────────
    lint.linters.cppcheck = vim.tbl_extend("force",
      lint.linters.cppcheck or {},
      {
        args = {
          "--enable=all",
          "--template={file}:{line}:{col}: {severity}: {message} [{id}]",
          "--suppress=missingIncludeSystem",
          "--quiet",
          "--language=c++",
        },
      }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🚀 DEBOUNCED LINT TRIGGER
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _lint_timer = nil
  local _lint_enabled = true
  
  local function debounced_lint(bufnr, delay)
    delay   = delay or 400
    bufnr   = bufnr or vim.api.nvim_get_current_buf()
  
    if not _lint_enabled then return end
    if vim.b[bufnr].disable_lint then return end
    if vim.bo[bufnr].buftype ~= "" then return end
    if vim.api.nvim_buf_line_count(bufnr) > 50000 then return end
  
    if _lint_timer then
      vim.loop.timer_stop(_lint_timer)
    end
  
    _lint_timer = vim.defer_fn(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then return end
      local ok, lint = pcall(require, "lint")
      if ok then
        pcall(lint.try_lint, nil, { ignore_errors = true })
      end
      _lint_timer = nil
    end, delay)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE + STATUS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function toggle_lint()
    _lint_enabled = not _lint_enabled
    if _lint_enabled then
      debounced_lint()
      vim.notify(
        "🔬 Linting  enabled",
        vim.log.levels.INFO,
        { title = "nvim-lint", timeout = 1200 }
      )
    else
      -- Clear existing diagnostics set by nvim-lint
      vim.diagnostic.reset(
        vim.api.nvim_create_namespace("nvim-lint"),
        vim.api.nvim_get_current_buf()
      )
      vim.notify(
        "🔬 Linting  disabled",
        vim.log.levels.INFO,
        { title = "nvim-lint", timeout = 1200 }
      )
    end
  end
  
  local function show_lint_status()
    local lint     = require("lint")
    local bufnr    = vim.api.nvim_get_current_buf()
    local ft       = vim.bo[bufnr].filetype
    local fts      = { ft, "*" }
    local active   = {}
  
    for _, ftype in ipairs(fts) do
      local lts = lint.linters_by_ft[ftype] or {}
      for _, lt in ipairs(lts) do
        local ok, info = pcall(function() return lint.linters[lt] end)
        if ok and info then
          local linter_exe = type(info.cmd) == "function" and info.cmd() or (info.cmd or lt)
          local available  = vim.fn.executable(linter_exe) == 1
          table.insert(active, {
            name      = lt,
            exe       = linter_exe,
            available = available,
          })
        end
      end
    end
  
    if #active == 0 then
      vim.notify(
        "🔬 No linters configured for: " .. ft,
        vim.log.levels.WARN,
        { title = "nvim-lint" }
      )
      return
    end
  
    local lines = {
      string.format("🔬 nvim-lint Status — %s", ft),
      "─────────────────────────────────────",
      string.format("  Global lint: %s", _lint_enabled and "✅ on" or "⭕ off"),
      string.format("  Buffer lint: %s", vim.b[bufnr].disable_lint and "⭕ off" or "✅ on"),
      "",
      "  Linters:",
    }
  
    for _, l in ipairs(active) do
      table.insert(lines, string.format(
        "  %s %-20s  %s",
        l.available and "✅" or "⭕",
        l.name,
        l.available and vim.fn.exepath(l.exe) or "(not installed)"
      ))
    end
  
    vim.notify(
      table.concat(lines, "\n"),
      vim.log.levels.INFO,
      { title = "nvim-lint Status" }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "mfussenegger/nvim-lint",
      event = { "BufReadPre", "BufNewFile" },
  
      keys = {
        {
          "<leader>ll",
          function() debounced_lint(nil, 0) end,
          desc   = "🔬 Lint Buffer Now",
          silent = true,
        },
        {
          "<leader>uL",
          toggle_lint,
          desc   = "🔬 Toggle Linting",
          silent = true,
        },
        {
          "<leader>uB",
          function()
            vim.b.disable_lint = not vim.b.disable_lint
            if not vim.b.disable_lint then debounced_lint(nil, 0) end
            vim.notify(
              string.format(
                "🔬 Buffer linting %s",
                vim.b.disable_lint and " disabled" or " enabled"
              ),
              vim.log.levels.INFO,
              { title = "nvim-lint", timeout = 1200 }
            )
          end,
          desc   = "🔬 Toggle Buffer Linting",
          silent = true,
        },
        {
          "<leader>lL",
          show_lint_status,
          desc   = "🔬 Lint Status",
          silent = true,
        },
      },
  
      config = function()
        local lint = require("lint")
  
        -- ── Attach linters by filetype ───────────────────────────────────────
        lint.linters_by_ft = build_linters_by_ft()
  
        -- ── Apply custom configurations ──────────────────────────────────────
        configure_linters(lint)
  
        -- ── Highlights ────────────────────────────────────────────────────────
        setup_highlights()
  
        -- ── Autocmds ─────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshNvimLint", { clear = true })
  
        -- Trigger: BufEnter (initial lint when opening a file)
        vim.api.nvim_create_autocmd("BufEnter", {
          group    = aug,
          callback = function(ev) debounced_lint(ev.buf, 500) end,
        })
  
        -- Trigger: BufWritePost (lint after save)
        vim.api.nvim_create_autocmd("BufWritePost", {
          group    = aug,
          callback = function(ev) debounced_lint(ev.buf, 100) end,
        })
  
        -- Trigger: InsertLeave (lint when leaving insert mode)
        vim.api.nvim_create_autocmd("InsertLeave", {
          group    = aug,
          callback = function(ev) debounced_lint(ev.buf, 300) end,
        })
  
        -- Trigger: TextChanged in normal mode (debounced)
        vim.api.nvim_create_autocmd("TextChanged", {
          group    = aug,
          callback = function(ev) debounced_lint(ev.buf, 800) end,
        })
  
        -- Trigger: CursorHold (background lint while idle)
        vim.api.nvim_create_autocmd("CursorHold", {
          group    = aug,
          callback = function(ev) debounced_lint(ev.buf, 0) end,
        })
  
        -- ColorScheme: update highlights
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🔬 nvim-lint highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH nvim-lint", timeout = 1200 }
            )
          end,
        })
  
        -- Expose statusline component
        _G.AshLintStatus = function()
          if not _lint_enabled then return "󰉨 " end
          local ns     = require("lint").get_namespace
          local bufnr  = vim.api.nvim_get_current_buf()
          local counts = vim.diagnostic.count(bufnr)
          local e      = counts[vim.diagnostic.severity.ERROR]   or 0
          local w      = counts[vim.diagnostic.severity.WARN]    or 0
          if e > 0 then
            return string.format(" %d", e)
          elseif w > 0 then
            return string.format(" %d", w)
          end
          return ""
        end
  
        -- User command
        vim.api.nvim_create_user_command("Lint", function()
          debounced_lint(nil, 0)
        end, { desc = "🔬 Run linters on current buffer" })
  
        if vim.g.ash_debug then
          local count = vim.tbl_count(lint.linters_by_ft)
          vim.notify(
            string.format("🔬 nvim-lint: %d filetypes configured", count),
            vim.log.levels.DEBUG,
            { title = "ASH nvim-lint" }
          )
        end
      end,
    },
  }