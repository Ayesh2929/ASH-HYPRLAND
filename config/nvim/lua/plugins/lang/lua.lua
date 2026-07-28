-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌙 LUA — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                               ║
-- ║   lua_ls · stylua · lazydev · neodev · luacheck · ASH config aware            ║
-- ║   neovim API completion · plugin dev helpers · ASH theme-synced                ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — Lua-specific semantic colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Semantic token overrides ──────────────────────────────────────────────
    hl(0, "@lsp.type.class.lua",         { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.function.lua",      { fg = "#89b4fa"                })
    hl(0, "@lsp.type.method.lua",        { fg = "#89b4fa"                })
    hl(0, "@lsp.type.property.lua",      { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.variable.lua",      { fg = "#cdd6f4"                })
    hl(0, "@lsp.type.parameter.lua",     { italic = true, fg = "#c8c8c8" })
    hl(0, "@lsp.type.self.lua",          { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.keyword.lua",       { bold = true,   fg = "#cba6f7" })
    hl(0, "@lsp.type.namespace.lua",     { fg = "#94e2d5"                })
    hl(0, "@lsp.type.string.lua",        { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.lua",        { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.lua",       { bold = true,   fg = "#fab387" })
  
    -- ── Treesitter: Lua-specific ──────────────────────────────────────────────
    hl(0, "@constructor.lua",            { fg = "#89b4fa"                })
    hl(0, "@variable.member.lua",        { fg = "#cdd6f4"                })
    hl(0, "@string.escape.lua",          { bold = true,   fg = "#7dcfff" })
    hl(0, "@punctuation.special.lua",    { fg = "#cba6f7"                })
  
    -- ── Neovim-specific globals ────────────────────────────────────────────────
    hl(0, "LuaVimGlobal",                { bold = true,   fg = "#89b4fa" })
    hl(0, "LuaRequireCall",              { italic = true, fg = "#cba6f7" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.class.lua",    { bold = true, fg = p.yellow   }) end
      if p.blue   then hl(0, "@lsp.type.function.lua", { fg = p.blue                  }) end
      if p.mauve  then hl(0, "@lsp.type.keyword.lua",  { bold = true, fg = p.mauve    }) end
      if p.teal   then hl(0, "@lsp.type.namespace.lua",{ fg = p.teal                  }) end
      if p.green  then hl(0, "@lsp.type.string.lua",   { fg = p.green                 }) end
      if p.yellow then hl(0, "@lsp.type.self.lua",     { bold = true, fg = p.yellow   }) end
      if p.blue   then hl(0, "LuaVimGlobal",           { bold = true, fg = p.blue     }) end
      if p.mauve  then hl(0, "LuaRequireCall",         { italic = true, fg = p.mauve  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 LUA UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Get all Neovim plugin library paths for lua_ls
  local function get_nvim_library()
    local library = {
      vim.fn.expand("$VIMRUNTIME/lua"),
      vim.fn.stdpath("config") .. "/lua",
    }
  
    -- Add all lazy plugin paths
    local ok, lazy_config = pcall(require, "lazy.core.config")
    if ok and lazy_config.plugins then
      for _, plugin in pairs(lazy_config.plugins) do
        if plugin.dir and vim.fn.isdirectory(plugin.dir .. "/lua") == 1 then
          table.insert(library, plugin.dir)
        end
      end
    end
  
    return library
  end
  
  -- Evaluate current Lua buffer / selection
  local function eval_lua()
    local mode  = vim.fn.mode()
    local lines
  
    if mode == "v" or mode == "V" then
      -- Visual selection
      local s = vim.api.nvim_buf_get_mark(0, "<")
      local e = vim.api.nvim_buf_get_mark(0, ">")
      lines   = vim.api.nvim_buf_get_lines(0, s[1] - 1, e[1], false)
    else
      -- Current file
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    end
  
    local code = table.concat(lines, "\n")
    local fn, err = load(code, "=(eval)", "t")
  
    if not fn then
      vim.notify(
        "🌙 Lua eval error:\n" .. tostring(err),
        vim.log.levels.ERROR,
        { title = "Lua Eval" }
      )
      return
    end
  
    local ok_run, result = xpcall(fn, function(e2)
      return debug.traceback(e2, 2)
    end)
  
    if not ok_run then
      vim.notify(
        "🌙 Lua runtime error:\n" .. tostring(result),
        vim.log.levels.ERROR,
        { title = "Lua Eval" }
      )
    else
      local out = result ~= nil and vim.inspect(result) or "(nil)"
      vim.notify(
        "🌙 Result:\n" .. out,
        vim.log.levels.INFO,
        { title = "Lua Eval" }
      )
    end
  end
  
  -- Reload current Lua module
  local function reload_module()
    local buf  = vim.api.nvim_buf_get_name(0)
    local cfg  = vim.fn.stdpath("config")
  
    -- Find the module name relative to the config lua/ directory
    local rel  = buf:match(vim.pesc(cfg .. "/lua/") .. "(.+)%.lua$")
    if not rel then
      vim.notify(
        "🌙 Cannot determine module name (must be inside config/lua/)",
        vim.log.levels.WARN,
        { title = "Lua Reload" }
      )
      return
    end
  
    local mod_name = rel:gsub("/", ".")
  
    -- Clear from package.loaded
    package.loaded[mod_name] = nil
  
    -- Re-require with error handling
    local ok_req, err = pcall(require, mod_name)
    if ok_req then
      vim.notify(
        "🌙 Reloaded: " .. mod_name,
        vim.log.levels.INFO,
        { title = "Lua Reload", timeout = 1500 }
      )
    else
      vim.notify(
        "🌙 Reload error:\n" .. tostring(err),
        vim.log.levels.ERROR,
        { title = "Lua Reload" }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── lazydev.nvim — Neovim API annotations ─────────────────────────────────────
    {
      "folke/lazydev.nvim",
      ft   = "lua",
      opts = {
        library = {
          -- Load luvit types when the `vim.uv` word is found
          { path = "luvit-meta/library", words = { "vim%.uv" } },
          -- Load snacks.nvim types
          { path = "snacks.nvim",        words = { "Snacks" } },
          -- Load lazy.nvim itself
          { path = "lazy.nvim",          words = { "Lazy" } },
          -- Always load Neovim runtime
          { path = vim.env.VIMRUNTIME },
          -- Load current config
          { path = vim.fn.stdpath("config"), mods = { "lua" } },
        },
        enabled = function(root_dir)
          -- Enable for Neovim config and plugins
          return vim.g.lazydev_enabled ~= false
            and (root_dir:find(vim.fn.stdpath("config"), 1, true) ~= nil
              or root_dir:find(vim.fn.stdpath("data") .. "/lazy", 1, true) ~= nil)
        end,
        integrations = {
          lspconfig  = true,
          cmp        = true,
          coq        = false,
          neotest    = true,
        },
      },
    },
  
    -- ── luvit-meta — libuv type stubs ─────────────────────────────────────────────
    {
      "Bilal2453/luvit-meta",
      lazy = true,
    },
  
    -- ── nvim-lspconfig: lua_ls setup ──────────────────────────────────────────────
    {
      "neovim/nvim-lspconfig",
      ft   = "lua",
      opts = {
        servers = {
          lua_ls = {
            settings = {
              Lua = {
                runtime = {
                  version = "LuaJIT",
                  path    = vim.split(package.path, ";"),
                },
                workspace = {
                  checkThirdParty = false,
                  library         = get_nvim_library(),
                  maxPreload      = 100000,
                  preloadFileSize = 10000,
                },
                diagnostics = {
                  globals = {
                    "vim", "Snacks",
                    "describe", "it", "before_each", "after_each",
                    "assert", "require", "pcall", "xpcall", "rawget",
                  },
                  disable  = { "missing-fields", "incomplete-signature-doc" },
                  severity = {
                    undefined_global  = "Warning",
                    redefined_local   = "Hint",
                  },
                },
                completion = {
                  callSnippet    = "Replace",
                  keywordSnippet = "Replace",
                  workspaceWord  = true,
                  showWord       = "Fallback",
                  displayContext = 6,
                },
                hint = {
                  enable     = true,
                  arrayIndex = "Disable",
                  await      = true,
                  paramName  = "Disable",
                  paramType  = true,
                  semicolon  = "Disable",
                  setType    = false,
                },
                format = {
                  enable = false,   -- handled by stylua via conform.nvim
                },
                codeLens = {
                  enable = true,
                },
                doc = {
                  privateName = { "^_" },
                },
                telemetry  = { enable = false },
                type = {
                  castNumberToInteger = true,
                },
                window = {
                  progressBar = true,
                  statusBar   = false,
                },
              },
            },
          },
        },
      },
    },
  
    -- ── Lua filetype configuration & keymaps ──────────────────────────────────────
    {
      "nvim-lua/plenary.nvim",   -- use plenary as a hook target
      ft = "lua",
  
      keys = {
        -- Eval
        { "<leader>le",  eval_lua,       mode = { "n", "v" }, ft = "lua", desc = "🌙 Lua: Eval"          },
        { "<leader>lx",  "<cmd>source %<cr>",                 ft = "lua", desc = "🌙 Lua: Source file"   },
        { "<leader>lX",  reload_module,                       ft = "lua", desc = "🌙 Lua: Reload module"  },
        -- Plugin management
        { "<leader>ll",  "<cmd>Lazy<cr>",                     ft = "lua", desc = "🌙 Lua: Open Lazy"      },
        { "<leader>lL",  "<cmd>Lazy sync<cr>",                ft = "lua", desc = "🌙 Lua: Lazy sync"      },
        { "<leader>lu",  "<cmd>Lazy update<cr>",              ft = "lua", desc = "🌙 Lua: Lazy update"    },
        -- Inspect
        {
          "<leader>lI",
          function()
            local buf = vim.api.nvim_get_current_buf()
            local clients = vim.lsp.get_clients({ bufnr = buf })
            local client_names = vim.tbl_map(function(c) return c.name end, clients)
            vim.notify(
              table.concat({
                "🌙 Lua Environment",
                "──────────────────────────────────",
                string.format("  LuaJIT:  %s", jit and jit.version or "unknown"),
                string.format("  LSP:     %s", table.concat(client_names, ", ")),
                string.format("  Config:  %s", vim.fn.stdpath("config")),
                string.format("  Data:    %s", vim.fn.stdpath("data")),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Lua Info" }
            )
          end,
          ft   = "lua",
          desc = "🌙 Lua: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshLua", { clear = true })
  
        -- Filetype options
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "lua",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 2
            vim.opt_local.tabstop     = 2
            vim.opt_local.softtabstop = 2
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
            vim.opt_local.foldmethod  = "expr"
            vim.opt_local.foldexpr    = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel   = 99
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🌙 Lua highlights synced", vim.log.levels.INFO,
              { title = "ASH Lua", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🌙 Lua loaded — LuaJIT %s", jit and jit.version or "unknown"),
            vim.log.levels.DEBUG,
            { title = "ASH Lua" }
          )
        end
      end,
    },
  }