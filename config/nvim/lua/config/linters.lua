-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔬 LINTERS REGISTRY — ASH CONFIG v5.0 OMEGA                              ║
-- ║   60+ linters · nvim-lint integration · per-filetype chains                   ║
-- ║   Custom configs · mason auto-install · trigger events                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔬 LINTERS BY FILETYPE
-- Only include linters whose executables are available
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function exe(name)
  return vim.fn.executable(name) == 1
end

---Build linter list only including available tools
---@return table<string, string[]>
function M.build_linters_by_ft()
  local linters = {}

  local function add(ft, linter)
    if not exe(linter) then return end
    linters[ft]  = linters[ft] or {}
    if not vim.tbl_contains(linters[ft], linter) then
      table.insert(linters[ft], linter)
    end
  end

  -- ── Shell ──────────────────────────────────────────────────────────────────
  add("sh",         "shellcheck")
  add("bash",       "shellcheck")
  add("zsh",        "zsh")
  add("sh",         "shellharden")

  -- ── Python ────────────────────────────────────────────────────────────────
  add("python",     "ruff")
  add("python",     "flake8")
  add("python",     "pylint")
  add("python",     "mypy")
  add("python",     "bandit")

  -- ── Lua ───────────────────────────────────────────────────────────────────
  add("lua",        "luacheck")
  add("lua",        "selene")

  -- ── JavaScript / TypeScript ────────────────────────────────────────────────
  add("javascript",       "eslint_d")
  add("javascript",       "biomejs")
  add("javascriptreact",  "eslint_d")
  add("typescript",       "eslint_d")
  add("typescript",       "biomejs")
  add("typescriptreact",  "eslint_d")

  -- ── Go ────────────────────────────────────────────────────────────────────
  add("go",         "golangcilint")
  add("go",         "revive")
  add("go",         "staticcheck")

  -- ── C / C++ ───────────────────────────────────────────────────────────────
  add("c",          "cppcheck")
  add("cpp",        "cppcheck")
  add("c",          "cpplint")
  add("cpp",        "cpplint")

  -- ── CSS / SCSS ─────────────────────────────────────────────────────────────
  add("css",        "stylelint")
  add("scss",       "stylelint")
  add("less",       "stylelint")
  add("sass",       "stylelint")

  -- ── HTML ──────────────────────────────────────────────────────────────────
  add("html",       "htmlhint")
  add("html",       "tidy")

  -- ── YAML ──────────────────────────────────────────────────────────────────
  add("yaml",       "yamllint")
  add("yaml",       "actionlint")

  -- ── JSON ──────────────────────────────────────────────────────────────────
  add("json",       "jsonlint")
  add("json",       "biomejs")
  add("jsonc",      "biomejs")

  -- ── Markdown ──────────────────────────────────────────────────────────────
  add("markdown",   "markdownlint")
  add("markdown",   "vale")
  add("markdown",   "proselint")

  -- ── Docker ────────────────────────────────────────────────────────────────
  add("dockerfile", "hadolint")

  -- ── Terraform ─────────────────────────────────────────────────────────────
  add("terraform",  "tflint")
  add("terraform",  "terraform_validate")

  -- ── Nix ───────────────────────────────────────────────────────────────────
  add("nix",        "statix")
  add("nix",        "deadnix")

  -- ── Haskell ───────────────────────────────────────────────────────────────
  add("haskell",    "hlint")

  -- ── Elixir ────────────────────────────────────────────────────────────────
  add("elixir",     "credo")

  -- ── Ruby ──────────────────────────────────────────────────────────────────
  add("ruby",       "rubocop")
  add("ruby",       "standardrb")

  -- ── PHP ───────────────────────────────────────────────────────────────────
  add("php",        "phpstan")
  add("php",        "phpcs")

  -- ── SQL ───────────────────────────────────────────────────────────────────
  add("sql",        "sqlfluff")

  -- ── LaTeX ─────────────────────────────────────────────────────────────────
  add("tex",        "chktex")
  add("tex",        "lacheck")

  -- ── Ansible ───────────────────────────────────────────────────────────────
  add("yaml",          "ansible_lint")
  add("yaml.ansible",  "ansible_lint")

  -- ── Protobuf ──────────────────────────────────────────────────────────────
  add("proto",      "buf_lint")

  -- ── Vim ───────────────────────────────────────────────────────────────────
  add("vim",        "vint")

  -- ── RST ───────────────────────────────────────────────────────────────────
  add("rst",        "rstcheck")
  add("rst",        "vale")

  -- ── Security ──────────────────────────────────────────────────────────────
  add("python",     "semgrep")
  add("javascript", "semgrep")
  add("typescript", "semgrep")

  -- ── GLSL ──────────────────────────────────────────────────────────────────
  add("glsl",       "glslc")

  -- ── Dart ──────────────────────────────────────────────────────────────────
  add("dart",       "dart_analyze")

  -- ── R ─────────────────────────────────────────────────────────────────────
  add("r",          "lintr")

  -- ── EditorConfig (all files) ───────────────────────────────────────────────
  if exe("editorconfig-checker") then
    linters["*"] = linters["*"] or {}
    table.insert(linters["*"], "editorconfig-checker")
  end

  return linters
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 LINTER CUSTOM CONFIGS (overrides for nvim-lint)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.linter_configs = {
  shellcheck = {
    args = { "--format=json", "--severity=warning", "--shell=auto", "-" },
  },

  luacheck = {
    args = {
      "--formatter", "plain",
      "--codes", "--ranges",
      "--globals", "vim",
      "--std", "luajit",
      "-",
    },
  },

  flake8 = {
    args = {
      "--format=default",
      "--max-line-length=100",
      "--ignore=E501,W503,W504,E203",
      "--stdin-display-name", function()
        return vim.api.nvim_buf_get_name(0)
      end,
      "-",
    },
  },

  mypy = {
    args = {
      "--ignore-missing-imports",
      "--show-error-codes",
      "--show-column-numbers",
      "--pretty",
      "--no-color-output",
      "--no-error-summary",
    },
  },

  pylint = {
    args = {
      "--output-format=json",
      "--disable=C0111,C0114,C0115,C0116,R0903",
      "--max-line-length=100",
    },
  },

  eslint_d = {
    args = {
      "--format", "json",
      "--stdin",
      "--stdin-filename", function() return vim.api.nvim_buf_get_name(0) end,
    },
    condition = function(ctx)
      return vim.fs.find(
        { ".eslintrc",".eslintrc.js",".eslintrc.cjs",
          ".eslintrc.json","eslint.config.js","eslint.config.mjs" },
        { upward = true, path = ctx.dirname }
      )[1] ~= nil
    end,
  },

  markdownlint = {
    args = {
      "--disable", "MD013",
      "--disable", "MD033",
      "--disable", "MD041",
      "--stdin",
    },
  },

  yamllint = {
    args = {
      "--format", "parsable",
      "-d", "{extends: relaxed, rules: {line-length: {max: 120}, truthy: disable}}",
      "-",
    },
  },

  golangcilint = {
    args = { "run", "--out-format", "json", "--fast", "--timeout", "60s" },
  },

  hadolint = {
    args = {
      "--format", "json",
      "--ignore", "DL3008",
      "-",
    },
  },

  tflint = {
    args = { "--format=json" },
  },

  vale = {
    args = { "--output=JSON", "--no-wrap" },
  },

  cppcheck = {
    args = {
      "--enable=all",
      "--template={file}:{line}:{col}: {severity}: {message} [{id}]",
      "--suppress=missingIncludeSystem",
      "--quiet",
      "--language=c++",
    },
  },

  sqlfluff = {
    args = { "lint", "--format=json", "--dialect=postgresql" },
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 MASON ENSURE INSTALLED (linters subset)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.mason_ensure = {
  "shellcheck",   "shellharden",
  "luacheck",     "selene",
  "flake8",       "mypy",         "pylint",     "bandit",
  "eslint_d",     "biomejs",
  "golangci-lint","revive",       "staticcheck",
  "stylelint",    "htmlhint",
  "yamllint",     "actionlint",
  "jsonlint",
  "markdownlint-cli2", "vale",    "proselint",
  "hadolint",
  "tflint",       "checkov",
  "hlint",
  "credo",
  "rubocop",      "standardrb",
  "phpstan",      "phpcs",
  "sqlfluff",
  "chktex",       "lacheck",
  "ansible-lint",
  "buf",
  "vint",
  "rstcheck",
  "editorconfig-checker",
  "statix",       "deadnix",
  "trivy",        "gitleaks",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎛️  TRIGGER EVENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.trigger_events  = {
  "BufEnter",
  "BufWritePost",
  "InsertLeave",
  "TextChanged",
  "CursorHold",
}

M.debounce_ms     = 400
M.large_file_lines= 50000  -- disable linting above this line count

return M