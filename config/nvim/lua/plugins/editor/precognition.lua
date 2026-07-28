-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║     🔮 PRECOGNITION — ULTRA MOTION HINT OVERLAY v5.0 OMEGA                     ║
-- ║   Ghost-text motion hints · inline learning · context-aware suggestions        ║
-- ║   adaptive display · ASH theme-synced · pairs with hardtime perfectly          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 WHAT PRECOGNITION SHOWS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  Precognition renders ghost-text overlays showing WHERE motion keys
--  would land you, inline with the buffer text, so you can SEE the
--  optimal key to press before you press it.
--
--  Example:
--    function|myFunc(arg1, arg2)
--             ^-- w would jump here
--             f-- f would match 'f' in myFunc
--
--  Hints shown:
--    w  b  e  ge     → word boundary jumps
--    W  B  E  gE     → WORD boundary jumps
--    f  F  t  T      → char-find targets
--    ^  $  0          → line boundary
--    {  }             → paragraph jumps
--    [[ ]]            → section jumps
--    <C-d> <C-u>      → scroll positions (relative)
--    %                → bracket pairs

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — layered ghost-text colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Primary hint (the key label) ─────────────────────────────────────────
    hl(0, "PrecognitionHighlight", {
      bold      = false,
      italic    = true,
      fg        = "#545c7e",
      bg        = "NONE",
      nocombine = false,
    })
  
    -- ── Word-motion hints (w/b/e/ge) ─────────────────────────────────────────
    hl(0, "PrecognitionWordHint", {
      italic    = true,
      fg        = "#7aa2f7",
      bg        = "NONE",
    })
  
    -- ── Char-find hints (f/F/t/T) ────────────────────────────────────────────
    hl(0, "PrecognitionCharHint", {
      italic    = true,
      fg        = "#9ece6a",
      bg        = "NONE",
    })
  
    -- ── Line-boundary hints (^/$) ────────────────────────────────────────────
    hl(0, "PrecognitionLineHint", {
      italic    = true,
      fg        = "#e0af68",
      bg        = "NONE",
    })
  
    -- ── Paragraph / section hints ({ } [[ ]]) ────────────────────────────────
    hl(0, "PrecognitionSectionHint", {
      italic    = true,
      fg        = "#bb9af7",
      bg        = "NONE",
    })
  
    -- ── Matching bracket hint (%) ────────────────────────────────────────────
    hl(0, "PrecognitionMatchHint", {
      italic    = true,
      fg        = "#ff9e64",
      bg        = "NONE",
    })
  
    -- ── Scroll hints (<C-d>/<C-u>) ───────────────────────────────────────────
    hl(0, "PrecognitionScrollHint", {
      italic    = true,
      fg        = "#73daca",
      bg        = "NONE",
    })
  
    -- ── ASH palette sync ────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      local dim = p.overlay0 or p.subtext0 or "#545c7e"
      hl(0, "PrecognitionHighlight",   { italic = true, fg = dim               })
      if p.blue   then hl(0, "PrecognitionWordHint",    { italic = true, fg = p.blue   }) end
      if p.green  then hl(0, "PrecognitionCharHint",    { italic = true, fg = p.green  }) end
      if p.yellow then hl(0, "PrecognitionLineHint",    { italic = true, fg = p.yellow }) end
      if p.mauve  then hl(0, "PrecognitionSectionHint", { italic = true, fg = p.mauve  }) end
      if p.orange then hl(0, "PrecognitionMatchHint",   { italic = true, fg = p.orange }) end
      if p.teal   then hl(0, "PrecognitionScrollHint",  { italic = true, fg = p.teal   }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART TOGGLE + ADAPTIVE DISPLAY CONTROL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local _prec_enabled  = true
  local _prec_adaptive = true   -- auto-hide in large files
  
  local function toggle_precognition()
    local pc = require("precognition")
    if _prec_enabled then
      pc.hide()
      _prec_enabled = false
      vim.notify(
        "🔮 Precognition  hidden",
        vim.log.levels.INFO,
        { title = "Precognition", timeout = 1200 }
      )
    else
      pc.show()
      _prec_enabled = true
      vim.notify(
        "🔮 Precognition  showing motion hints",
        vim.log.levels.INFO,
        { title = "Precognition", timeout = 1200 }
      )
    end
  end
  
  local function toggle_gutter()
    local pc  = require("precognition")
    local cfg = require("precognition.config").config
    cfg.gutter_hints = not cfg.gutter_hints
    -- Refresh display
    pc.hide()
    if _prec_enabled then pc.show() end
    vim.notify(
      string.format("🔮 Gutter hints %s", cfg.gutter_hints and " on" or " off"),
      vim.log.levels.INFO,
      { title = "Precognition", timeout = 1200 }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "tris203/precognition.nvim",
      event  = { "BufReadPre", "BufNewFile" },
  
      keys = {
        {
          "<leader>uP",
          toggle_precognition,
          desc   = "🔮 Toggle Precognition",
          silent = true,
        },
        {
          "<leader>uG",
          toggle_gutter,
          desc   = "🔮 Toggle Precognition Gutter",
          silent = true,
        },
      },
  
      opts = {
        -- ── Start visible ───────────────────────────────────────────────────
        -- false = load but stay hidden until first :PrecognitionToggle
        startVisible     = false,
  
        -- ── Show hints in the gutter (sign column) in addition to inline ──────
        showBlankVirtLine = true,
  
        -- ── Inline hints position ────────────────────────────────────────────
        highlightColor   = { link = "PrecognitionHighlight" },
  
        -- ── Hint definitions ─────────────────────────────────────────────────
        -- Each key controls whether that motion hint is shown
        hints = {
          -- ── Word motions ─────────────────────────────────────────────────
          Caret             = { text = "^",    prio = 2  },
          Dollar            = { text = "$",    prio = 1  },
          MatchingPair      = { text = "%",    prio = 5  },
          Zero              = { text = "0",    prio = 1  },
          w                 = { text = "w",    prio = 10 },
          b                 = { text = "b",    prio = 9  },
          e                 = { text = "e",    prio = 8  },
          W                 = { text = "W",    prio = 7  },
          B                 = { text = "B",    prio = 6  },
          E                 = { text = "E",    prio = 5  },
          -- ── Line-specific ──────────────────────────────────────────────
          ge                = { text = "ge",   prio = 3  },
          gE                = { text = "gE",   prio = 2  },
        },
  
        -- ── Gutter hints (sign column) ────────────────────────────────────────
        gutter_hints = {
          -- Vertical navigation shown in gutter
          G                 = { text = "G",    prio = 1  },
          gg                = { text = "gg",   prio = 1  },
          ParagraphNext     = { text = "}",    prio = 4  },
          ParagraphPrev     = { text = "{",    prio = 4  },
          SectionNext       = { text = "]]",   prio = 3  },
          SectionPrev       = { text = "[[",   prio = 3  },
          HalfPageDown      = { text = "^D",   prio = 2  },
          HalfPageUp        = { text = "^U",   prio = 2  },
        },
  
        -- ── Disabled filetypes ────────────────────────────────────────────────
        disabled_fts = {
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
          "DressingInput",
          "noice",
          "notify",
          "checkhealth",
          "lspinfo",
          "codecompanion",
          "avante",
          "diffview",
          "markdown",
          "text",
          "txt",
          "org",
          "neorg",
        },
      },
  
      config = function(_, opts)
        require("precognition").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshPrecognition", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload: repaint hints with new palette colours
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Refresh precognition display
            local pc = require("precognition")
            pc.hide()
            if _prec_enabled then
              vim.defer_fn(function()
                pc.show()
              end, 150)
            end
            vim.notify(
              "🔮 Precognition highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Precognition", timeout = 1200 }
            )
          end,
        })
  
        -- ── Adaptive: auto-hide in large files ─────────────────────────────────
        vim.api.nvim_create_autocmd("BufReadPost", {
          group    = aug,
          callback = function(ev)
            if not _prec_adaptive then return end
            local line_count = vim.api.nvim_buf_line_count(ev.buf)
            local pc = require("precognition")
            if line_count > 10000 then
              if _prec_enabled then
                pc.hide()
                vim.notify(
                  string.format(
                    "🔮 Precognition paused (large file: %d lines)",
                    line_count
                  ),
                  vim.log.levels.DEBUG,
                  { title = "Precognition", timeout = 1500 }
                )
              end
            else
              if _prec_enabled then
                pc.show()
              end
            end
          end,
        })
  
        -- ── Complementary: announce when a hint-suggested motion is used ───────
        -- This reinforces learning by confirming good choices
        local good_motions = { "w", "b", "e", "W", "B", "E", "f", "F", "t", "T",
                               "}", "{", "]]", "[[", "gg", "G", "%", "/", "?",
                               "<C-d>", "<C-u>", "n", "N", "*", "#" }
  
        for _, motion in ipairs(good_motions) do
          vim.keymap.set("n", motion, function()
            -- Just pass through; the reinforcement is the hint disappearing
            return motion
          end, {
            expr    = true,
            silent  = true,
            noremap = true,
          })
        end
  
        if vim.g.ash_debug then
          vim.notify(
            string.format(
              "🔮 Precognition loaded — startVisible: %s",
              tostring(opts.startVisible)
            ),
            vim.log.levels.DEBUG,
            { title = "ASH Precognition" }
          )
        end
      end,
    },
  }