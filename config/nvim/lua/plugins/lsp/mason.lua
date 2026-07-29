-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📦 MASON — ULTRA PACKAGE MANAGER v5.0 OMEGA                              ║
-- ║   100+ tools · LSP servers · formatters · linters · DAP adapters               ║
-- ║   auto-install · auto-update · ASH theme-synced UI · smart categorisation      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — ASH palette-aware Mason UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "MasonNormal",              { link = "NormalFloat"   })
    hl(0, "MasonHeader",              { bold = true, reverse = true })
    hl(0, "MasonHeaderSecondary",     { bold = true, reverse = true })
    hl(0, "MasonHighlight",           { bold = true, fg = "#7aa2f7" })
    hl(0, "MasonHighlightBlock",      { bold = true, fg = "#1a1b26", bg = "#7aa2f7" })
    hl(0, "MasonHighlightBlockBold",  { bold = true, fg = "#1a1b26", bg = "#7aa2f7" })
    hl(0, "MasonHighlightSecondary",  { bold = true, fg = "#9ece6a" })
    hl(0, "MasonHighlightBlockSecondary", { fg = "#1a1b26", bg = "#9ece6a" })
    hl(0, "MasonHighlightBlockBoldSecondary", { bold = true, fg = "#1a1b26", bg = "#9ece6a" })
  
    -- ── Status badges ─────────────────────────────────────────────────────────
    hl(0, "MasonPackageInstalled",    { bold = true, fg = "#9ece6a" })
    hl(0, "MasonPackageUninstalled",  { fg = "#f38ba8"              })
    hl(0, "MasonPackagePending",      { fg = "#f9e2af"              })
  
    -- ── Muted / UI elements ───────────────────────────────────────────────────
    hl(0, "MasonMuted",               { fg = "#9399b2"              })
    hl(0, "MasonMutedBlock",          { fg = "#1a1b26", bg = "#9399b2" })
    hl(0, "MasonMutedBlockBold",      { bold = true, fg = "#1a1b26", bg = "#9399b2" })
    hl(0, "MasonError",               { bold = true, fg = "#f38ba8" })
    hl(0, "MasonWarning",             { bold = true, fg = "#f9e2af" })
    hl(0, "MasonLink",                { underline = true, fg = "#89b4fa" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue  then
        hl(0, "MasonHighlight",      { bold = true, fg = p.blue })
        hl(0, "MasonHighlightBlock", { bold = true, fg = p.base or "#1a1b26", bg = p.blue })
        hl(0, "MasonHighlightBlockBold", { bold = true, fg = p.base or "#1a1b26", bg = p.blue })
        hl(0, "MasonLink",           { underline = true, fg = p.blue })
      end
      if p.green then
        hl(0, "MasonPackageInstalled",{ bold = true, fg = p.green })
        hl(0, "MasonHighlightSecondary", { bold = true, fg = p.green })
        hl(0, "MasonHighlightBlockSecondary", { fg = p.base or "#1a1b26", bg = p.green })
      end
      if p.red   then hl(0, "MasonPackageUninstalled", { fg = p.red    }) end
      if p.yellow then hl(0, "MasonPackagePending",    { fg = p.yellow }) end
      if p.overlay1 then hl(0, "MasonMuted",           { fg = p.overlay1}) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 PACKAGE REGISTRY — all tools Mason should ensure are installed
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- These are installed via mason-tool-installer / mason-lspconfig
  -- The list is intentionally comprehensive — tools not needed will stay uninstalled
  _G.AshMasonEnsureInstalled = {
  
    -- ── 🔧 Language Servers ────────────────────────────────────────────────────
    -- Systems
    "rust-analyzer",
    "clangd",
    "zls",
    "gleam",
  
    -- Scripting
    "pyright",
    "ruff-lsp",
    "lua-language-server",
    "bash-language-server",
  
    -- JVM
    "jdtls",
    "kotlin-language-server",
  
    -- Web
    "typescript-language-server",
    "css-lsp",
    "html-lsp",
    "tailwindcss-language-server",
    "graphql-language-service-cli",
    "emmet-language-server",
    "eslint-lsp",
    "volar",
    "astro-language-server",
    "svelte-language-server",
    "prismals",
  
    -- Go
    "gopls",
  
    -- Functional
    "haskell-language-server",
    "ocamllsp",
    "elixir-ls",
  
    -- Config
    "json-lsp",
    "yaml-language-server",
    "taplo",
    "dockerfile-language-server",
    "docker-compose-language-service",
    "terraform-ls",
    "nil",
    "marksman",
    "texlab",
    "sqls",
    "hyprls",
  
    -- Other
    "intelephense",
    "omnisharp",
    "r-languageserver",
    "glsl-analyzer",
    "pbls",
    "denols",
    "mdx-analyzer",
    "solidity-ls-nomicfoundation",
  
    -- ── 🎨 Formatters ──────────────────────────────────────────────────────────
    -- Multi-language
    "prettier",
    "prettierd",
    "biome",
  
    -- Lua
    "stylua",
  
    -- Python
    "black",
    "isort",
    "ruff",
    "autopep8",
  
    -- Go
    "gofumpt",
    "goimports",
    "goimports-reviser",
    "golines",
  
    -- Rust (via rustup, not mason)
    -- "rustfmt",
  
    -- Shell
    "shfmt",
    "beautysh",
  
    -- Fish
    "fish-indent",   -- via fisher, not mason
  
    -- C/C++
    "clang-format",
  
    -- Java
    "google-java-format",
  
    -- Web
    "css-beautify",
    "htmlbeautifier",
  
    -- SQL
    "sql-formatter",
    "sqlfmt",
    "sqlfluff",
  
    -- YAML
    "yamlfmt",
  
    -- Markdown
    "mdformat",
    "markdownlint",
    "cbfmt",
  
    -- Nix
    "nixfmt",
    "alejandra",
  
    -- Kotlin
    "ktfmt",
  
    -- OCaml
    "ocamlformat",
  
    -- Haskell
    "fourmolu",
    "ormolu",
  
    -- Protobuf
    "buf",
  
    -- LaTeX
    "latexindent",
  
    -- Terraform
    "terraform",
  
    -- ── 🔬 Linters ───────────────────────────────────────────────────────────
    -- Shell
    "shellcheck",
    "shellharden",
  
    -- Python
    "pylint",
    "flake8",
    "mypy",
    "bandit",
  
    -- JavaScript / TypeScript
    "eslint_d",
    "biomejs",
  
    -- Lua
    "luacheck",
  
    -- Go
    "golangci-lint",
    "revive",
    "staticcheck",
  
    -- Markdown
    "markdownlint-cli2",
    "vale",
  
    -- YAML
    "yamllint",
  
    -- JSON
    "jsonlint",
  
    -- Dockerfile
    "hadolint",
  
    -- Ansible
    "ansible-lint",
  
    -- Terraform
    "tflint",
    "checkov",
  
    -- HTML
    "htmlhint",
  
    -- CSS
    "stylelint",
  
    -- C/C++
    "cpplint",
  
    -- Security
    "trivy",
    "gitleaks",
  
    -- General
    "editorconfig-checker",
    "proselint",
  
    -- ── 🐛 DAP Adapters ───────────────────────────────────────────────────────
    -- Python
    "debugpy",
  
    -- Go
    "delve",
  
    -- C/C++/Rust
    "codelldb",
    "cpptools",
  
    -- Node / JS
    "js-debug-adapter",
    "node-debug2-adapter",
  
    -- Bash
    "bash-debug-adapter",
  
    -- Java
    "java-debug-adapter",
    "java-test",
  
    -- PHP
    "php-debug-adapter",
  
    -- Haskell
    "haskell-debug-adapter",
  
    -- .NET
    "netcoredbg",
  
    -- Kotlin
    "kotlin-debug-adapter",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART AUTO-INSTALL — install on demand without blocking startup
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function ensure_installed()
    local registry = require("mason-registry")
  
    -- Refresh registry before installing
    registry.refresh(function()
      local to_install = {}
      for _, pkg_name in ipairs(_G.AshMasonEnsureInstalled or {}) do
        local ok, pkg = pcall(registry.get_package, pkg_name)
        if ok and not pkg:is_installed() then
          table.insert(to_install, pkg_name)
        end
      end
  
      if #to_install == 0 then return end
  
      vim.notify(
        string.format("📦 Mason: Installing %d package(s)…", #to_install),
        vim.log.levels.INFO,
        { title = "Mason" }
      )
  
      for _, pkg_name in ipairs(to_install) do
        local ok2, pkg = pcall(registry.get_package, pkg_name)
        if ok2 then
          pkg:install():once("closed", function()
            if pkg:is_installed() then
              vim.schedule(function()
                vim.notify(
                  string.format("📦 ✅ Installed: %s", pkg_name),
                  vim.log.levels.INFO,
                  { title = "Mason", timeout = 2000 }
                )
              end)
            end
          end)
        end
      end
    end)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "williamboman/mason.nvim",
      cmd          = {
        "Mason",
        "MasonInstall",
        "MasonUninstall",
        "MasonUninstallAll",
        "MasonLog",
        "MasonUpdate",
      },
      build        = ":MasonUpdate",
      event        = { "BufReadPre", "BufNewFile" },
  
      keys = {
        {
          "<leader>pm",
          "<cmd>Mason<cr>",
          desc   = "📦 Mason: Package Manager",
          silent = true,
        },
        {
          "<leader>pM",
          function() ensure_installed() end,
          desc   = "📦 Mason: Ensure All Installed",
          silent = true,
        },
        {
          "<leader>pu",
          "<cmd>MasonUpdate<cr>",
          desc   = "📦 Mason: Update All",
          silent = true,
        },
        {
          "<leader>pl",
          "<cmd>MasonLog<cr>",
          desc   = "📦 Mason: Log",
          silent = true,
        },
      },
  
      opts = {
        -- ── UI configuration ─────────────────────────────────────────────────
        ui = {
          -- Window size
          width        = 0.88,
          height       = 0.80,
  
          -- Border style
          border       = "rounded",
  
          -- Keymaps inside Mason UI
          keymaps      = {
            toggle_package_expand   = "<CR>",
            install_package         = "i",
            update_package          = "u",
            check_package_version   = "c",
            update_all_packages     = "U",
            check_outdated_packages = "C",
            uninstall_package       = "X",
            cancel_installation     = "<C-c>",
            apply_language_filter   = "<C-f>",
            toggle_help             = "g?",
            toggle_preview          = "P",
          },
  
          -- Icons
          icons = {
            package_installed   = "✅",
            package_pending     = "⏳",
            package_uninstalled = "○",
          },
        },
  
        -- ── Installation paths ────────────────────────────────────────────────
        install_root_dir = vim.fn.stdpath("data") .. "/mason",
  
        -- ── Pip install args ──────────────────────────────────────────────────
        pip = {
          upgrade_pip    = false,
          install_args   = {},
        },
  
        -- ── Log level ─────────────────────────────────────────────────────────
        log_level      = vim.log.levels.INFO,
  
        -- ── Max concurrent jobs ───────────────────────────────────────────────
        max_concurrent_installers = 4,
  
        -- ── GitHub provider (for downloading from GitHub releases) ────────────
        github = {
          download_url_template = "https://github.com/%s/releases/download/%s/%s",
        },
  
        -- ── Registries ────────────────────────────────────────────────────────
        registries = {
          "github:mason-org/mason-registry",
        },
  
        -- ── Provider priority ─────────────────────────────────────────────────
        providers = {
          "mason.providers.registry-api",
          "mason.providers.client",
        },
      },
  
      config = function(_, opts)
        require("mason").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshMason", { clear = true })
  
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
              "📦 Mason highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Mason", timeout = 1200 }
            )
          end,
        })
  
        -- ── Auto-install on startup (deferred to not block) ───────────────────
        vim.defer_fn(ensure_installed, 2000)
  
        -- ── Status line component ─────────────────────────────────────────────
        _G.AshMasonStatus = function()
          local registry = require("mason-registry")
          local installed = #registry.get_installed_packages()
          return string.format("📦 %d", installed)
        end
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "📦 Mason loaded — %d packages registered",
              #(_G.AshMasonEnsureInstalled or {})
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Mason" }
          )
        end
      end,
    },
  }