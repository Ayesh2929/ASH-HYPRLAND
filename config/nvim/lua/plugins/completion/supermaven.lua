-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🚀 SUPERMAVEN — ULTRA FAST AI COMPLETION v5.0 OMEGA                      ║
-- ║   300ms latency · 300k token context · ghost text · cmp integration            ║
-- ║   per-filetype · pro features · ASH theme-synced · smart dismiss               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — supermaven ghost text colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Ghost text
    hl(0, "SupermavenSuggestion",    {
      italic    = true,
      fg        = "#6e738d",
    })
  
    -- Accepted flash
    hl(0, "SupermavenAccepted",      {
      bold      = true,
      fg        = "#6f6c99",
      bg        = "#1a1930",
    })
  
    -- Status colours
    hl(0, "SupermavenEnabled",       { bold = true, fg = "#6f6c99"    })
    hl(0, "SupermavenDisabled",      { italic = true, fg = "#6e738d"  })
    hl(0, "SupermavenLoading",       { bold = true, fg = "#e0af68"    })
    hl(0, "SupermavenError",         { bold = true, fg = "#f38ba8"    })
    hl(0, "SupermavenPro",           { bold = true, fg = "#bb9af7"    })
  
    -- cmp kind
    hl(0, "CmpItemKindSupermaven",   { fg = "#6f6c99"                })
  
    -- ASH palette sync
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p   = ash.palette
      local dim = p.overlay0 or "#6e738d"
      hl(0, "SupermavenSuggestion", { italic = true, fg = dim })
      if p.mauve then
        hl(0, "SupermavenEnabled",    { bold = true, fg = p.mauve    })
        hl(0, "CmpItemKindSupermaven",{ fg = p.mauve                 })
        hl(0, "SupermavenAccepted",   {
          bold = true,
          fg   = p.mauve,
          bg   = p.surface0 or "#1a1930",
        })
      end
      if p.yellow then hl(0, "SupermavenLoading", { bold = true, fg = p.yellow }) end
      if p.red    then hl(0, "SupermavenError",   { bold = true, fg = p.red    }) end
      if p.lavender then hl(0, "SupermavenPro",   { bold = true, fg = p.lavender }) end
      hl(0, "SupermavenDisabled", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 STATE MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _sm_enabled = true
  
  local function toggle_supermaven()
    local ok, sm = pcall(require, "supermaven-nvim.api")
    if not ok then
      vim.notify("🚀 Supermaven not loaded", vim.log.levels.WARN,
        { title = "Supermaven" })
      return
    end
  
    if _sm_enabled then
      sm.stop()
      _sm_enabled = false
      vim.notify("🚀 Supermaven  disabled", vim.log.levels.INFO,
        { title = "Supermaven", timeout = 1200 })
    else
      sm.start()
      _sm_enabled = true
      vim.notify("🚀 Supermaven  enabled", vim.log.levels.INFO,
        { title = "Supermaven", timeout = 1200 })
    end
  end
  
  local function show_supermaven_status()
    local ok, sm = pcall(require, "supermaven-nvim.api")
    if not ok then
      vim.notify("🚀 Supermaven not loaded", vim.log.levels.WARN, { title = "Supermaven" })
      return
    end
  
    local status = sm.get_status and sm.get_status() or { running = _sm_enabled }
    local lines  = {
      "🚀 Supermaven Status",
      "─────────────────────",
      string.format("  Running:  %s", (status.running or _sm_enabled) and "✅" or "⭕"),
      string.format("  Plan:     %s", status.plan or "free"),
      string.format("  Version:  %s", status.version or "latest"),
    }
    vim.notify(
      table.concat(lines, "\n"),
      vim.log.levels.INFO,
      { title = "Supermaven" }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "supermaven-inc/supermaven-nvim",
      event        = "InsertEnter",
      cmd          = {
        "SupermavenStart",
        "SupermavenStop",
        "SupermavenRestart",
        "SupermavenToggle",
        "SupermavenStatus",
        "SupermavenUseFree",
        "SupermavenUsePro",
        "SupermavenLogout",
      },
  
      keys = {
        { "<leader>aM",  toggle_supermaven,    desc = "🚀 Toggle Supermaven", silent = true },
        { "<leader>ams", show_supermaven_status, desc = "🚀 Supermaven Status", silent = true },
  
        -- Accept full suggestion
        {
          "<M-s>",
          function()
            local ok, completion = pcall(require, "supermaven-nvim.completion_preview")
            if ok then completion.on_accept_suggestion() end
          end,
          mode   = "i",
          desc   = "🚀 Accept Supermaven",
          silent = true,
        },
  
        -- Accept next word
        {
          "<M-d>",
          function()
            local ok, completion = pcall(require, "supermaven-nvim.completion_preview")
            if ok then completion.on_accept_suggestion_word() end
          end,
          mode   = "i",
          desc   = "🚀 Accept Supermaven word",
          silent = true,
        },
  
        -- Dismiss suggestion
        {
          "<M-c>",
          function()
            local ok, completion = pcall(require, "supermaven-nvim.completion_preview")
            if ok then completion.on_dismiss_suggestion() end
          end,
          mode   = "i",
          desc   = "🚀 Dismiss Supermaven",
          silent = true,
        },
      },
  
      opts = {
        -- ── Keymaps (plugin-native) ────────────────────────────────────────────
        -- We manage these manually above for consistency
        keymaps = {
          accept_suggestion      = "<M-s>",
          clear_suggestion       = "<M-c>",
          accept_word            = "<M-d>",
        },
  
        -- ── Colour for ghost text ──────────────────────────────────────────────
        color = {
          suggestion_color       = "#6e738d",
          cterm                  = 244,
        },
  
        -- ── Log level ─────────────────────────────────────────────────────────
        log_level                = "info",
  
        -- ── Disable supermaven in these filetypes ─────────────────────────────
        disable_inline_completion = {
          -- Completion handled by dedicated plugins
          "neo-tree",
          "TelescopePrompt",
          "fzf",
          "lazy",
          "mason",
          "alpha",
          "dashboard",
          "toggleterm",
          "help",
          "man",
          "noice",
          "notify",
          "checkhealth",
          "lspinfo",
          "DressingInput",
          "gitcommit",
          "NeogitCommitMessage",
        },
  
        -- ── Ignore these filetypes for ghost text ─────────────────────────────
        disable_keymaps            = false,
  
        -- ── Use pro features (if logged in) ───────────────────────────────────
        condition                  = function() return true end,
  
        -- ── cmp source settings ───────────────────────────────────────────────
        -- The cmp source is automatically registered when the plugin loads
      },
  
      config = function(_, opts)
        require("supermaven-nvim").setup(opts)
  
        setup_highlights()
  
        -- ── Override ghost text highlight ─────────────────────────────────────
        -- supermaven uses its own hl group; remap to ours
        vim.api.nvim_create_autocmd("ColorScheme", {
          callback = function()
            setup_highlights()
            -- Remap supermaven's internal hl to our styled one
            vim.api.nvim_set_hl(0, "SupermavenGhost", { link = "SupermavenSuggestion" })
          end,
        })
  
        local aug = vim.api.nvim_create_augroup("AshSupermaven", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.api.nvim_set_hl(0, "SupermavenGhost", { link = "SupermavenSuggestion" })
            vim.notify("🚀 Supermaven highlights synced", vim.log.levels.INFO,
              { title = "ASH Supermaven", timeout = 1200 })
          end,
        })
  
        -- Expose statusline component
        _G.AshSupermavenStatus = function()
          if not _sm_enabled then return " 🚀 " end
          return " 🚀 "
        end
  
        if vim.g.ash_debug then
          vim.notify("🚀 Supermaven loaded", vim.log.levels.DEBUG, { title = "ASH Supermaven" })
        end
      end,
    },
  }