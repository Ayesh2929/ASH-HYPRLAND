-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 FORMATTERS REGISTRY — ASH CONFIG v5.0 OMEGA                           ║
-- ║   50+ formatters · per-filetype chains · conform.nvim integration              ║
-- ║   Conditional activation · mason auto-install · format-on-save control        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local M = {}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 FORMATTERS BY FILETYPE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

---@type table<string, string[]|fun(bufnr:integer):string[]>
M.formatters_by_ft = {
  -- ── Lua ──────────────────────────────────────────────────────────────────
  lua             = { "stylua" },

  -- ── Python ───────────────────────────────────────────────────────────────
  python          = function(bufnr)
    local ok, conform = pcall(require, "conform")
    if ok then
      if conform.get_formatter_info("ruff_format", bufnr).available then
        return { "ruff_fix", "ruff_format" }
      end
    end
    return { "isort", "black" }
  end,

  -- ── JavaScript / TypeScript ────────────────────────────────────────────────
  javascript          = { "biome", "prettierd", "prettier", stop_after_first = true },
  javascriptreact     = { "biome", "prettierd", "prettier", stop_after_first = true },
  typescript          = { "biome", "prettierd", "prettier", stop_after_first = true },
  typescriptreact     = { "biome", "prettierd", "prettier", stop_after_first = true },
  ["typescript.tsx"]  = { "biome", "prettierd", "prettier", stop_after_first = true },
  ["javascript.jsx"]  = { "biome", "prettierd", "prettier", stop_after_first = true },

  -- ── Web ───────────────────────────────────────────────────────────────────
  html        = { "prettierd", "prettier", stop_after_first = true },
  css         = { "prettierd", "prettier", stop_after_first = true },
  scss        = { "prettierd", "prettier", stop_after_first = true },
  less        = { "prettierd", "prettier", stop_after_first = true },
  vue         = { "prettierd", "prettier", stop_after_first = true },
  svelte      = { "prettierd", "prettier", stop_after_first = true },
  astro       = { "prettierd", "prettier", stop_after_first = true },
  graphql     = { "prettierd", "prettier", stop_after_first = true },
  handlebars  = { "prettierd", "prettier", stop_after_first = true },
  mdx         = { "prettierd", "prettier", stop_after_first = true },

  -- ── Go ────────────────────────────────────────────────────────────────────
  go          = { "goimports", "gofumpt" },

  -- ── Rust ──────────────────────────────────────────────────────────────────
  rust        = { "rustfmt" },

  -- ── Shell ─────────────────────────────────────────────────────────────────
  sh          = { "shfmt" },
  bash        = { "shfmt" },
  zsh         = { "shfmt" },
  fish        = { "fish_indent" },

  -- ── Systems ───────────────────────────────────────────────────────────────
  c           = { "clang_format" },
  cpp         = { "clang_format" },
  cuda        = { "clang_format" },
  cs          = { "csharpier" },
  java        = { "google_java_format" },
  kotlin      = { "ktfmt" },
  swift       = { "swiftformat" },
  dart        = { "dart_format" },
  zig         = { "zigfmt" },

  -- ── JVM ───────────────────────────────────────────────────────────────────
  scala       = { "scalafmt" },

  -- ── Functional ────────────────────────────────────────────────────────────
  haskell     = { "fourmolu", "ormolu", stop_after_first = true },
  ocaml       = { "ocamlformat" },
  elixir      = { "mix" },
  erlang      = { "erlfmt" },
  gleam       = { "gleam" },

  -- ── Config / Data ──────────────────────────────────────────────────────────
  json        = { "biome", "prettierd", "prettier", stop_after_first = true },
  jsonc       = { "biome", "prettierd", "prettier", stop_after_first = true },
  yaml        = { "yamlfmt", "prettierd", "prettier", stop_after_first = true },
  toml        = { "taplo" },
  xml         = { "xmllint" },

  -- ── Infrastructure ─────────────────────────────────────────────────────────
  dockerfile  = { "trim_whitespace" },
  terraform   = { "terraform_fmt" },
  hcl         = { "terragrunt_hclfmt" },
  nix         = { "alejandra", "nixfmt", stop_after_first = true },

  -- ── SQL ───────────────────────────────────────────────────────────────────
  sql         = { "sqlfmt", "sql_formatter", stop_after_first = true },
  mysql       = { "sql_formatter" },
  plsql       = { "sql_formatter" },

  -- ── Markup & Docs ──────────────────────────────────────────────────────────
  markdown    = { "prettierd", "prettier", stop_after_first = true },
  rst         = { "rstfmt" },
  tex         = { "latexindent" },
  latex       = { "latexindent" },
  bibtex      = { "bibtex_tidy" },
  org         = { "trim_whitespace" },

  -- ── Scripting ─────────────────────────────────────────────────────────────
  ruby        = { "rubocop" },
  php         = { "php_cs_fixer" },
  perl        = { "perltidy" },

  -- ── Protobuf ──────────────────────────────────────────────────────────────
  proto       = { "buf" },

  -- ── Hyprland ──────────────────────────────────────────────────────────────
  hypr        = { "trim_whitespace", "trim_newlines" },

  -- ── Catch-all ─────────────────────────────────────────────────────────────
  ["_"]       = { "trim_whitespace", "trim_newlines" },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 FORMATTER CONFIGURATIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.formatters = {
  -- ── stylua ────────────────────────────────────────────────────────────────
  stylua = {
    prepend_args = {
      "--config-path", vim.fn.stdpath("config") .. "/stylua.toml",
    },
  },

  -- ── shfmt ─────────────────────────────────────────────────────────────────
  shfmt = {
    prepend_args = function(_, ctx)
      local indent = vim.bo[ctx.buf].expandtab
        and tostring(vim.bo[ctx.buf].shiftwidth) or "0"
      return { "-i", indent, "-ci", "-bn", "-sr" }
    end,
  },

  -- ── black ─────────────────────────────────────────────────────────────────
  black = {
    prepend_args = {
      "--fast", "--line-length", "100", "--skip-magic-trailing-comma",
    },
  },

  -- ── isort ─────────────────────────────────────────────────────────────────
  isort = {
    prepend_args = { "--profile", "black", "--line-length", "100" },
  },

  -- ── ruff_fix ──────────────────────────────────────────────────────────────
  ruff_fix = {
    command = "ruff",
    args    = {
      "check", "--fix", "--select=I",
      "--stdin-filename", "$FILENAME", "-",
    },
    stdin = true,
    cwd   = require("conform.util").root_file({
      "pyproject.toml", "setup.cfg", "ruff.toml", ".ruff.toml",
    }),
  },

  -- ── ruff_format ───────────────────────────────────────────────────────────
  ruff_format = {
    command = "ruff",
    args    = { "format", "--stdin-filename", "$FILENAME", "-" },
    stdin   = true,
    cwd     = require("conform.util").root_file({
      "pyproject.toml", "setup.cfg", "ruff.toml", ".ruff.toml",
    }),
  },

  -- ── prettier ──────────────────────────────────────────────────────────────
  prettier = {
    prepend_args = {
      "--tab-width", "2",
      "--single-quote",
      "--trailing-comma", "es5",
      "--print-width", "100",
      "--prose-wrap", "always",
    },
    cwd = require("conform.util").root_file({
      ".prettierrc", ".prettierrc.js", ".prettierrc.json",
      ".prettierrc.yml", "prettier.config.js", "package.json",
    }),
  },

  -- ── prettierd ─────────────────────────────────────────────────────────────
  prettierd = {
    env = {
      PRETTIERD_DEFAULT_CONFIG = vim.fn.expand(
        "~/.config/prettier/.prettierrc.json"
      ),
    },
  },

  -- ── biome ─────────────────────────────────────────────────────────────────
  biome = {
    condition = function(_, ctx)
      return vim.fs.find(
        { "biome.json", "biome.jsonc" },
        { upward = true, path = ctx.dirname }
      )[1] ~= nil
    end,
  },

  -- ── clang_format ─────────────────────────────────────────────────────────
  clang_format = {
    prepend_args = { "--style=file", "--fallback-style=LLVM" },
  },

  -- ── gofumpt ───────────────────────────────────────────────────────────────
  gofumpt = { extra_args = { "-extra" } },

  -- ── goimports ─────────────────────────────────────────────────────────────
  goimports = { extra_args = { "-local", "" } },

  -- ── rustfmt ───────────────────────────────────────────────────────────────
  rustfmt = {
    extra_args = function(_, ctx)
      local cargo = vim.fs.find("Cargo.toml", {
        upward = true, path = ctx.dirname,
      })[1]
      if cargo then
        for line in io.lines(cargo) do
          local ed = line:match("^edition%s*=%s*\"(%d+)\"")
          if ed then return { "--edition=" .. ed } end
        end
      end
      return { "--edition=2021" }
    end,
  },

  -- ── latexindent ────────────────────────────────────────────────────────────
  latexindent = { prepend_args = { "-m", "-l" } },

  -- ── yamlfmt ───────────────────────────────────────────────────────────────
  yamlfmt = {
    prepend_args = {
      "-formatter", "retain_line_breaks=true,max_line_length=120",
    },
  },

  -- ── sql_formatter ─────────────────────────────────────────────────────────
  sql_formatter = {
    prepend_args = { "--language", "postgresql", "--lines-between-queries", "2" },
  },

  -- ── nixfmt ────────────────────────────────────────────────────────────────
  nixfmt = { extra_args = { "--width", "100" } },

  -- ── taplo ─────────────────────────────────────────────────────────────────
  taplo = { extra_args = { "format", "-" } },

  -- ── ocamlformat ───────────────────────────────────────────────────────────
  ocamlformat = {
    condition = function(_, ctx)
      return vim.fs.find(
        { ".ocamlformat" },
        { upward = true, path = ctx.dirname }
      )[1] ~= nil
    end,
  },
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 MASON ENSURE INSTALLED (formatters subset)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.mason_ensure = {
  -- Multi-language
  "prettier",   "prettierd",  "biome",
  -- Lua
  "stylua",
  -- Python
  "black",      "isort",      "ruff",
  -- Go
  "gofumpt",    "goimports",  "golines",
  -- Shell
  "shfmt",      "beautysh",
  -- C/C++
  "clang-format",
  -- Java
  "google-java-format",
  -- Kotlin
  "ktfmt",
  -- Haskell
  "fourmolu",   "ormolu",
  -- OCaml
  "ocamlformat",
  -- Nix
  "nixfmt",     "alejandra",
  -- SQL
  "sql-formatter", "sqlfmt",
  -- YAML
  "yamlfmt",
  -- Markdown
  "mdformat",   "cbfmt",
  -- LaTeX
  "latexindent",
  -- Protobuf
  "buf",
  -- Terraform
  "terraform",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔌 FORMAT-ON-SAVE EXCLUSIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

M.format_on_save_exclude_ft = {
  "bigfile",  "snacks_picker_list",
  "neo-tree", "Trouble",  "lazy",  "mason",
}

M.format_on_save_exclude_bt = {
  "terminal", "nofile", "nowrite", "prompt", "quickfix",
}

return M