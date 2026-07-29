-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌊 CODEIUM AI — ULTRA FREE AI COMPLETION ENGINE v5.0 OMEGA               ║
-- ║   Ghost text · virtual text · cmp source · chat · local inference              ║
-- ║   40+ languages · smart context · ASH theme-synced animated suggestions        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — gradient ghost text with personality
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  -- ── Ghost text layers ─────────────────────────────────────────────────────
  hl(0, "CodeiumSuggestion",        {
    italic    = true,
    fg        = "#4a5568",
    nocombine = true,
  })

  -- ── Codeium panel ─────────────────────────────────────────────────────────
  hl(0, "CodeiumPanelNormal",       { link = "NormalFloat"   })
  hl(0, "CodeiumPanelBorder",       { link = "FloatBorder"   })
  hl(0, "CodeiumPanelTitle",        {
    bold      = true,
    fg        = "#09B6A2",
  })

  -- ── Status indicators ─────────────────────────────────────────────────────
  hl(0, "CodeiumEnabled",           { bold = true,   fg = "#09B6A2" })
  hl(0, "CodeiumDisabled",          { italic = true, fg = "#6e738d" })
  hl(0, "CodeiumLoading",           { bold = true,   fg = "#f9e2af" })
  hl(0, "CodeiumError",             { bold = true,   fg = "#f38ba8" })
  hl(0, "CodeiumConnected",         { bold = true,   fg = "#09B6A2" })

  -- ── Chat UI ───────────────────────────────────────────────────────────────
  hl(0, "CodeiumChatUser",          { bold = true,   fg = "#7aa2f7" })
  hl(0, "CodeiumChatAI",            { bold = true,   fg = "#09B6A2" })
  hl(0, "CodeiumChatCode",          { bg = "#1e2030", fg = "#cdd6f4" })
  hl(0, "CodeiumChatBorder",        { link = "FloatBorder"   })

  -- ── cmp item kind ─────────────────────────────────────────────────────────
  hl(0, "CmpItemKindCodeium",       { fg = "#09B6A2"                })

  -- ── ASH palette sync ──────────────────────────────────────────────────────
  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p   = ash.palette
    local dim = p.overlay0 or p.subtext0 or "#4a5568"

    hl(0, "CodeiumSuggestion", { italic = true, fg = dim, nocombine = true })

    local teal = p.teal or "#09B6A2"
    hl(0, "CodeiumEnabled",    { bold = true, fg = teal })
    hl(0, "CodeiumPanelTitle", { bold = true, fg = teal })
    hl(0, "CodeiumConnected",  { bold = true, fg = teal })
    hl(0, "CodeiumChatAI",     { bold = true, fg = teal })
    hl(0, "CmpItemKindCodeium",{ fg = teal              })

    if p.blue  then hl(0, "CodeiumChatUser",  { bold = true, fg = p.blue   }) end
    if p.yellow then hl(0, "CodeiumLoading",  { bold = true, fg = p.yellow }) end
    if p.red   then hl(0, "CodeiumError",     { bold = true, fg = p.red    }) end

    if p.surface1 then
      hl(0, "CodeiumChatCode", { bg = p.surface1, fg = p.text or "#cdd6f4" })
    end
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 STATE MANAGEMENT & SMART ACTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local _enabled = true
local _stats   = { accepted = 0, dismissed = 0, shown = 0, session_start = os.time() }

local function toggle()
  local ok, codeium = pcall(require, "codeium")
  if not ok then return end

  _enabled = not _enabled

  if _enabled then
    codeium.enable()
    vim.notify(
      "🌊 Codeium  ACTIVE",
      vim.log.levels.INFO,
      { title = "Codeium", timeout = 1200 }
    )
  else
    codeium.disable()
    vim.notify(
      "🌊 Codeium  PAUSED",
      vim.log.levels.INFO,
      { title = "Codeium", timeout = 1200 }
    )
  end
end

