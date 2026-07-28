-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  ░█████╗░░██████╗██╗░░██╗  ███╗░░██╗███████╗░█████╗░██╗░░░██╗██╗███╗░░░███╗ ║
-- ║  ██╔══██╗██╔════╝██║░░██║  ████╗░██║██╔════╝██╔══██╗██║░░░██║██║████╗░████║ ║
-- ║  ███████║╚█████╗░███████║  ██╔██╗██║█████╗░░██║░░██║╚██╗░██╔╝██║██╔████╔██║ ║
-- ║  ██╔══██║░╚═══██╗██╔══██║  ██║╚████║██╔══╝░░██║░░██║░╚████╔╝░██║██║╚██╔╝██║ ║
-- ║  ██║░░██║██████╔╝██║░░██║  ██║░╚███║███████╗╚█████╔╝░░╚██╔╝░░██║██║░╚═╝░██║ ║
-- ║  ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝  ╚═╝░░╚══╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝╚═╝░░░░╚═╝ ║
-- ╠══════════════════════════════════════════════════════════════════════════════╣
-- ║  🚀 ASH DOTFILES v5.0 OMEGA • NEOVIM ULTRA IDE CONFIGURATION               ║
-- ║  ⚡ Lazy.nvim • LSP • DAP • Treesitter • AI • Full IDE Experience           ║
-- ║  🎨 Dynamic Theming • 65+ Plugins • Zero Compromise Performance             ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 0 ─ STRICT MODE & EARLY ABORT GUARDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if vim.fn.has("nvim-0.10") == 0 then
    vim.notify(
      "⚠️  ASH NeoVim requires Neovim >= 0.10.0\n"
        .. "   Current: "
        .. vim.version().major
        .. "."
        .. vim.version().minor
        .. "."
        .. vim.version().patch
        .. "\n   Please upgrade: https://neovim.io",
      vim.log.levels.ERROR,
      { title = "ASH NeoVim — Version Error" }
    )
    return
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 1 ─ PERFORMANCE OPTIMIZATION: DISABLE BUILT-IN PROVIDERS EARLY
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Disable unused built-in plugins to shave ~8ms from startup
  local disabled_builtins = {
    "2html_plugin",
    "bugreport",
    "compiler",
    "ftplugin",
    "getscript",
    "getscriptPlugin",
    "gzip",
    "logipat",
    "matchit",
    "netrw",
    "netrwFileHandlers",
    "netrwPlugin",
    "netrwSettings",
    "optwin",
    "rplugin",
    "rrhelper",
    "spellfile_plugin",
    "synmenu",
    "tar",
    "tarPlugin",
    "tohtml",
    "tutor",
    "vimball",
    "vimballPlugin",
    "zip",
    "zipPlugin",
  }
  
  for _, plugin in ipairs(disabled_builtins) do
    vim.g["loaded_" .. plugin] = 1
  end
  
  -- Disable providers we don't need (significant startup time savings)
  vim.g.loaded_python3_provider = 0
  vim.g.loaded_ruby_provider = 0
  vim.g.loaded_perl_provider = 0
  vim.g.loaded_node_provider = 0
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 2 ─ GLOBAL NAMESPACE BOOTSTRAP
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Expose a global `Ash` namespace accessible from every module
  ---@class AshConfig
  ---@field version       string   Dotfiles version tag
  ---@field theme         string   Active ASH theme name
  ---@field colorscheme   string   Active Neovim colorscheme
  ---@field transparent   boolean  Enable transparent backgrounds
  ---@field icons         table    Nerd Font icon registry
  ---@field lsp           table    LSP behaviour overrides
  ---@field ai            table    AI completion settings
  ---@field perf          table    Performance tuning knobs
  ---@field flags         table    Feature flags
  Ash = {
    version = "5.0.0-omega",
    theme = vim.env.ASH_THEME or "catppuccin-mocha",
    colorscheme = vim.env.ASH_NVIM_COLORSCHEME or "catppuccin",
  
    -- Transparency: respects the compositor
    transparent = vim.env.ASH_TRANSPARENT == "1" or false,
  
    -- ── Icon registry ────────────────────────────────────────────────────────
    icons = {
      -- Diagnostics
      diagnostics = {
        Error = "󰅚 ",
        Warn  = "󰀪 ",
        Hint  = "󰌶 ",
        Info  = " ",
      },
      -- Git
      git = {
        added    = " ",
        changed  = " ",
        removed  = " ",
        renamed  = "󰁕 ",
        unmerged = " ",
        ignored  = "󰄮 ",
      },
      -- Kinds (LSP completion / outline)
      kinds = {
        Array         = "󰅪 ",
        Boolean       = "󰨙 ",
        Class         = "󰆧 ",
        Color         = "󰏘 ",
        Constant      = "󰏿 ",
        Constructor   = " ",
        Copilot       = " ",
        Enum          = " ",
        EnumMember    = " ",
        Event         = " ",
        Field         = "󰜢 ",
        File          = "󰈙 ",
        Folder        = "󰉋 ",
        Function      = "󰊕 ",
        Interface     = " ",
        Key           = "󰌋 ",
        Keyword       = "󰌋 ",
        Method        = "󰆧 ",
        Module        = "󰏗 ",
        Namespace     = "󰌗 ",
        Null          = "󰟢 ",
        Number        = "󰎠 ",
        Object        = "󰅩 ",
        Operator      = "󰆕 ",
        Package       = "󰏗 ",
        Property      = "󰜢 ",
        Reference     = "󰈇 ",
        Snippet       = " ",
        String        = "󰉾 ",
        Struct        = "󱡠 ",
        Text          = "󰉿 ",
        TypeParameter = "󰊄 ",
        Unit          = "󰑭 ",
        Value         = "󰎠 ",
        Variable      = "󰀫 ",
      },
      -- UI chrome
      ui = {
        ArrowLeft       = " ",
        ArrowRight      = " ",
        BoldArrowDown   = "",
        BoldArrowLeft   = "",
        BoldArrowRight  = "",
        BoldArrowUp     = "",
        BookMark        = "󰃃",
        Bug             = "󰃤 ",
        Calendar        = " ",
        Check           = "󰄳 ",
        ChevronRight    = " ",
        Circle          = " ",
        Close           = "󰅖 ",
        CloudDownload   = " ",
        Code            = " ",
        Comment         = " ",
        Dashboard       = " ",
        Ellipsis        = "󰇘",
        EmptyFolder     = " ",
        EmptyFolderOpen = " ",
        File            = " ",
        FileSymlink     = " ",
        Files           = " ",
        FindFile        = "󰈞 ",
        FindText        = "󰊄 ",
        Fire            = " ",
        Folder          = "󰉋 ",
        FolderOpen      = " ",
        FolderSymlink   = " ",
        Forward         = " ",
        Gear            = " ",
        History         = " ",
        Lightbulb       = "󰌵 ",
        Line            = "󰕶",
        List            = " ",
        Lock            = "󰌾 ",
        NewFile         = " ",
        Note            = "󰎞 ",
        Package         = " ",
        Pencil          = "󰏫 ",
        Plus            = " ",
        Project         = " ",
        Search          = " ",
        SignIn          = " ",
        SignOut         = " ",
        Stacks          = " ",
        Tab             = "󰌒 ",
        Table           = " ",
        Target          = "󰀘 ",
        Terminal        = " ",
        Telescope       = " ",
        Tree            = " ",
        Watch           = "󰥔 ",
      },
      -- Status line separators
      separators = {
        powerline = { left = "", right = "" },
        round     = { left = "", right = "" },
        block     = { left = "█", right = "█" },
        arrow     = { left = "", right = "" },
        slant     = { left = "", right = "" },
      },
    },
  
    -- ── LSP behaviour ────────────────────────────────────────────────────────
    lsp = {
      -- Servers that Mason should auto-install
      servers = {
        -- Web
        "ts_ls", "eslint", "cssls", "html", "jsonls", "tailwindcss",
        "graphql", "prismals",
        -- Systems
        "rust_analyzer", "clangd", "zls",
        -- Scripting
        "pyright", "ruff", "bashls",
        -- Go
        "gopls",
        -- Lua
        "lua_ls",
        -- Data
        "yamlls", "taplo", "dockerls",
        -- Nix
        "nil_ls",
        -- Hyprland
        "hyprls",
      },
      -- Diagnostic virtual text style
      virtual_text = true,
      -- Inlay hints (Neovim ≥ 0.10)
      inlay_hints = true,
      -- Code lens
      codelens = true,
      -- Format on save
      format_on_save = true,
    },
  
    -- ── AI settings ──────────────────────────────────────────────────────────
    ai = {
      -- "codeium" | "copilot" | "supermaven" | "none"
      provider = vim.env.ASH_AI_PROVIDER or "codeium",
      -- Local Ollama model for chat (avante / codecompanion)
      ollama_model = vim.env.ASH_OLLAMA_MODEL or "llama3.1:8b",
      -- Show ghost text inline suggestions
      ghost_text = true,
    },
  
    -- ── Performance knobs ────────────────────────────────────────────────────
    perf = {
      -- Max file size for full feature set (bytes)
      max_file_size = 1024 * 1024, -- 1 MB
      -- Max line length before disabling some features
      max_line_length = 10000,
      -- Treesitter: disable for very large files
      ts_max_file_size = 512 * 1024,
      -- Disable UI candy for files above this size
      bigfile_size = 256 * 1024,
    },
  
    -- ── Feature flags ────────────────────────────────────────────────────────
    flags = {
      enable_dap        = true,
      enable_ai         = true,
      enable_git        = true,
      enable_testing    = true,
      enable_database   = true,
      enable_rest_client = true,
      enable_obsidian   = false, -- opt-in: needs vault path
      enable_leetcode   = false, -- opt-in: needs account
      enable_wakatime   = vim.fn.filereadable(vim.env.HOME .. "/.wakatime.cfg") == 1,
      enable_animations = true,
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 3 ─ RUNTIME PATH BOOTSTRAP (before anything else touches rtp)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local config_path = vim.fn.stdpath("config") --[[@as string]]
  local data_path   = vim.fn.stdpath("data")   --[[@as string]]
  local cache_path  = vim.fn.stdpath("cache")  --[[@as string]]
  
  -- Expose resolved paths in global namespace
  Ash.paths = {
    config = config_path,
    data   = data_path,
    cache  = cache_path,
    lazy   = data_path .. "/lazy/lazy.nvim",
    mason  = data_path .. "/mason",
    themes = config_path .. "/lua/themes",
    snips  = config_path .. "/lua/plugins/completion/snippets",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 4 ─ LAZY.NVIM BOOTSTRAP
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local lazy_path = Ash.paths.lazy
  
  if not vim.uv.fs_stat(lazy_path) then
    vim.notify("⚙️  Bootstrapping lazy.nvim…", vim.log.levels.INFO, {
      title = "ASH NeoVim",
    })
  
    local ok, err = pcall(vim.fn.system, {
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable",
      "https://github.com/folke/lazy.nvim.git",
      lazy_path,
    })
  
    if not ok or vim.v.shell_error ~= 0 then
      vim.notify(
        "❌ Failed to clone lazy.nvim:\n" .. (err or "unknown error"),
        vim.log.levels.ERROR,
        { title = "ASH NeoVim — Bootstrap Error" }
      )
      return
    end
  end
  
  vim.opt.rtp:prepend(lazy_path)
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 5 ─ LOAD CORE MODULES (order-sensitive)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- We load core modules BEFORE lazy so options are set before plugin init
  local core_modules = {
    "core.options",   -- vim.opt.* settings
    "core.icons",     -- icon helpers (already bootstrapped above, validate here)
    "core.autocmds",  -- autocommands
    "core.keymaps",   -- base keymaps (plugin keymaps live in plugin specs)
    "core.filetype",  -- custom filetype detection
    "core.utils",     -- utility helpers exposed as Ash.util.*
    "core.health",    -- :checkhealth ash
  }
  
  for _, mod in ipairs(core_modules) do
    local ok, err = pcall(require, mod)
    if not ok then
      vim.notify(
        string.format("❌ Failed to load core module [%s]:\n%s", mod, err),
        vim.log.levels.ERROR,
        { title = "ASH NeoVim — Core Error" }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 6 ─ LAZY.NVIM PLUGIN LOADER
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  require("lazy").setup({
    -- ── Plugin spec imports ─────────────────────────────────────────────────
    -- Each file returns a lazy plugin spec table (or array of specs)
    { import = "plugins.ui" },
    { import = "plugins.editor" },
    { import = "plugins.lsp" },
    { import = "plugins.completion" },
    { import = "plugins.dap" },
    { import = "plugins.lang" },
    { import = "plugins.tools" },
    { import = "plugins.ai" },
    { import = "themes" },
  }, {
    -- ── Lazy.nvim configuration ─────────────────────────────────────────────
    root    = data_path .. "/lazy",
    lockfile = config_path .. "/lazy-lock.json",
  
    defaults = {
      -- All plugins lazy-load by default; explicit `lazy = false` to eagerly load
      lazy    = true,
      -- Pin to latest stable when no version is specified
      version = false,
    },
  
    -- Auto-install missing plugins on startup
    install = {
      missing    = true,
      colorscheme = { Ash.colorscheme, "habamax" },
    },
  
    -- ── Checker ─────────────────────────────────────────────────────────────
    checker = {
      enabled   = true,
      notify    = true,
      frequency = 86400, -- once per day (seconds)
    },
  
    -- ── Change detection ────────────────────────────────────────────────────
    change_detection = {
      enabled = true,
      notify  = false, -- silence the noisy notification
    },
  
    -- ── Performance ─────────────────────────────────────────────────────────
    performance = {
      cache = { enabled = true },
      reset_packpath = true,
      rtp = {
        reset = true,
        -- These runtime paths are always needed
        paths = {},
        -- Disable these default rtp entries
        disabled_plugins = {
          "gzip", "matchit", "matchparen", "netrwPlugin",
          "tarPlugin", "tohtml", "tutor", "zipPlugin",
        },
      },
    },
  
    -- ── UI ──────────────────────────────────────────────────────────────────
    ui = {
      size        = { width = 0.88, height = 0.82 },
      wrap        = false,
      border      = "rounded",
      backdrop    = 60,
      title       = " 󰒲 ASH NeoVim — Plugin Manager ",
      title_pos   = "center",
      pills       = true,
      icons = {
        cmd        = Ash.icons.ui.Code,
        config     = Ash.icons.ui.Gear,
        event      = Ash.icons.ui.Watch,
        ft         = Ash.icons.ui.File,
        init       = Ash.icons.ui.Fire,
        import     = Ash.icons.ui.Package,
        keys       = Ash.icons.ui.Tab,
        lazy       = "󰒲 ",
        loaded     = "● ",
        not_loaded = "○ ",
        plugin     = Ash.icons.ui.Package,
        runtime    = Ash.icons.ui.Stacks,
        require    = Ash.icons.ui.Package,
        source     = Ash.icons.ui.Code,
        start      = Ash.icons.ui.Fire,
        task       = Ash.icons.ui.Check,
        list = {
          "●",
          "➜",
          "★",
          "‒",
        },
      },
      -- Custom header rendered in the lazy UI
      custom_keys = {
        -- Open plugin repo in browser
        ["<localleader>g"] = {
          function(plugin)
            vim.fn.jobstart({ "xdg-open", plugin.url })
          end,
          desc = "Open GitHub repo",
        },
      },
    },
  
    -- ── Debug (disable in production) ───────────────────────────────────────
    debug = false,
  })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 7 ─ POST-LOAD: ASH THEME SYNC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Defer theme application until after the UI is fully rendered to avoid
  -- flickering on startup.
  vim.defer_fn(function()
    local ok, theme = pcall(require, "themes")
    if ok and theme and theme.apply then
      theme.apply(Ash.colorscheme)
    else
      -- Fallback: apply colorscheme directly
      pcall(vim.cmd.colorscheme, Ash.colorscheme)
    end
  end, 0)
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 8 ─ POST-LOAD: ASH ENVIRONMENT WATCHER (live theme sync with Hyprland)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Watch for ASH_THEME changes via a unix socket / env-file and
  -- hot-reload the colorscheme without restarting Neovim.
  vim.defer_fn(function()
    local ok, watcher = pcall(require, "after.plugin.ash-theme-watcher")
    if ok and watcher and watcher.start then
      watcher.start()
    end
  end, 100)
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 9 ─ STARTUP PROFILING (dev only)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  if vim.env.ASH_NVIM_PROFILE == "1" then
    vim.defer_fn(function()
      -- Print startup time after everything has settled
      local stats   = require("lazy").stats()
      local startup = math.floor(stats.startuptime * 10 + 0.5) / 10
  
      vim.notify(
        string.format(
          "⚡ Loaded %d/%d plugins in %sms",
          stats.loaded,
          stats.count,
          startup
        ),
        vim.log.levels.INFO,
        {
          title = "ASH NeoVim — Startup Profile",
          timeout = 5000,
        }
      )
    end, 0)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- END OF init.lua — "If your config isn't this clean, you're not trying."
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━