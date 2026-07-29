-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰣇 HYPRLAND — ULTRA CONFIG LANGUAGE SUPPORT v5.0 OMEGA                   ║
-- ║   hyprls · custom treesitter parser · hyprctl integration · ASH config aware  ║
-- ║   monitors · keybinds · animations · shaders · ASH theme-synced               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — Hyprland config premium colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── LSP tokens ────────────────────────────────────────────────────────────
    hl(0, "@lsp.type.keyword.hypr",      { bold = true,   fg = "#7aa2f7" })
    hl(0, "@lsp.type.variable.hypr",     { fg = "#cba6f7"                })
    hl(0, "@lsp.type.property.hypr",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.string.hypr",       { fg = "#a6e3a1"                })
    hl(0, "@lsp.type.number.hypr",       { fg = "#fab387"                })
    hl(0, "@lsp.type.boolean.hypr",      { bold = true,   fg = "#fab387" })
    hl(0, "@lsp.type.comment.hypr",      { italic = true, fg = "#9399b2" })
    hl(0, "@lsp.type.operator.hypr",     { fg = "#89b4fa"                })
    hl(0, "@lsp.type.section.hypr",      { bold = true,   fg = "#f9e2af" })
    hl(0, "@lsp.type.modifier.hypr",     { bold = true,   fg = "#cba6f7" })
  
    -- ── Treesitter hypr ───────────────────────────────────────────────────────
    hl(0, "@keyword.hypr",               { bold = true,   fg = "#7aa2f7" })
    hl(0, "@property.hypr",              { fg = "#89b4fa"                })
    hl(0, "@variable.hypr",              { fg = "#cba6f7"                })
    hl(0, "@string.hypr",                { fg = "#a6e3a1"                })
    hl(0, "@number.hypr",                { fg = "#fab387"                })
    hl(0, "@boolean.hypr",               { bold = true,   fg = "#fab387" })
    hl(0, "@comment.hypr",               { italic = true, fg = "#9399b2" })
    hl(0, "@operator.hypr",              { fg = "#89b4fa"                })
    hl(0, "@punctuation.bracket.hypr",   { fg = "#cdd6f4"                })
    hl(0, "@punctuation.delimiter.hypr", { fg = "#9399b2"                })
    hl(0, "@punctuation.special.hypr",   { bold = true,   fg = "#cba6f7" })
    hl(0, "@type.hypr",                  { bold = true,   fg = "#f9e2af" })
    hl(0, "@constant.hypr",              { bold = true,   fg = "#fab387" })
  
    -- ── Hyprland config sections ───────────────────────────────────────────────
    hl(0, "HyprSection",       { bold = true, italic = true, fg = "#f9e2af", bg = "#2d2a1e" })
    hl(0, "HyprKeyword",       { bold = true,   fg = "#7aa2f7" })
    hl(0, "HyprVariable",      { fg = "#cba6f7"                })
    hl(0, "HyprValue",         { fg = "#a6e3a1"                })
    hl(0, "HyprModKey",        { bold = true,   fg = "#f38ba8" })  -- SUPER, ALT, etc.
    hl(0, "HyprKey",           { bold = true,   fg = "#f9e2af" })  -- key names
    hl(0, "HyprColor",         { bold = true,   fg = "#7dcfff" })  -- rgba() colours
    hl(0, "HyprAnimation",     { italic = true, fg = "#94e2d5" })
    hl(0, "HyprMonitor",       { bold = true,   fg = "#89b4fa" })
    hl(0, "HyprWorkspace",     { bold = true,   fg = "#9ece6a" })
    hl(0, "HyprWindowRule",    { italic = true, fg = "#cba6f7" })
    hl(0, "HyprLayerRule",     { italic = true, fg = "#89b4fa" })
    hl(0, "HyprBind",          { bold = true,   fg = "#7aa2f7" })
    hl(0, "HyprExec",          { bold = true,   fg = "#9ece6a" })
    hl(0, "HyprEnv",           { bold = true,   fg = "#f9e2af" })
    hl(0, "HyprPlugin",        { bold = true,   fg = "#fab387" })
    hl(0, "HyprSource",        { italic = true, underline = true, fg = "#89b4fa" })
    hl(0, "HyprSubmap",        { bold = true,   fg = "#cba6f7" })
    hl(0, "HyprDispatcher",    { fg = "#89dceb"                })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@keyword.hypr",   { bold = true, fg = p.blue })
        hl(0, "HyprKeyword",     { bold = true, fg = p.blue })
        hl(0, "HyprBind",        { bold = true, fg = p.blue })
        hl(0, "HyprMonitor",     { bold = true, fg = p.blue })
      end
      if p.yellow then
        hl(0, "@type.hypr",      { bold = true, fg = p.yellow })
        hl(0, "HyprSection",     { bold = true, italic = true, fg = p.yellow, bg = p.surface0 or "#2d2a1e" })
        hl(0, "HyprKey",         { bold = true, fg = p.yellow })
      end
      if p.mauve  then
        hl(0, "@variable.hypr",  { fg = p.mauve })
        hl(0, "HyprVariable",    { fg = p.mauve })
        hl(0, "HyprWindowRule",  { italic = true, fg = p.mauve })
      end
      if p.green  then
        hl(0, "@string.hypr",    { fg = p.green })
        hl(0, "HyprValue",       { fg = p.green })
        hl(0, "HyprExec",        { bold = true, fg = p.green })
        hl(0, "HyprWorkspace",   { bold = true, fg = p.green })
      end
      if p.red    then hl(0, "HyprModKey",  { bold = true, fg = p.red }) end
      if p.teal   then hl(0, "HyprAnimation",{ italic = true, fg = p.teal }) end
      if p.cyan   then hl(0, "HyprColor",    { bold = true, fg = p.cyan }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "@comment.hypr", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 HYPRLAND UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Run hyprctl command and show output
  local function hyprctl(args, title)
    if vim.fn.executable("hyprctl") ~= 1 then
      vim.notify("󰣇 hyprctl not found (not running Hyprland?)", vim.log.levels.WARN,
        { title = "Hyprland" })
      return nil
    end
    local result = vim.fn.systemlist("hyprctl " .. args .. " 2>&1")
    if title then
      vim.notify(
        table.concat(result, "\n"),
        vim.log.levels.INFO,
        { title = "hyprctl: " .. title }
      )
    end
    return result
  end
  
  -- Reload Hyprland config (the ASH way)
  local function reload_config()
    if vim.fn.executable("hyprctl") ~= 1 then
      vim.notify("󰣇 hyprctl not available", vim.log.levels.WARN, { title = "Hyprland" })
      return
    end
  
    -- Save the current buffer first
    vim.cmd("write")
  
    -- Reload via hyprctl
    vim.fn.system("hyprctl reload")
    vim.notify(
      "󰣇 Hyprland config reloaded",
      vim.log.levels.INFO,
      { title = "Hyprland", timeout = 1500 }
    )
  end
  
  -- List active monitors
  local function show_monitors()
    hyprctl("monitors", "Monitors")
  end
  
  -- List workspaces
  local function show_workspaces()
    hyprctl("workspaces", "Workspaces")
  end
  
  -- List active windows
  local function show_clients()
    hyprctl("clients", "Clients")
  end
  
  -- Dispatch hyprctl command from input
  local function dispatch_cmd()
    vim.ui.input({ prompt = "󰣇 hyprctl dispatch: " }, function(cmd)
      if cmd and cmd ~= "" then
        local result = vim.fn.system("hyprctl dispatch " .. cmd)
        vim.notify(
          result ~= "" and result or "OK",
          vim.log.levels.INFO,
          { title = "hyprctl dispatch", timeout = 1500 }
        )
      end
    end)
  end
  
  -- Show keyword value via hyprctl keyword
  local function set_keyword()
    vim.ui.input({ prompt = "󰣇 hyprctl keyword (key val): " }, function(input)
      if input and input ~= "" then
        local result = vim.fn.system("hyprctl keyword " .. input)
        vim.notify(
          result ~= "" and result or "Set: " .. input,
          vim.log.levels.INFO,
          { title = "hyprctl keyword", timeout = 1500 }
        )
      end
    end)
  end
  
  -- Hyprland config file paths
  local HYPR_CONFIG_DIR = vim.fn.expand("~/.config/hypr")
  
  local HYPR_FILES = {
    { name = "hyprland.conf",    desc = "Main config"          },
    { name = "keybinds.conf",    desc = "Keybindings"          },
    { name = "animations.conf",  desc = "Animations"           },
    { name = "decorations.conf", desc = "Decorations"          },
    { name = "monitors.conf",    desc = "Monitors"             },
    { name = "autostart.conf",   desc = "Autostart"            },
    { name = "windowrules.conf", desc = "Window rules"         },
    { name = "env.conf",         desc = "Environment variables" },
    { name = "themes/colors.conf",desc = "Theme colours"       },
    { name = "plugins.conf",     desc = "Hyprland plugins"     },
  }
  
  -- Open Hypr config file picker
  local function open_hypr_config()
    local existing = vim.tbl_filter(function(f)
      return vim.fn.filereadable(HYPR_CONFIG_DIR .. "/" .. f.name) == 1
    end, HYPR_FILES)
  
    if #existing == 0 then
      vim.notify("󰣇 No Hyprland configs found in " .. HYPR_CONFIG_DIR,
        vim.log.levels.WARN, { title = "Hyprland" })
      return
    end
  
    local items = vim.tbl_map(function(f)
      return string.format("%-25s  %s", f.name, f.desc)
    end, existing)
  
    vim.ui.select(items, { prompt = "󰣇 Open Hyprland config: " }, function(_, idx)
      if idx then
        vim.cmd("edit " .. HYPR_CONFIG_DIR .. "/" .. existing[idx].name)
      end
    end)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── Treesitter: hypr grammar (custom) ─────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "hypr" })
  
        -- Register custom parser if not already in treesitter
        local ok_p, parser_config = pcall(
          function() return require("nvim-treesitter.parsers").get_parser_configs() end
        )
        if ok_p and parser_config and not parser_config.hypr then
          parser_config.hypr = {
            install_info = {
              url    = "https://github.com/luckasRanarison/tree-sitter-hypr",
              files  = { "src/parser.c" },
              branch = "main",
              generate_requires_npm            = false,
              requires_generate_from_grammar   = false,
            },
            filetype = "hypr",
          }
        end
      end,
    },
  
    -- ── hyprls — Hyprland language server ─────────────────────────────────────────
    {
      "neovim/nvim-lspconfig",
      ft   = "hypr",
      opts = {
        servers = {
          hyprls = {
            cmd       = { "hyprls" },
            filetypes = { "hypr" },
            root_dir  = function(fname)
              return vim.fn.fnamemodify(fname, ":h")
            end,
            on_attach = function(client, bufnr)
              -- Auto-reload on save
              vim.api.nvim_create_autocmd("BufWritePost", {
                buffer   = bufnr,
                callback = function()
                  if vim.g.ash_hypr_autoreload then
                    reload_config()
                  end
                end,
              })
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {},
          },
        },
      },
    },
  
    -- ── Hyprland config utilities ──────────────────────────────────────────────────
    {
      "nvim-lua/plenary.nvim",
      ft = "hypr",
  
      keys = {
        -- ── Config management ──────────────────────────────────────────────────
        {
          "<leader>hyR",
          reload_config,
          desc = "󰣇 Hyprland: Reload config",
        },
        {
          "<leader>hyo",
          open_hypr_config,
          desc = "󰣇 Hyprland: Open config file",
        },
        {
          "<leader>hyc",
          function()
            vim.cmd("edit " .. HYPR_CONFIG_DIR .. "/hyprland.conf")
          end,
          desc = "󰣇 Hyprland: Main config",
        },
        {
          "<leader>hyk",
          function()
            local kf = HYPR_CONFIG_DIR .. "/keybinds/default.conf"
            if vim.fn.filereadable(kf) == 1 then
              vim.cmd("edit " .. kf)
            else
              vim.cmd("edit " .. HYPR_CONFIG_DIR .. "/keybinds.conf")
            end
          end,
          desc = "󰣇 Hyprland: Keybinds",
        },
        {
          "<leader>hyt",
          function()
            vim.cmd("edit " .. HYPR_CONFIG_DIR .. "/themes/colors.conf")
          end,
          desc = "󰣇 Hyprland: Theme colors",
        },
  
        -- ── ASH integration ────────────────────────────────────────────────────
        {
          "<leader>hya",
          function()
            vim.notify(
              "󰣇 Triggering ASH theme sync…",
              vim.log.levels.INFO,
              { title = "Hyprland + ASH", timeout = 800 }
            )
            vim.fn.system("ash theme apply --reload")
          end,
          desc = "󰣇 Hyprland: ASH theme apply",
        },
  
        -- ── Toggle auto-reload on save ──────────────────────────────────────────
        {
          "<leader>hyu",
          function()
            vim.g.ash_hypr_autoreload = not vim.g.ash_hypr_autoreload
            vim.notify(
              string.format("󰣇 Auto-reload on save: %s",
                vim.g.ash_hypr_autoreload and "✅ ON" or "⭕ OFF"),
              vim.log.levels.INFO,
              { title = "Hyprland", timeout = 1200 }
            )
          end,
          ft   = "hypr",
          desc = "󰣇 Hyprland: Toggle auto-reload",
        },
  
        -- ── hyprctl commands ──────────────────────────────────────────────────
        {
          "<leader>hym",
          show_monitors,
          desc = "󰣇 Hyprland: Show monitors",
        },
        {
          "<leader>hyw",
          show_workspaces,
          desc = "󰣇 Hyprland: Show workspaces",
        },
        {
          "<leader>hyW",
          show_clients,
          desc = "󰣇 Hyprland: Show clients",
        },
        {
          "<leader>hyd",
          dispatch_cmd,
          desc = "󰣇 Hyprland: Dispatch command",
        },
        {
          "<leader>hys",
          set_keyword,
          desc = "󰣇 Hyprland: Set keyword",
        },
        {
          "<leader>hyi",
          function()
            local hypr_v   = vim.fn.trim(vim.fn.system("hyprctl version 2>/dev/null | head -1"))
            local hyprls_v = vim.fn.executable("hyprls")
            local hl_count = #vim.fn.glob(HYPR_CONFIG_DIR .. "/**/*.conf", false, true)
            vim.notify(
              table.concat({
                "󰣇 Hyprland Environment",
                "──────────────────────────────────",
                string.format("  Version:     %s", hypr_v),
                string.format("  hyprls:      %s", hyprls_v == 1 and "✅" or "⭕"),
                string.format("  Config dir:  %s", HYPR_CONFIG_DIR),
                string.format("  Config files:%d .conf files", hl_count),
                string.format("  Auto-reload: %s", vim.g.ash_hypr_autoreload and "✅ ON" or "⭕ OFF"),
                string.format("  ASH:         %s", vim.fn.executable("ash") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Hyprland Info" }
            )
          end,
          desc = "󰣇 Hyprland: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        -- Filetype detection for all Hyprland config files
        vim.filetype.add({
          extension = { hypr = "hypr" },
          filename  = {
            ["hyprland.conf"]  = "hypr",
            ["hyprlock.conf"]  = "hypr",
            ["hypridle.conf"]  = "hypr",
            ["hyprpaper.conf"] = "hypr",
          },
          pattern   = {
            [".*/hypr/.*%.conf"]     = "hypr",
            [".*/hyprland/.*%.conf"] = "hypr",
            -- ASH dotfiles hypr directory
            [".*/config/hypr/.*"]    = "hypr",
            -- Per-device configs
            [".*/per%-device/.*%.conf"] = "hypr",
            -- Mode configs
            [".*/modes/.*%.conf"]    = "hypr",
          },
        })
  
        local aug = vim.api.nvim_create_augroup("AshHypr", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "hypr",
          callback = function()
            vim.opt_local.expandtab    = true
            vim.opt_local.shiftwidth   = 4
            vim.opt_local.tabstop      = 4
            vim.opt_local.softtabstop  = 4
            vim.opt_local.textwidth    = 100
            vim.opt_local.commentstring= "# %s"
            vim.opt_local.foldmethod   = "expr"
            vim.opt_local.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
            vim.opt_local.foldlevel    = 99
  
            -- Extmarks: highlight section headers with background
            local bufnr = vim.api.nvim_get_current_buf()
            local ns    = vim.api.nvim_create_namespace("AshHyprSections")
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            for i, line in ipairs(lines) do
              -- Detect section headers like: general {  input {  animations {
              if line:match("^%s*[%w_]+%s*{%s*$") and not line:match("^%s*#") then
                vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
                  hl_group = "HyprSection",
                  hl_eol   = true,
                  priority = 90,
                })
              end
            end
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("󰣇 Hyprland highlights synced", vim.log.levels.INFO,
              { title = "ASH Hyprland", timeout = 1200 })
          end,
        })
  
        -- ASH-specific: fire event when Hyprland config changes
        vim.api.nvim_create_autocmd("BufWritePost", {
          group   = aug,
          pattern = "*.hypr,hyprland.conf,hyprlock.conf",
          callback = function()
            vim.api.nvim_exec_autocmds("User", {
              pattern = "HyprConfigChanged",
              data    = { file = vim.api.nvim_buf_get_name(0) },
            })
          end,
        })
  
        -- Expose global toggle for auto-reload
        vim.g.ash_hypr_autoreload = false
  
        if vim.g.ash_debug then
          vim.notify(
            "󰣇 Hyprland lang support loaded",
            vim.log.levels.DEBUG,
            { title = "ASH Hyprland" }
          )
        end
      end,
    },
  }