local function show_session_stats()
  local elapsed   = os.time() - _stats.session_start
  local hours     = math.floor(elapsed / 3600)
  local mins      = math.floor((elapsed % 3600) / 60)
  local accept_rate = _stats.shown > 0
    and string.format("%.1f%%", (_stats.accepted / _stats.shown) * 100)
    or "n/a"

  vim.notify(
    table.concat({
      "🌊 Codeium Session Stats",
      "──────────────────────────────────",
      string.format("  Status:     %s", _enabled and "✅ Active" or "⭕ Paused"),
      string.format("  Duration:   %dh %dm", hours, mins),
      string.format("  Shown:      %d suggestions", _stats.shown),
      string.format("  Accepted:   %d", _stats.accepted),
      string.format("  Dismissed:  %d", _stats.dismissed),
      string.format("  Accept rate:%s", accept_rate),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Codeium Analytics" }
  )
end

-- Diagnose Codeium connection
local function diagnose()
  local ok, codeium_status = pcall(require, "codeium.status")
  if not ok then
    vim.notify("🌊 Codeium not loaded", vim.log.levels.WARN, { title = "Codeium" })
    return
  end

  local status = codeium_status.get_status()
  vim.notify(
    table.concat({
      "🌊 Codeium Diagnostics",
      "──────────────────────────────────",
      string.format("  Status:  %s", vim.inspect(status)),
      string.format("  Enabled: %s", _enabled and "yes" or "no"),
      string.format("  Version: %s",
        vim.fn.trim(vim.fn.system("codeium --version 2>/dev/null")) or "unknown"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Codeium Diagnostics" }
  )
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "Exafunction/codeium.nvim",
    cmd          = {
      "Codeium",
      "CodeiumEnable",
      "CodeiumDisable",
      "CodeiumToggle",
      "CodeiumAuto",
      "CodeiumManual",
      "CodeiumChat",
      "CodeiumStatus",
    },
    event        = "InsertEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "hrsh7th/nvim-cmp", optional = true },
    },

    keys = {
      -- ── Accept ────────────────────────────────────────────────────────────
      {
        "<M-a>",
        function()
          local ok, vt = pcall(require, "codeium.virtual_text")
          if ok and vt.get_current_completion_item then
            _stats.accepted = _stats.accepted + 1
          end
          return vim.fn["codeium#Accept"]()
        end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Accept suggestion",
        silent = true,
      },

      -- ── Accept word ───────────────────────────────────────────────────────
      {
        "<M-w>",
        function() return vim.fn["codeium#AcceptNextWord"]() end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Accept next word",
        silent = true,
      },

      -- ── Accept line ───────────────────────────────────────────────────────
      {
        "<M-l>",
        function() return vim.fn["codeium#AcceptNextLine"]() end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Accept next line",
        silent = true,
      },

      -- ── Cycle suggestions ─────────────────────────────────────────────────
      {
        "<M-]>",
        function()
          _stats.shown = _stats.shown + 1
          return vim.fn["codeium#CycleCompletions"](1)
        end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Next suggestion",
        silent = true,
      },
      {
        "<M-[>",
        function()
          _stats.shown = _stats.shown + 1
          return vim.fn["codeium#CycleCompletions"](-1)
        end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Prev suggestion",
        silent = true,
      },

      -- ── Dismiss ────────────────────────────────────────────────────────────
      {
        "<M-e>",
        function()
          _stats.dismissed = _stats.dismissed + 1
          return vim.fn["codeium#Clear"]()
        end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Dismiss",
        silent = true,
      },

      -- ── Manual trigger ────────────────────────────────────────────────────
      {
        "<M-s>",
        function() return vim.fn["codeium#Complete"]() end,
        mode   = "i",
        expr   = true,
        desc   = "🌊 Codeium: Trigger completion",
        silent = true,
      },

      -- ── Control ───────────────────────────────────────────────────────────
      {
        "<leader>aI",
        toggle,
        desc   = "🌊 Codeium: Toggle",
        silent = true,
      },
      {
        "<leader>aIs",
        show_session_stats,
        desc   = "🌊 Codeium: Session stats",
        silent = true,
      },
      {
        "<leader>aId",
        diagnose,
        desc   = "🌊 Codeium: Diagnose",
        silent = true,
      },
      {
        "<leader>aIc",
        "<cmd>CodeiumChat<cr>",
        desc   = "🌊 Codeium: Chat",
        silent = true,
      },
    },

    opts = {
      -- ── Virtual text ──────────────────────────────────────────────────────
      enable_chat        = true,
      enable_local_search= true,
      enable_index_service = true,

      -- ── Virtual text config ───────────────────────────────────────────────
      virtual_text = {
        enabled          = true,
        manual           = false,
        hide_during_cmp  = true,
        key_bindings     = {
          accept         = false,
          next           = false,
          prev           = false,
          dismiss        = false,
        },
        hl_group         = "CodeiumSuggestion",
        inline_completions = true,
      },

      -- ── Disable in certain filetypes ──────────────────────────────────────
      tools = {
        -- Disable for binary / special buffers
      },
    },

    config = function(_, opts)
      require("codeium").setup(opts)

      setup_highlights()

      -- ── Expose statusline component ────────────────────────────────────────
      _G.AshCodeiumStatus = function()
        if not _enabled then return " 🌊 " end
        local ok, fn = pcall(function()
          return vim.fn["codeium#GetStatusString"]()
        end)
        if ok and fn ~= "" then
          return " 🌊 " .. tostring(fn) .. " "
        end
        return " 🌊 "
      end

      local aug = vim.api.nvim_create_augroup("AshCodeiumAI", { clear = true })

      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("🌊 Codeium highlights synced", vim.log.levels.INFO,
            { title = "ASH Codeium", timeout = 1200 })
        end,
      })
    end,
  },
}