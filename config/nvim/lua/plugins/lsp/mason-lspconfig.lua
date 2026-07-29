-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║    🔗 MASON-LSPCONFIG — ULTRA LSP BRIDGE v5.0 OMEGA                            ║
-- ║   Auto-installs LSP servers · bridges Mason ↔ lspconfig                        ║
-- ║   smart handler dispatch · per-server custom setup · zero-config defaults      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  SERVER NAME MAP — Mason package name → lspconfig server name
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Servers to ensure Mason installs (LSP subset only)
local LSP_SERVERS_ENSURE = {
    -- Systems
    "rust_analyzer",
    "clangd",
    "zls",
    "gleam",
  
    -- Scripting
    "pyright",
    "ruff_lsp",
    "lua_ls",
    "bashls",
  
    -- Web
    "ts_ls",
    "cssls",
    "html",
    "tailwindcss",
    "graphql",
    "emmet_language_server",
    "eslint",
    "volar",
    "astro",
    "svelte",
    "prismals",
  
    -- Go
    "gopls",
  
    -- JVM
    "kotlin_language_server",
  
    -- Functional
    "hls",
    "ocamllsp",
    "elixirls",
  
    -- Config
    "jsonls",
    "yamlls",
    "taplo",
    "dockerls",
    "docker_compose_language_service",
    "terraformls",
    "nil_ls",
    "marksman",
    "texlab",
    "sqls",
  
    -- Other
    "intelephense",
    "omnisharp",
    "r_language_server",
    "glsl_analyzer",
    "denols",
    "mdx_analyzer",
    "hyprls",
  }
  
  -- Servers that mason-lspconfig should NOT auto-setup
  -- (they have bespoke setup via dedicated plugins)
  local MANUAL_SETUP_SERVERS = {
    "jdtls",   -- nvim-jdtls
    "metals",  -- nvim-metals
    "rust_analyzer", -- rustaceanvim (optional)
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 HANDLER FACTORY — creates per-server setup handlers
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function make_handlers()
    local lspconfig    = require("lspconfig")
    local capabilities = _G.AshLspCapabilities  or require("cmp_nvim_lsp").default_capabilities()
    local on_attach    = _G.AshLspOnAttach      or function(_, _) end
    local server_cfgs  = _G.AshLspServers       or {}
  
    local handlers = {}
  
    -- ── Default handler ────────────────────────────────────────────────────────
    -- Called for any server without a dedicated handler
    handlers[1] = function(server_name)
      -- Skip servers that are manually set up
      if vim.tbl_contains(MANUAL_SETUP_SERVERS, server_name) then
        return
      end
  
      local cfg = server_cfgs[server_name] or {}
  
      -- Skip servers explicitly disabled in ASH config
      if cfg.mason == false then return end
  
      -- Build merged config
      local server_config = vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach    = cfg.on_attach or on_attach,
      }, cfg)
  
      -- Remove meta-keys that lspconfig doesn't understand
      server_config.mason = nil
  
      lspconfig[server_name].setup(server_config)
  
      if vim.g.ash_debug then
        vim.notify(
          string.format("🔗 mason-lspconfig: setup %s", server_name),
          vim.log.levels.DEBUG,
          { title = "mason-lspconfig" }
        )
      end
    end
  
    -- ── Per-server handlers ────────────────────────────────────────────────────
  
    -- rust_analyzer: optionally delegate to rustaceanvim
    handlers["rust_analyzer"] = function()
      local ok_rust, rustacean = pcall(require, "rustaceanvim")
      if ok_rust then
        -- rustaceanvim handles rust_analyzer setup itself
        return
      end
      -- Fallback: standard lspconfig setup
      local cfg = server_cfgs["rust_analyzer"] or {}
      lspconfig.rust_analyzer.setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach    = cfg.on_attach or on_attach,
      }, cfg))
    end
  
    -- lua_ls: ensure neovim runtime library is included
    handlers["lua_ls"] = function()
      local cfg = server_cfgs["lua_ls"] or {}
      -- Guarantee neovim library is always present
      local settings = vim.tbl_deep_extend("force", {
        Lua = {
          workspace = {
            library = {
              vim.fn.expand("$VIMRUNTIME/lua"),
              vim.fn.stdpath("config") .. "/lua",
            },
          },
        },
      }, cfg.settings or {})
      lspconfig.lua_ls.setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach    = cfg.on_attach or on_attach,
        settings     = settings,
      }, cfg))
    end
  
    -- ts_ls: skip if Deno project (denols takes priority)
    handlers["ts_ls"] = function()
      local cfg = server_cfgs["ts_ls"] or {}
      lspconfig.ts_ls.setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach    = cfg.on_attach or on_attach,
        -- Don't attach if a Deno config is present
        root_dir     = function(fname)
          local deno_cfg = lspconfig.util.root_pattern("deno.json", "deno.jsonc")(fname)
          if deno_cfg then return nil end
          return lspconfig.util.root_pattern(
            "tsconfig.json", "package.json", "jsconfig.json", ".git"
          )(fname)
        end,
      }, cfg))
    end
  
    -- denols: only attach in Deno projects
    handlers["denols"] = function()
      local cfg = server_cfgs["denols"] or {}
      lspconfig.denols.setup(vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach    = cfg.on_attach or on_attach,
        root_dir     = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
      }, cfg))
    end
  
    -- clangd: special offset encoding fix
    handlers["clangd"] = function()
      local cfg = server_cfgs["clangd"] or {}
      local clangd_caps = vim.tbl_deep_extend("force", capabilities, {
        offsetEncoding = { "utf-16" },
      })
      lspconfig.clangd.setup(vim.tbl_deep_extend("force", {
        capabilities = clangd_caps,
        on_attach    = cfg.on_attach or on_attach,
      }, cfg))
    end
  
    -- jdtls: skip — managed by nvim-jdtls
    handlers["jdtls"] = function() end
  
    -- metals: skip — managed by nvim-metals
    handlers["metals"] = function() end
  
    return handlers
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "williamboman/mason-lspconfig.nvim",
      event        = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "williamboman/mason.nvim",
        "neovim/nvim-lspconfig",
      },
  
      opts = {
        -- ── Servers to auto-install ───────────────────────────────────────────
        ensure_installed = LSP_SERVERS_ENSURE,
  
        -- ── Auto-install: install when first opened ───────────────────────────
        automatic_installation = {
          exclude = MANUAL_SETUP_SERVERS,
        },
      },
  
      config = function(_, opts)
        local mason_lspconfig = require("mason-lspconfig")
  
        mason_lspconfig.setup(opts)
  
        -- ── Register handlers ─────────────────────────────────────────────────
        -- Handlers are built lazily so _G.AshLsp* globals from lspconfig.lua
        -- are already populated by the time setup_handlers runs
        vim.defer_fn(function()
          mason_lspconfig.setup_handlers(make_handlers())
        end, 0)
  
        -- ── Status summary ────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshMasonLspconfig", { clear = true })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- No highlights owned by this module; just log
            if vim.g.ash_debug then
              vim.notify(
                "🔗 mason-lspconfig: theme changed, handlers intact",
                vim.log.levels.DEBUG,
                { title = "mason-lspconfig" }
              )
            end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "🔗 mason-lspconfig: %d servers registered",
              #LSP_SERVERS_ENSURE
            ),
            vim.log.levels.DEBUG,
            { title = "ASH mason-lspconfig" }
          )
        end
      end,
    },
  }