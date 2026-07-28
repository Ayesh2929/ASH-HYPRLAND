-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌊 CODEIUM — ULTRA FREE AI COMPLETION v5.0 OMEGA                         ║
-- ║   Free · local inference option · ghost text · cmp source · ASH theme-synced  ║
-- ║   40+ languages · smart context · per-filetype toggle · status indicators      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — codeium ghost text & status colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Ghost text (AI suggestion shown inline)
    hl(0, "CodeiumSuggestion",    {
      italic    = true,
      fg        = "#6e738d",
    })
  
    -- Accepted suggestion flash
    hl(0, "CodeiumAccepted",      {
      bold      = true,
      fg        = "#09B6A2",
      bg        = "#0d2420",
    })
  
    -- Status indicators
    hl(0, "CodeiumEnabled",       { bold = true, fg = "#09B6A2"   })
    hl(0, "CodeiumDisabled",      { italic = true, fg = "#6e738d" })
    hl(0, "CodeiumLoading",       { bold = true, fg = "#e0af68"   })
    hl(0, "CodeiumError",         { bold = true, fg = "#f38ba8"   })
  
    -- cmp integration
    hl(0, "CmpItemKindCodeium",   { fg = "#09B6A2"               })
  
    -- ASH palette sync
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p   = ash.palette
      local dim = p.overlay0 or "#6e738d"
      hl(0, "CodeiumSuggestion", { italic = true, fg = dim })
      if p.teal or p.cyan then
        local c = p.teal or p.cyan
        hl(0, "CodeiumEnabled",       { bold = true, fg = c })
        hl(0, "CmpItemKindCodeium",   { fg = c              })
        hl(0, "CodeiumAccepted",      { bold = true, fg = c, bg = p.surface0 or "#0d2420" })
      end
      if p.yellow  then hl(0, "CodeiumLoading", { bold = true, fg = p.yellow }) end
      if p.red     then hl(0, "CodeiumError",   { bold = true, fg = p.red    }) end
      hl(0, "CodeiumDisabled", { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 STATE MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _codeium_enabled = true
  
  local function toggle_codeium()
    _codeium_enabled = not _codeium_enabled
    if _codeium_enabled then
      vim.fn["codeium#Enable"]()
      vim.notify("🌊 Codeium  enabled", vim.log.levels.INFO,
        { title = "Codeium", timeout = 1200 })
    else
      vim.fn["codeium#Disable"]()
      vim.notify("🌊 Codeium  disabled", vim.log.levels.INFO,
        { title = "Codeium", timeout = 1200 })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "Exafunction/codeium.nvim",
      cmd          = { "Codeium", "CodeiumEnable", "CodeiumDisable" },
      event        = "InsertEnter",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
      },
  
      keys = {
        { "<leader>aI",  toggle_codeium, desc = "🌊 Toggle Codeium",  silent = true },
        -- Accept suggestion
        {
          "<M-a>",
          function()
            return vim.fn["codeium#Accept"]()
          end,
          mode   = "i",
          expr   = true,
          desc   = "🌊 Accept Codeium",
          silent = true,
        },
        -- Next suggestion
        {
          "<M-}>",
          function()
            return vim.fn["codeium#CycleCompletions"](1)
          end,
          mode   = "i",
          expr   = true,
          desc   = "🌊 Next Codeium suggestion",
          silent = true,
        },
        -- Prev suggestion
        {
          "<M-{>",
          function()
            return vim.fn["codeium#CycleCompletions"](-1)
          end,
          mode   = "i",
          expr   = true,
          desc   = "🌊 Prev Codeium suggestion",
          silent = true,
        },
        -- Clear suggestion
        {
          "<M-x>",
          function()
            return vim.fn["codeium#Clear"]()
          end,
          mode   = "i",
          expr   = true,
          desc   = "🌊 Clear Codeium",
          silent = true,
        },
      },
  
      opts = {
        -- ── Virtual text ──────────────────────────────────────────────────────
        enable_chat           = false,
        enable_local_search   = true,
        enable_index_service  = true,
  
        -- ── Keymap (via opts – some versions use this) ────────────────────────
        tools                 = {},
        wrapper               = nil,
  
        -- ── Disable per filetype ──────────────────────────────────────────────
        detect_proxy          = nil,
  
        -- ── cmp source config ─────────────────────────────────────────────────
        -- handled in cmp.lua via { name = "codeium" }
  
        -- ── Virtual text config ───────────────────────────────────────────────
        virtual_text = {
          enabled      = true,
          manual       = false,
  
          -- Only show ghost text when there are no cmp items visible
          hide_during_cmp = true,
  
          -- Delay before showing suggestion (ms)
          key_bindings = {
            accept        = false,   -- handled above
            next          = false,
            prev          = false,
            dismiss       = false,
          },
  
          hl_group      = "CodeiumSuggestion",
  
          -- Show as virtual text overlay
          inline_completions = true,
        },
      },
  
      config = function(_, opts)
        require("codeium").setup(opts)
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshCodeium", { clear = true })
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
  
        -- Statusline component
        _G.AshCodeiumStatus = function()
          if not _codeium_enabled then return " 🌊 " end
          local ok, status = pcall(vim.fn["codeium#GetStatusString"])
          if ok and status and status ~= "" then
            return " 🌊 " .. tostring(status) .. " "
          end
          return " 🌊 "
        end
  
        if vim.g.ash_debug then
          vim.notify("🌊 Codeium loaded", vim.log.levels.DEBUG, { title = "ASH Codeium" })
        end
      end,
    },
  }