-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🏋️  HARDTIME — ULTRA VIM HABIT TRAINER v5.0 OMEGA                        ║
-- ║   Break bad habits · enforce motions · smart restrictions · per-mode           ║
-- ║   customisable hints · gamification · ASH integration · progress tracking      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 WHAT HARDTIME TRAINS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  ❌ Stops hjkl-spam  (repeated basic motions)
--  ❌ Stops arrow key usage in normal/insert modes
--  ✅ Encourages: w/b/e/ge, f/F/t/T, /, ?, *, n/N, %
--  ✅ Encourages: }  {  [[ ]] <C-d> <C-u>  gg G
--  ✅ Encourages: flash.nvim / hop.nvim jumps
--  📊 Tracks violation count per session

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎯 HINT MESSAGES — motivational replacements per bad motion
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local HINTS = {
    -- hjkl replacements
    {
      pattern      = "^h+$",
      hint         = "⚡ Use b / B / F{char} / T{char} / ^ / 0 instead of hhhh",
      enabled      = true,
      strict        = false,
    },
    {
      pattern      = "^l+$",
      hint         = "⚡ Use e / w / f{char} / $ / A instead of llll",
      enabled      = true,
      strict        = false,
    },
    {
      pattern      = "^k+$",
      hint         = "⚡ Use {  [[  <C-u>  gg  /{pattern} instead of kkkk",
      enabled      = true,
      strict        = false,
    },
    {
      pattern      = "^j+$",
      hint         = "⚡ Use }  ]]  <C-d>  G  /{pattern} instead of jjjj",
      enabled      = true,
      strict        = false,
    },
  
    -- Arrow key hints
    {
      pattern      = "^<Up>+$",
      hint         = "🔼 Arrow keys OFF — use k / { / <C-u>",
      enabled      = true,
      strict        = true,
    },
    {
      pattern      = "^<Down>+$",
      hint         = "🔽 Arrow keys OFF — use j / } / <C-d>",
      enabled      = true,
      strict        = true,
    },
    {
      pattern      = "^<Left>+$",
      hint         = "◀ Arrow keys OFF — use h / b / F{char}",
      enabled      = true,
      strict        = true,
    },
    {
      pattern      = "^<Right>+$",
      hint         = "▶ Arrow keys OFF — use l / w / f{char}",
      enabled      = true,
      strict        = true,
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 SESSION VIOLATION TRACKER
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local VIOLATIONS = { count = 0, by_key = {} }
  
  local function record_violation(key)
    VIOLATIONS.count = VIOLATIONS.count + 1
    VIOLATIONS.by_key[key] = (VIOLATIONS.by_key[key] or 0) + 1
  end
  
  local function show_violation_report()
    if VIOLATIONS.count == 0 then
      vim.notify(
        "🏋️  Perfect session! Zero bad habits detected! 🎉",
        vim.log.levels.INFO,
        { title = "Hardtime Report" }
      )
      return
    end
  
    local lines = {
      string.format("🏋️  Hardtime Session Report — %d violation(s)", VIOLATIONS.count),
      "─────────────────────────────────────",
    }
  
    -- Sort by count descending
    local sorted = {}
    for k, v in pairs(VIOLATIONS.by_key) do
      table.insert(sorted, { key = k, count = v })
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
  
    for _, entry in ipairs(sorted) do
      table.insert(lines, string.format(
        "  %-15s  ×%d  %s",
        entry.key,
        entry.count,
        entry.count > 10 and "⚠️  needs work" or "👍 improving"
      ))
    end
  
    table.insert(lines, "─────────────────────────────────────")
    table.insert(lines, "Keep pushing! Every session gets better 💪")
  
    vim.notify(
      table.concat(lines, "\n"),
      VIOLATIONS.count > 20 and vim.log.levels.WARN or vim.log.levels.INFO,
      { title = "Hardtime Report" }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE — per-buffer hardtime control
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _hardtime_enabled = true
  
  local function toggle_hardtime()
    local ht = require("hardtime")
    if _hardtime_enabled then
      ht.disable()
      _hardtime_enabled = false
      vim.notify(
        "🏋️  Hardtime  disabled (rest mode)",
        vim.log.levels.INFO,
        { title = "Hardtime", timeout = 1500 }
      )
    else
      ht.enable()
      _hardtime_enabled = true
      vim.notify(
        "🏋️  Hardtime  enabled (training mode)",
        vim.log.levels.INFO,
        { title = "Hardtime", timeout = 1500 }
      )
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "m4xshen/hardtime.nvim",
      dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
      },
      event  = { "BufReadPre", "BufNewFile" },
  
      keys = {
        {
          "<leader>uh",
          toggle_hardtime,
          desc   = "🏋️  Toggle Hardtime",
          silent = true,
        },
        {
          "<leader>uH",
          show_violation_report,
          desc   = "🏋️  Hardtime Report",
          silent = true,
        },
      },
  
      opts = {
        -- ── Master switch ────────────────────────────────────────────────────
        enabled          = true,
  
        -- ── Hint configuration ───────────────────────────────────────────────
        -- Hints appear as virtual text or notifications
        hints            = HINTS,
  
        -- ── Notification style ────────────────────────────────────────────────
        -- "nvim" | "hardtime" (nvim = uses vim.notify, hardtime = built-in)
        notification_type = "nvim",
  
        -- ── Maximum repetitions before restriction kicks in ───────────────────
        -- e.g. allow max_count=2 means pressing j 3 times gets blocked
        max_count        = 3,
  
        -- ── Disable count: allow motion with a count prefix ─────────────────
        -- e.g. 5j is allowed; but jjjjj is not
        disable_mouse    = false,
  
        -- ── Restricted keys: throttled when spammed ──────────────────────────
        restricted_keys  = {
          ["h"]      = { "n", "x" },
          ["j"]      = { "n", "x" },
          ["k"]      = { "n", "x" },
          ["l"]      = { "n", "x" },
          ["-"]      = { "n", "x" },
          ["+"]      = { "n", "x" },
          ["gj"]     = { "n", "x" },
          ["gk"]     = { "n", "x" },
          ["<CR>"]   = { "n", "x" },
          ["<C-M>"]  = { "n", "x" },
          ["<C-N>"]  = { "n", "x" },
          ["<C-P>"]  = { "n", "x" },
        },
  
        -- ── Disabled keys: completely blocked ────────────────────────────────
        disabled_keys    = {
          ["<Up>"]    = { "", "i" },
          ["<Down>"]  = { "", "i" },
          ["<Left>"]  = { "", "i" },
          ["<Right>"] = { "", "i" },
        },
  
        -- ── Allowed filetypes: never apply hardtime ────────────────────────
        disabled_filetypes = {
          "alpha",
          "dashboard",
          "starter",
          "neo-tree",
          "NvimTree",
          "oil",
          "minifiles",
          "Trouble",
          "trouble",
          "qf",
          "quickfix",
          "help",
          "man",
          "lazy",
          "mason",
          "TelescopePrompt",
          "TelescopeResults",
          "fzf",
          "toggleterm",
          "terminal",
          "spectre_panel",
          "undotree",
          "gitcommit",
          "NeogitStatus",
          "NeogitCommitMessage",
          "DressingInput",
          "noice",
          "notify",
          "checkhealth",
          "lspinfo",
          "codecompanion",
          "avante",
          "diffview",
          "Diffview*",
        },
  
        -- ── Smart escape: allow hjkl when preceded by a count (5j = OK) ──────
        allow_different_key  = false,
  
        -- ── Resetting ─────────────────────────────────────────────────────────
        -- Reset the restriction timer after these keys are pressed
        reset_keys           = {
          "0", "^", "$", "gg", "G",
          "<C-d>", "<C-u>", "<C-f>", "<C-b>",
          "w", "W", "b", "B", "e", "E", "ge", "gE",
          "f", "F", "t", "T",
          "/", "?", "n", "N", "*", "#",
          "{", "}", "[[", "]]",
          "s", "S",   -- flash.nvim
          "H", "M", "L",
          "%",
        },
  
        -- ── Force mode: make restriction a hard block (not just a hint) ───────
        force_exit_insert_mode = false,
      },
  
      config = function(_, opts)
        require("hardtime").setup(opts)
  
        -- ── Hook into the hint system to track violations ─────────────────────
        local aug = vim.api.nvim_create_augroup("AshHardtime", { clear = true })
  
        -- Track when hardtime fires a notification (proxy for violation)
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "HardtimeViolation",
          callback = function(ev)
            local key = ev.data and ev.data.key or "unknown"
            record_violation(key)
          end,
        })
  
        -- Show daily report on VimLeave if violations occurred
        vim.api.nvim_create_autocmd("VimLeave", {
          group    = aug,
          callback = function()
            if VIOLATIONS.count > 0 and vim.g.ash_hardtime_report_on_exit then
              show_violation_report()
            end
          end,
        })
  
        -- ASH hot-reload: no highlights to manage; just re-enable
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            -- Brief disable/enable to pick up any filetype changes
            local ht = require("hardtime")
            if _hardtime_enabled then
              ht.disable()
              vim.defer_fn(ht.enable, 100)
            end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🏋️  Hardtime loaded — max_count: " .. opts.max_count,
            vim.log.levels.DEBUG,
            { title = "ASH Hardtime" }
          )
        end
      end,
    },
  }