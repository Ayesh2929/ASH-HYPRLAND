-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 CONFORM.NVIM — ULTRA FORMATTER ENGINE v5.0 OMEGA                      ║
-- ║   50+ formatters · async · format-on-save · injected language support          ║
-- ║   per-filetype chains · timeout control · ASH theme diagnostics               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — format status indicators
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
    hl(0, "ConformFormatting",     { bold = true, fg = "#7aa2f7"             })
    hl(0, "ConformFormatDone",     { bold = true, fg = "#9ece6a"             })
    hl(0, "ConformFormatError",    { bold = true, fg = "#f38ba8"             })
    hl(0, "ConformFormatDisabled", { italic = true, fg = "#545c7e"           })
    hl(0, "ConformFormatterName",  { italic = true, fg = "#bb9af7"           })
    hl(0, "ConformFormatTimeout",  { bold = true, fg = "#f9e2af"             })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "ConformFormatting",     { bold = true, fg = p.blue   }) end
      if p.green  then hl(0, "ConformFormatDone",     { bold = true, fg = p.green  }) end
      if p.red    then hl(0, "ConformFormatError",    { bold = true, fg = p.red    }) end
      if p.mauve  then hl(0, "ConformFormatterName",  { italic = true, fg = p.mauve }) end
      if p.yellow then hl(0, "ConformFormatTimeout",  { bold = true, fg = p.yellow }) end
      if p.overlay0 then hl(0, "ConformFormatDisabled", { italic = true, fg = p.overlay0 }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 FORMAT-ON-SAVE STATE — toggle-able per session
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _format_on_save_enabled = true
  
  local function toggle_format_on_save()
    _format_on_save_enabled = not _format_on_save_enabled
    vim.notify(
      string.format(
        "🎨 Format-on-save %s",
        _format_on_save_enabled and " enabled" or " disabled"
      ),
      vim.log.levels.INFO,
      { title = "Conform", timeout = 1500 }
    )
  end
  
  -- Per-buffer format-on-save disable (e.g. for generated files)
  local DISABLE_AUTOFORMAT_FILETYPES = {
    "bigfile",
    "snacks_picker_list",
    "neo-tree",
  }
  
  local DISABLE_AUTOFORMAT_BUFTYPES = {
    "terminal",
    "nofile",
    "nowrite",
    "prompt",
    "quickfix",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART FORMAT HELPER — notify + format
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function format_buffer(opts)
    return function()
      local conform  = require("conform")
      local bufnr    = vim.api.nvim_get_current_buf()
      local formatters = conform.list_formatters(bufnr)
  
      if #formatters == 0 then
        vim.notify(
          "🎨 No formatter available for " .. vim.bo.filetype,
          vim.log.levels.WARN,
          { title = "Conform" }
        )
        return
      end
  
      local names = table.concat(
        vim.tbl_map(function(f) return f.name end, formatters),
        " → "
      )
  
      vim.notify(
        string.format("🎨 Formatting with: %s", names),
        vim.log.levels.INFO,
        { title = "Conform", timeout = 1000 }
      )
  
      conform.format(vim.tbl_extend("force", {
        bufnr      = bufnr,
        async      = true,
        lsp_format = "fallback",
        timeout_ms = 5000,
      }, opts or {}))
    end
  end
  
  local function format_selection()
    local conform = require("conform")
    local bufnr   = vim.api.nvim_get_current_buf()
    local s       = vim.api.nvim_buf_get_mark(bufnr, "<")
    local e       = vim.api.nvim_buf_get_mark(bufnr, ">")
  
    conform.format({
      bufnr      = bufnr,
      async      = true,
      lsp_format = "fallback",
      range      = { start = s, ["end"] = e },
      timeout_ms = 5000,
    })
  end
  
  local function show_formatter_info()
    local conform  = require("conform")
    local bufnr    = vim.api.nvim_get_current_buf()
    local fmts     = conform.list_formatters(bufnr)
    local avail    = conform.list_formatters_to_run(bufnr)
  
    if #fmts == 0 then
      vim.notify(
        "🎨 No formatters configured for: " .. vim.bo.filetype,
        vim.log.levels.WARN,
        { title = "Conform Info" }
      )
      return
    end
  
    local lines = {
      string.format("🎨 Conform Formatters — %s", vim.bo.filetype),
      "─────────────────────────────────────",
    }
  
    for _, fmt in ipairs(fmts) do
      local active   = vim.tbl_contains(
        vim.tbl_map(function(a) return a.name end, avail), fmt.name
      )
      local status   = active and "✅" or "⭕"
      local exe      = fmt.command or fmt.name
      local exe_path = vim.fn.exepath(exe)
      table.insert(lines, string.format(
        "  %s %-20s  %s",
        status,
        fmt.name,
        exe_path ~= "" and exe_path or "(not found)"
      ))
    end
  
    table.insert(lines, "─────────────────────────────────────")
    table.insert(lines, string.format(
      "  Format-on-save: %s",
      _format_on_save_enabled and "✅ enabled" or "⭕ disabled"
    ))
  
    vim.notify(
      table.concat(lines, "\n"),
      vim.log.levels.INFO,
      { title = "Conform Info" }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "stevearc/conform.nvim",
      event        = { "BufWritePre" },
      cmd          = { "ConformInfo", "Format", "FormatEnable", "FormatDisable" },
      dependencies = {
        { "williamboman/mason.nvim", optional = true },
      },
  
      -- ── Keys ──────────────────────────────────────────────────────────────────
      keys = {
        {
          "<leader>lf",
          format_buffer(),
          mode  = { "n", "v" },
          desc  = "🎨 Format Buffer",
          silent = true,
        },
        {
          "<leader>lF",
          format_buffer({ lsp_format = "never" }),
          mode  = "n",
          desc  = "🎨 Format (conform only, no LSP)",
          silent = true,
        },
        {
          "<leader>lv",
          format_selection,
          mode  = "v",
          desc  = "🎨 Format Selection",
          silent = true,
        },
        {
          "<leader>uf",
          toggle_format_on_save,
          desc  = "🎨 Toggle Format-on-Save",
          silent = true,
        },
        {
          "<leader>uF",
          function()
            vim.b.disable_autoformat = not vim.b.disable_autoformat
            vim.notify(
              string.format(
                "🎨 Buffer format-on-save %s",
                vim.b.disable_autoformat and " disabled" or " enabled"
              ),
              vim.log.levels.INFO,
              { title = "Conform", timeout = 1500 }
            )
          end,
          desc  = "🎨 Toggle Buffer Format-on-Save",
          silent = true,
        },
        {
          "<leader>li",
          show_formatter_info,
          desc  = "🎨 Formatter Info",
          silent = true,
        },
        {
          "<leader>lI",
          "<cmd>ConformInfo<cr>",
          desc  = "🎨 Conform Info (full)",
          silent = true,
        },
      },
  
      -- ── Options ───────────────────────────────────────────────────────────────
      opts = {
        -- ── Formatters by filetype ─────────────────────────────────────────────
        -- Each entry is a list of formatters tried left-to-right
        -- Use { name, stop_after_first = true } to stop on first success
        formatters_by_ft = {
          -- ── Lua ──────────────────────────────────────────────────────────────
          lua           = { "stylua" },
  
          -- ── Python ────────────────────────────────────────────────────────────
          python        = function(bufnr)
            -- Use ruff if available, else black + isort
            if require("conform").get_formatter_info("ruff_format", bufnr).available then
              return { "ruff_fix", "ruff_format" }
            end
            return { "isort", "black" }
          end,
  
          -- ── JavaScript / TypeScript ────────────────────────────────────────────
          javascript         = { "biome", "prettierd", "prettier", stop_after_first = true },
          javascriptreact    = { "biome", "prettierd", "prettier", stop_after_first = true },
          typescript         = { "biome", "prettierd", "prettier", stop_after_first = true },
          typescriptreact    = { "biome", "prettierd", "prettier", stop_after_first = true },
          ["typescript.tsx"] = { "biome", "prettierd", "prettier", stop_after_first = true },
          ["javascript.jsx"] = { "biome", "prettierd", "prettier", stop_after_first = true },
  
          -- ── Web ───────────────────────────────────────────────────────────────
          html          = { "prettierd", "prettier", stop_after_first = true },
          css           = { "prettierd", "prettier", stop_after_first = true },
          scss          = { "prettierd", "prettier", stop_after_first = true },
          less          = { "prettierd", "prettier", stop_after_first = true },
          vue           = { "prettierd", "prettier", stop_after_first = true },
          svelte        = { "prettierd", "prettier", stop_after_first = true },
          astro         = { "prettierd", "prettier", stop_after_first = true },
          graphql       = { "prettierd", "prettier", stop_after_first = true },
          handlebars    = { "prettierd", "prettier", stop_after_first = true },
          mdx           = { "prettierd", "prettier", stop_after_first = true },
  
          -- ── Go ────────────────────────────────────────────────────────────────
          go            = { "goimports", "gofumpt" },
  
          -- ── Rust ──────────────────────────────────────────────────────────────
          rust          = { "rustfmt" },
  
          -- ── Shell ─────────────────────────────────────────────────────────────
          sh            = { "shfmt" },
          bash          = { "shfmt" },
          zsh           = { "shfmt" },
  
          -- ── Fish ──────────────────────────────────────────────────────────────
          fish          = { "fish_indent" },
  
          -- ── Systems ───────────────────────────────────────────────────────────
          c             = { "clang_format" },
          cpp           = { "clang_format" },
          cuda          = { "clang_format" },
          cs            = { "csharpier" },
          java          = { "google_java_format" },
          kotlin        = { "ktfmt" },
          swift         = { "swiftformat" },
          dart          = { "dart_format" },
          zig           = { "zigfmt" },
          odin          = { "odinfmt" },
  
          -- ── JVM ───────────────────────────────────────────────────────────────
          scala         = { "scalafmt" },
          groovy        = { "npm_groovy_lint" },
  
          -- ── Functional ────────────────────────────────────────────────────────
          haskell       = { "fourmolu", "ormolu", stop_after_first = true },
          ocaml         = { "ocamlformat" },
          elixir        = { "mix" },
          erlang        = { "erlfmt" },
          gleam         = { "gleam" },
          elm           = { "elm_format" },
          clojure       = { "cljfmt" },
          fennel        = { "fnlfmt" },
  
          -- ── Config / Data ──────────────────────────────────────────────────────
          json          = { "biome", "prettierd", "prettier", stop_after_first = true },
          jsonc         = { "biome", "prettierd", "prettier", stop_after_first = true },
          yaml          = { "yamlfmt", "prettierd", "prettier", stop_after_first = true },
          toml          = { "taplo" },
          xml           = { "xmllint" },
          ini           = { "trim_whitespace" },
  
          -- ── Infrastructure ─────────────────────────────────────────────────────
          dockerfile    = { "trim_whitespace" },
          terraform     = { "terraform_fmt" },
          hcl           = { "terragrunt_hclfmt" },
          nix           = { "alejandra", "nixfmt", stop_after_first = true },
  
          -- ── SQL ───────────────────────────────────────────────────────────────
          sql           = { "sqlfmt", "sql_formatter", stop_after_first = true },
          mysql         = { "sql_formatter" },
          plsql         = { "sql_formatter" },
  
          -- ── Markup & Docs ──────────────────────────────────────────────────────
          markdown      = { "prettierd", "prettier", stop_after_first = true },
          rst           = { "rstfmt" },
          tex           = { "latexindent" },
          latex         = { "latexindent" },
          bibtex        = { "bibtex_tidy" },
          org           = { "trim_whitespace" },
  
          -- ── Scripting ─────────────────────────────────────────────────────────
          ruby          = { "rubocop" },
          php           = { "php_cs_fixer" },
          perl          = { "perltidy" },
          r             = { "formatR" },
  
          -- ── Web build tools ────────────────────────────────────────────────────
          ["html.handlebars"] = { "prettierd" },
          heex          = { "mix" },
          eelixir       = { "mix" },
  
          -- ── Proto ─────────────────────────────────────────────────────────────
          proto         = { "buf" },
  
          -- ── WGSL / GLSL ───────────────────────────────────────────────────────
          wgsl          = { "trim_whitespace" },
          glsl          = { "clang_format" },
  
          -- ── Hyprland ──────────────────────────────────────────────────────────
          hypr          = { "trim_whitespace", "trim_newlines" },
  
          -- ── Rasi (Rofi) ───────────────────────────────────────────────────────
          rasi          = { "trim_whitespace" },
  
          -- ── Catch-all: trim trailing whitespace ────────────────────────────────
          ["_"]         = { "trim_whitespace", "trim_newlines" },
        },
  
        -- ── Formatter configurations ────────────────────────────────────────────
        formatters = {
          -- ── stylua ─────────────────────────────────────────────────────────────
          stylua = {
            prepend_args = {
              "--config-path",
              vim.fn.stdpath("config") .. "/stylua.toml",
            },
          },
  
          -- ── shfmt ──────────────────────────────────────────────────────────────
          shfmt = {
            prepend_args = function(_self, ctx)
              -- Detect indent from buffer settings
              local indent = vim.bo[ctx.buf].expandtab
                             and tostring(vim.bo[ctx.buf].shiftwidth)
                             or "0"
              return { "-i", indent, "-ci", "-bn", "-sr" }
            end,
          },
  
          -- ── black ──────────────────────────────────────────────────────────────
          black = {
            prepend_args = {
              "--fast",
              "--line-length", "100",
              "--skip-magic-trailing-comma",
            },
          },
  
          -- ── isort ──────────────────────────────────────────────────────────────
          isort = {
            prepend_args = {
              "--profile", "black",
              "--line-length", "100",
            },
          },
  
          -- ── ruff_fix ───────────────────────────────────────────────────────────
          ruff_fix = {
            command        = "ruff",
            args           = {
              "check",
              "--fix",
              "--select=I",          -- import sorting
              "--stdin-filename", "$FILENAME",
              "-",
            },
            stdin          = true,
            cwd            = require("conform.util").root_file({
              "pyproject.toml", "setup.cfg", "ruff.toml", ".ruff.toml",
            }),
          },
  
          -- ── ruff_format ────────────────────────────────────────────────────────
          ruff_format = {
            command        = "ruff",
            args           = {
              "format",
              "--stdin-filename", "$FILENAME",
              "-",
            },
            stdin          = true,
            cwd            = require("conform.util").root_file({
              "pyproject.toml", "setup.cfg", "ruff.toml", ".ruff.toml",
            }),
          },
  
          -- ── prettier ───────────────────────────────────────────────────────────
          prettier = {
            prepend_args = {
              "--tab-width", "2",
              "--single-quote",
              "--trailing-comma", "es5",
              "--print-width", "100",
              "--prose-wrap", "always",
            },
            cwd            = require("conform.util").root_file({
              ".prettierrc", ".prettierrc.js", ".prettierrc.cjs",
              ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml",
              "prettier.config.js", "prettier.config.cjs",
              "package.json",
            }),
          },
  
          -- ── prettierd (daemon version — faster) ────────────────────────────────
          prettierd = {
            env = {
              PRETTIERD_DEFAULT_CONFIG = vim.fn.expand("~/.config/prettier/.prettierrc.json"),
            },
          },
  
          -- ── biome ──────────────────────────────────────────────────────────────
          biome = {
            condition      = function(_self, ctx)
              -- Only use biome if biome.json / biome.jsonc present
              return vim.fs.find(
                { "biome.json", "biome.jsonc" },
                { upward = true, path = ctx.dirname }
              )[1] ~= nil
            end,
          },
  
          -- ── clang_format ───────────────────────────────────────────────────────
          clang_format = {
            prepend_args = {
              "--style=file",
              "--fallback-style=LLVM",
            },
          },
  
          -- ── gofumpt ────────────────────────────────────────────────────────────
          gofumpt = {
            extra_args = { "-extra" },
          },
  
          -- ── goimports ──────────────────────────────────────────────────────────
          goimports = {
            extra_args = { "-local", "" },
          },
  
          -- ── rustfmt ────────────────────────────────────────────────────────────
          rustfmt = {
            extra_args     = function(self, ctx)
              -- Detect edition from Cargo.toml
              local cargo = vim.fs.find("Cargo.toml", {
                upward = true,
                path   = ctx.dirname,
              })[1]
              if cargo then
                for line in io.lines(cargo) do
                  local edition = line:match("^edition%s*=%s*\"(%d+)\"")
                  if edition then
                    return { "--edition=" .. edition }
                  end
                end
              end
              return { "--edition=2021" }
            end,
          },
  
          -- ── latexindent ────────────────────────────────────────────────────────
          latexindent = {
            prepend_args   = { "-m", "-l" },
          },
  
          -- ── yamlfmt ────────────────────────────────────────────────────────────
          yamlfmt = {
            prepend_args   = {
              "-formatter", "retain_line_breaks=true,max_line_length=120",
            },
          },
  
          -- ── fourmolu ───────────────────────────────────────────────────────────
          fourmolu = {
            prepend_args   = { "--mode=check" },
          },
  
          -- ── sql_formatter ──────────────────────────────────────────────────────
          sql_formatter = {
            prepend_args   = {
              "--language", "postgresql",
              "--lines-between-queries", "2",
            },
          },
  
          -- ── nixfmt ─────────────────────────────────────────────────────────────
          nixfmt = {
            extra_args     = { "--width", "100" },
          },
  
          -- ── taplo (TOML) ───────────────────────────────────────────────────────
          taplo = {
            extra_args     = { "format", "-" },
          },
  
          -- ── ocamlformat ────────────────────────────────────────────────────────
          ocamlformat = {
            condition      = function(self, ctx)
              return vim.fs.find(
                { ".ocamlformat" },
                { upward = true, path = ctx.dirname }
              )[1] ~= nil
            end,
          },
  
          -- ── trim_whitespace (always available) ─────────────────────────────────
          trim_whitespace = {
            command = "awk",
            args    = { "{ sub(/[[:space:]]+$/, \"\"); print }" },
            stdin   = true,
          },
  
          -- ── trim_newlines ──────────────────────────────────────────────────────
          trim_newlines = {
            command = "awk",
            args    = { "NF { buf = buf $0 \"\\n\" } END { printf \"%s\", buf }", },
            stdin   = true,
          },
  
          -- ── inject_language: format embedded code blocks ────────────────────────
          inject = {
            options    = {
              ignore_errors = true,
            },
          },
        },
  
        -- ── Format-on-save ─────────────────────────────────────────────────────────
        format_on_save = function(bufnr)
          -- Check global toggle
          if not _format_on_save_enabled then return nil end
  
          -- Check buffer-local disable
          if vim.b[bufnr].disable_autoformat then return nil end
  
          -- Check filetype exclusions
          if vim.tbl_contains(DISABLE_AUTOFORMAT_FILETYPES, vim.bo[bufnr].filetype) then
            return nil
          end
  
          -- Check buftype exclusions
          if vim.tbl_contains(DISABLE_AUTOFORMAT_BUFTYPES, vim.bo[bufnr].buftype) then
            return nil
          end
  
          -- Check file size (don't format huge files)
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if line_count > 5000 then return nil end
  
          return {
            lsp_format = "fallback",
            timeout_ms = 3000,
          }
        end,
  
        -- ── Format after save (async for slow formatters) ──────────────────────────
        format_after_save = function(bufnr)
          -- Slow formatters run async after save
          local slow_fts = {
            "python",    -- mypy / pylint
            "go",        -- goimports can be slow
            "haskell",   -- fourmolu
            "tex",       -- latexindent
          }
          if not vim.tbl_contains(slow_fts, vim.bo[bufnr].filetype) then
            return nil
          end
          if not _format_on_save_enabled then return nil end
          if vim.b[bufnr].disable_autoformat then return nil end
  
          return { lsp_format = "fallback" }
        end,
  
        -- ── Logging ───────────────────────────────────────────────────────────────
        log_level     = vim.log.levels.WARN,
        notify_on_error = true,
        notify_no_formatters = true,
  
        -- ── Default format options ─────────────────────────────────────────────────
        default_format_opts = {
          lsp_format  = "fallback",
          timeout_ms  = 5000,
          async       = false,
          quiet       = false,
        },
      },
  
      -- ── Config ────────────────────────────────────────────────────────────────────
      config = function(_, opts)
        require("conform").setup(opts)
  
        setup_highlights()
  
        -- ── User commands ──────────────────────────────────────────────────────────
        vim.api.nvim_create_user_command("Format", function(args)
          local range = nil
          if args.count ~= -1 then
            local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)
            range = {
              start   = { args.line1, 0 },
              ["end"] = { args.line2, #end_line[1] },
            }
          end
          require("conform").format({
            async      = true,
            lsp_format = "fallback",
            range      = range,
            timeout_ms = 5000,
          })
        end, {
          range = true,
          desc  = "🎨 Format buffer or range",
        })
  
        vim.api.nvim_create_user_command("FormatEnable", function()
          _format_on_save_enabled      = true
          vim.b.disable_autoformat     = false
          vim.notify(
            "🎨 Format-on-save  enabled",
            vim.log.levels.INFO,
            { title = "Conform" }
          )
        end, { desc = "🎨 Enable format-on-save" })
  
        vim.api.nvim_create_user_command("FormatDisable", function(args)
          if args.bang then
            -- FormatDisable! = disable globally
            _format_on_save_enabled = false
            vim.notify(
              "🎨 Format-on-save  disabled (global)",
              vim.log.levels.INFO,
              { title = "Conform" }
            )
          else
            -- FormatDisable = disable for current buffer only
            vim.b.disable_autoformat = true
            vim.notify(
              "🎨 Format-on-save  disabled (buffer)",
              vim.log.levels.INFO,
              { title = "Conform" }
            )
          end
        end, {
          bang  = true,
          desc  = "🎨 Disable format-on-save",
        })
  
        -- ── Autocmds ──────────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshConform", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🎨 Conform highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Conform", timeout = 1200 }
            )
          end,
        })
  
        -- Expose global format-on-save state for statusline
        _G.AshFormatOnSave = function()
          if not _format_on_save_enabled then
            return " 󰉨 "
          end
          return ""
        end
  
        if vim.g.ash_debug then
          local conform     = require("conform")
          local ft_count    = vim.tbl_count(opts.formatters_by_ft or {})
          local fmt_count   = vim.tbl_count(opts.formatters or {})
          vim.notify(
            string.format(
              "🎨 Conform loaded — %d filetypes, %d formatter configs",
              ft_count, fmt_count
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Conform" }
          )
        end
      end,
    },
  }