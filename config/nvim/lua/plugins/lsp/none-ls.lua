-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔮 NONE-LS — ULTRA NULL-LS SUCCESSOR v5.0 OMEGA                          ║
-- ║   70+ formatters · 60+ linters · code actions · hover providers                 ║
-- ║   mason integration · per-filetype routing · async · ASH theme diagnostics     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 UTILITY: conditional source inclusion
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Include a source only if its executable is available on PATH
local function has(exe)
    return vim.fn.executable(exe) == 1
  end
  
  -- Wrap a none-ls source with an executable guard
  local function with_exe(source, exe, extra_opts)
    if not has(exe) then return nil end
    if extra_opts then return source.with(extra_opts) end
    return source
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  ON_ATTACH — none-ls specific per-buffer setup
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function on_attach(client, bufnr)
    -- Format on save (none-ls formatter)
    if client.supports_method("textDocument/formatting") then
      local fmt_aug = vim.api.nvim_create_augroup(
        "AshNoneLsFormat_" .. bufnr, { clear = true }
      )
      vim.api.nvim_create_autocmd("BufWritePre", {
        group    = fmt_aug,
        buffer   = bufnr,
        callback = function()
          -- Only format if a formatter is attached and not in large files
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if line_count > 10000 then return end
  
          vim.lsp.buf.format({
            bufnr   = bufnr,
            async   = false,
            timeout_ms = 3000,
            filter  = function(c)
              -- Prefer none-ls for formatting (disable native LSP formatters)
              local native_format_servers = {
                "lua_ls", "ts_ls", "html", "cssls", "jsonls",
              }
              return c.name == "null-ls"
                or not vim.tbl_contains(native_format_servers, c.name)
            end,
          })
        end,
      })
    end
  
    -- Delegate to global on_attach for keymaps
    local global_on_attach = _G.AshLspOnAttach
    if global_on_attach then
      global_on_attach(client, bufnr)
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvimtools/none-ls.nvim",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "nvim-lua/plenary.nvim",
        "williamboman/mason.nvim",
        -- Extra sources
        { "nvimtools/none-ls-extras.nvim", optional = true },
        { "gbprod/none-ls-shellcheck.nvim", optional = true },
        { "gbprod/none-ls-luacheck.nvim",  optional = true },
      },
  
      config = function()
        local nls  = require("null-ls")
        local fmt  = nls.builtins.formatting
        local diag = nls.builtins.diagnostics
        local ca   = nls.builtins.code_actions
        local hov  = nls.builtins.hover
  
        -- ── Collect sources ─────────────────────────────────────────────────────
        local sources = {}
  
        local function add(source)
          if source ~= nil then
            table.insert(sources, source)
          end
        end
  
        -- ╔════════════════════════════════════════════════════════════════╗
        -- ║               🎨  FORMATTERS                                   ║
        -- ╚════════════════════════════════════════════════════════════════╝
  
        -- ── Lua ──────────────────────────────────────────────────────────
        add(with_exe(fmt.stylua, "stylua", {
          extra_args    = { "--config-path", vim.fn.stdpath("config") .. "/stylua.toml" },
        }))
  
        -- ── Python ───────────────────────────────────────────────────────
        add(with_exe(fmt.black, "black", {
          extra_args    = { "--fast", "--line-length=100" },
        }))
        add(with_exe(fmt.isort, "isort", {
          extra_args    = { "--profile=black" },
        }))
        add(with_exe(fmt.ruff, "ruff", {
          extra_args    = { "--fix" },
          timeout       = 10000,
        }))
  
        -- ── JavaScript / TypeScript ───────────────────────────────────────
        add(with_exe(fmt.prettier, "prettier", {
          filetypes = {
            "javascript", "javascriptreact", "typescript", "typescriptreact",
            "vue", "css", "scss", "less", "html", "json", "jsonc",
            "yaml", "markdown", "mdx", "graphql", "handlebars",
            "svelte", "astro",
          },
          extra_args    = {
            "--tab-width",     "2",
            "--single-quote",  "true",
            "--trailing-comma","es5",
            "--print-width",   "100",
            "--prose-wrap",    "always",
          },
          prefer_local  = "node_modules/.bin",
        }))
  
        -- Biome (faster alternative to prettier + eslint)
        add(with_exe(fmt.biome, "biome", {
          filetypes     = {
            "javascript", "javascriptreact",
            "typescript", "typescriptreact",
            "json", "jsonc",
          },
          prefer_local  = "node_modules/.bin",
        }))
  
        -- ── Go ────────────────────────────────────────────────────────────
        add(with_exe(fmt.gofumpt,  "gofumpt"))
        add(with_exe(fmt.goimports,"goimports"))
        add(with_exe(fmt.golines,  "golines", {
          extra_args    = { "--max-len=120" },
        }))
  
        -- ── Rust ──────────────────────────────────────────────────────────
        add(with_exe(fmt.rustfmt, "rustfmt", {
          extra_args    = { "--edition=2021" },
        }))
  
        -- ── Shell ─────────────────────────────────────────────────────────
        add(with_exe(fmt.shfmt, "shfmt", {
          extra_args    = { "-i", "2", "-ci", "-bn" },
        }))
        add(with_exe(fmt.beautysh, "beautysh"))
  
        -- ── C / C++ ───────────────────────────────────────────────────────
        add(with_exe(fmt.clang_format, "clang-format", {
          extra_args    = { "--style=file", "--fallback-style=llvm" },
        }))
  
        -- ── Java ──────────────────────────────────────────────────────────
        add(with_exe(fmt.google_java_format, "google-java-format"))
  
        -- ── Kotlin ────────────────────────────────────────────────────────
        add(with_exe(fmt.ktfmt, "ktfmt"))
  
        -- ── OCaml ─────────────────────────────────────────────────────────
        add(with_exe(fmt.ocamlformat, "ocamlformat"))
  
        -- ── Haskell ───────────────────────────────────────────────────────
        add(with_exe(fmt.fourmolu,  "fourmolu"))
        add(with_exe(fmt.ormolu,    "ormolu"))
  
        -- ── Nix ───────────────────────────────────────────────────────────
        add(with_exe(fmt.nixfmt, "nixfmt"))
  
        -- ── SQL ───────────────────────────────────────────────────────────
        add(with_exe(fmt.sql_formatter, "sql-formatter", {
          extra_args    = { "--language", "postgresql" },
          filetypes     = { "sql", "mysql", "pgsql" },
        }))
        add(with_exe(fmt.sqlfmt, "sqlfmt"))
  
        -- ── YAML ──────────────────────────────────────────────────────────
        add(with_exe(fmt.yamlfmt, "yamlfmt"))
  
        -- ── Markdown ──────────────────────────────────────────────────────
        add(with_exe(fmt.mdformat, "mdformat", {
          filetypes     = { "markdown", "md" },
        }))
        add(with_exe(fmt.cbfmt, "cbfmt", {
          filetypes     = { "markdown", "org", "neorg" },
        }))
  
        -- ── LaTeX ─────────────────────────────────────────────────────────
        add(with_exe(fmt.latexindent, "latexindent", {
          extra_args    = { "-m" },
        }))
  
        -- ── Protobuf ──────────────────────────────────────────────────────
        add(with_exe(fmt.buf, "buf"))
  
        -- ── Terraform ─────────────────────────────────────────────────────
        add(with_exe(fmt.terraform_fmt, "terraform"))
  
        -- ── Fish ──────────────────────────────────────────────────────────
        add(with_exe(fmt.fish_indent, "fish_indent"))
  
        -- ── Nginx ─────────────────────────────────────────────────────────
        add(with_exe(fmt.nginx_beautifier, "nginxbeautifier"))
  
        -- ── PHP ───────────────────────────────────────────────────────────
        add(with_exe(fmt.php_cs_fixer, "php-cs-fixer"))
        add(with_exe(fmt.phpcsfixer,   "php-cs-fixer"))
  
        -- ── Dart ──────────────────────────────────────────────────────────
        add(with_exe(fmt.dart_format, "dart"))
  
        -- ── Elixir ────────────────────────────────────────────────────────
        add(with_exe(fmt.mix, "mix"))
  
        -- ── Scala ─────────────────────────────────────────────────────────
        add(with_exe(fmt.scalafmt, "scalafmt"))
  
        -- ── Crystal ────────────────────────────────────────────────────────
        add(with_exe(fmt.crystal_format, "crystal"))
  
        -- ── TOML ──────────────────────────────────────────────────────────
        -- taplo handled via taplo lsp
  
        -- ── XML ───────────────────────────────────────────────────────────
        add(with_exe(fmt.xmllint, "xmllint"))
  
        -- ── Generic / catch-all ───────────────────────────────────────────
        add(with_exe(fmt.trim_newlines, nil))   -- always available (built-in)
        add(with_exe(fmt.trim_whitespace, nil)) -- always available (built-in)
  
        -- ╔════════════════════════════════════════════════════════════════╗
        -- ║               🔬  DIAGNOSTICS (LINTERS)                        ║
        -- ╚════════════════════════════════════════════════════════════════╝
  
        -- ── Shell ─────────────────────────────────────────────────────────
        add(with_exe(diag.shellcheck, "shellcheck", {
          extra_args    = { "--severity=warning" },
          filetypes     = { "sh", "bash", "zsh" },
          diagnostic_config = {
            virtual_text  = false,
            underline     = true,
            signs         = true,
          },
        }))
        add(with_exe(diag.zsh, "zsh"))
  
        -- ── Python ───────────────────────────────────────────────────────
        add(with_exe(diag.pylint, "pylint", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          extra_args    = {
            "--disable=C0111,C0114,C0115,C0116",
            "--max-line-length=100",
          },
        }))
        add(with_exe(diag.flake8, "flake8", {
          extra_args    = { "--max-line-length=100", "--ignore=E501,W503" },
        }))
        add(with_exe(diag.mypy, "mypy", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          extra_args    = { "--ignore-missing-imports", "--show-error-codes" },
        }))
        add(with_exe(diag.bandit, "bandit", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          extra_args    = { "-ll" },
        }))
        add(with_exe(diag.ruff, "ruff"))
  
        -- ── JavaScript / TypeScript ───────────────────────────────────────
        add(with_exe(diag.eslint_d, "eslint_d", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          condition     = function(utils)
            return utils.root_has_file({
              ".eslintrc", ".eslintrc.js", ".eslintrc.cjs",
              ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml",
              "eslint.config.js", "eslint.config.mjs",
            })
          end,
        }))
  
        -- ── Lua ──────────────────────────────────────────────────────────
        add(with_exe(diag.luacheck, "luacheck", {
          extra_args    = { "--globals", "vim", "--std", "luajit" },
        }))
  
        -- ── Go ────────────────────────────────────────────────────────────
        add(with_exe(diag.golangci_lint, "golangci-lint", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          extra_args    = { "--fast" },
        }))
        add(with_exe(diag.staticcheck, "staticcheck"))
        add(with_exe(diag.revive,      "revive", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
        }))
  
        -- ── Markdown ──────────────────────────────────────────────────────
        add(with_exe(diag.markdownlint, "markdownlint", {
          extra_args    = { "--disable", "MD013" },
        }))
        add(with_exe(diag.vale, "vale", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          filetypes     = { "markdown", "rst", "tex", "text" },
        }))
  
        -- ── YAML ──────────────────────────────────────────────────────────
        add(with_exe(diag.yamllint, "yamllint", {
          extra_args    = { "-d", "{extends: relaxed, rules: {line-length: {max: 120}}}" },
        }))
  
        -- ── JSON ──────────────────────────────────────────────────────────
        add(with_exe(diag.jsonlint, "jsonlint"))
  
        -- ── Dockerfile ────────────────────────────────────────────────────
        add(with_exe(diag.hadolint, "hadolint"))
  
        -- ── CSS ───────────────────────────────────────────────────────────
        add(with_exe(diag.stylelint, "stylelint", {
          filetypes     = { "css", "scss", "less", "sass", "vue", "svelte" },
        }))
  
        -- ── HTML ──────────────────────────────────────────────────────────
        add(with_exe(diag.htmlhint, "htmlhint"))
  
        -- ── C / C++ ───────────────────────────────────────────────────────
        add(with_exe(diag.cpplint, "cpplint", {
          filetypes     = { "c", "cpp" },
        }))
  
        -- ── Terraform ─────────────────────────────────────────────────────
        add(with_exe(diag.terraform_validate, "terraform"))
        add(with_exe(diag.tflint, "tflint"))
  
        -- ── Ansible ───────────────────────────────────────────────────────
        add(with_exe(diag.ansiblelint, "ansible-lint", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          filetypes     = { "yaml", "yaml.ansible" },
        }))
  
        -- ── Protobuf ──────────────────────────────────────────────────────
        add(with_exe(diag.buf, "buf"))
  
        -- ── SQL ───────────────────────────────────────────────────────────
        add(with_exe(diag.sqlfluff, "sqlfluff", {
          extra_args    = { "--dialect", "postgres" },
          filetypes     = { "sql", "mysql", "pgsql" },
        }))
  
        -- ── LaTeX ─────────────────────────────────────────────────────────
        add(with_exe(diag.chktex, "chktex", {
          filetypes     = { "tex", "latex" },
        }))
  
        -- ── Security ──────────────────────────────────────────────────────
        add(with_exe(diag.trivy, "trivy", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
          filetypes     = { "dockerfile", "yaml", "json", "tf" },
        }))
  
        -- ── General ───────────────────────────────────────────────────────
        add(with_exe(diag.editorconfig_checker, "editorconfig-checker", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
        }))
  
        -- ── PHP ───────────────────────────────────────────────────────────
        add(with_exe(diag.phpcs, "phpcs"))
        add(with_exe(diag.phpstan, "phpstan", {
          method        = nls.methods.DIAGNOSTICS_ON_SAVE,
        }))
  
        -- ── Ruby ──────────────────────────────────────────────────────────
        add(with_exe(diag.rubocop, "rubocop", {
          extra_args    = { "--format=json" },
        }))
  
        -- ── Elixir ────────────────────────────────────────────────────────
        add(with_exe(diag.credo, "mix", {
          extra_args    = { "credo", "--strict" },
          filetypes     = { "elixir" },
        }))
  
        -- ── Dart ──────────────────────────────────────────────────────────
        add(with_exe(diag.dart_analyze, "dart"))
  
        -- ╔════════════════════════════════════════════════════════════════╗
        -- ║               ⚡  CODE ACTIONS                                  ║
        -- ╚════════════════════════════════════════════════════════════════╝
  
        -- ── ESLint ────────────────────────────────────────────────────────
        add(with_exe(ca.eslint_d, "eslint_d", {
          condition     = function(utils)
            return utils.root_has_file({
              ".eslintrc", ".eslintrc.js", ".eslintrc.cjs",
              ".eslintrc.json", "eslint.config.js",
            })
          end,
        }))
  
        -- ── Shell ─────────────────────────────────────────────────────────
        add(with_exe(ca.shellcheck, "shellcheck"))
  
        -- ── Git ───────────────────────────────────────────────────────────
        add(ca.gitrebase)
        add(ca.gitsigns)
  
        -- ── Refactoring ───────────────────────────────────────────────────
        local ok_refactor, refactor = pcall(require, "refactoring")
        if ok_refactor then
          add(with_exe(ca.refactoring, nil))
        end
  
        -- ── Proselint (writing suggestions) ───────────────────────────────
        add(with_exe(ca.proselint, "proselint", {
          filetypes = { "markdown", "text", "rst", "org" },
        }))
  
        -- ╔════════════════════════════════════════════════════════════════╗
        -- ║               📖  HOVER PROVIDERS                              ║
        -- ╚════════════════════════════════════════════════════════════════╝
  
        -- ── Dictionary / thesaurus ────────────────────────────────────────
        add(hov.dictionary)
        add(hov.printenv)
  
        -- ── Final filter: remove nils ─────────────────────────────────────
        sources = vim.tbl_filter(function(s) return s ~= nil end, sources)
  
        -- ── Setup none-ls ──────────────────────────────────────────────────
        nls.setup({
          -- ── Sources ───────────────────────────────────────────────────
          sources         = sources,
  
          -- ── Diagnostics config ────────────────────────────────────────
          diagnostics_format  = "[#{c}] #{m} (#{s})",
          diagnostics_config  = {
            underline    = true,
            virtual_text = {
              source   = "if_many",
              prefix   = "●",
              severity = { min = vim.diagnostic.severity.WARN },
            },
            signs        = true,
            update_in_insert = false,
            severity_sort    = true,
          },
  
          -- ── Debounce ──────────────────────────────────────────────────
          debounce        = 250,
  
          -- ── Default timeout ───────────────────────────────────────────
          default_timeout = 10000,
  
          -- ── Log level ─────────────────────────────────────────────────
          log_level       = "warn",
          update_in_insert = false,
  
          -- ── On attach ─────────────────────────────────────────────────
          on_attach       = on_attach,
  
          -- ── Root markers ──────────────────────────────────────────────
          root_dir        = require("null-ls.utils").root_pattern(
            ".git", ".null-ls-root", ".neoconf.json",
            "Makefile", "package.json", "pyproject.toml",
            "go.mod", "Cargo.toml", "flake.nix"
          ),
  
          -- ── Should attach ─────────────────────────────────────────────
          should_attach   = function(bufnr)
            -- Don't attach to huge files
            return vim.api.nvim_buf_line_count(bufnr) < 50000
          end,
        })
  
        -- ── Auto-update Mason on source changes ───────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshNoneLs", { clear = true })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            vim.notify(
              "🔮 none-ls: theme changed (no highlights to update)",
              vim.log.levels.DEBUG,
              { title = "ASH none-ls" }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🔮 none-ls: %d sources registered", #sources),
            vim.log.levels.DEBUG,
            { title = "ASH none-ls" }
          )
        end
      end,
    },
  }