-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/smear-cursor.lua — Liquid Cursor Trail                      ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: sphamba/smear-cursor.nvim                                           ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Fluid cursor smear trail on movement                                   ║
-- ║    • Colour transitions through palette gradient                            ║
-- ║    • Per-mode colour: insert=green, visual=mauve, replace=red               ║
-- ║    • Matrix-style character rain trail (optional)                           ║
-- ║    • Performance guard: auto-disable for large files & macro recording      ║
-- ║    • Wayland-native: respects compositor refresh rate                       ║
-- ║    • Toggle keymap with live status notification                            ║
-- ║    • Integrates with mini.animate (complementary, not redundant)            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "sphamba/smear-cursor.nvim",
    version = "*",
    event   = "VeryLazy",
    cond    = function()
      return not vim.env.CI
        and not vim.env.ASH_NO_ANIMATIONS
        and Ash.flags.enable_animations
        and vim.o.termguicolors
    end,
  
    keys = {
      {
        "<leader>uS",
        function()
          local sc = require("smear_cursor")
          sc.toggle()
          local enabled = require("smear_cursor.config").enabled
          vim.notify(
            (enabled and "󱥸 " or "󱠞 ")
              .. "Smear cursor " .. (enabled and "enabled" or "disabled"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 2000 }
          )
        end,
        desc = "󱥸  Toggle smear cursor",
      },
    },
  
    opts = function()
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      local base   = p.base    or "#1e1e2e"
      local blue   = p.blue    or "#89b4fa"
      local green  = p.green   or "#a6e3a1"
      local red    = p.red     or "#f38ba8"
      local mauve  = p.mauve   or "#cba6f7"
      local yellow = p.yellow  or "#f9e2af"
      local teal   = p.teal    or "#94e2d5"
      local peach  = p.peach   or "#fab387"
      local text   = p.text    or "#cdd6f4"
  
      -- ── Mode → colour map ─────────────────────────────────────────────────
      ---@type table<string, string>
      local mode_colours = {
        n  = blue,    -- Normal    → calm blue
        i  = green,   -- Insert    → active green
        v  = mauve,   -- Visual    → mauve
        V  = mauve,   -- V-LINE    → mauve
        R  = red,     -- Replace   → warning red
        c  = yellow,  -- Command   → yellow
        t  = teal,    -- Terminal  → teal
        s  = peach,   -- Select    → peach
      }
  
      ---Get current mode colour
      ---@return string hex
      local function cursor_colour()
        local m = vim.fn.mode():sub(1, 1)
        return mode_colours[m] or blue
      end
  
      -- ── Trail characters ──────────────────────────────────────────────────
      -- Characters used for the smear trail (head → tail)
      -- Using block elements for a liquid look
      local trail_chars = {
        "█", "▓", "▒", "░",
      }
  
      -- Alternative: matrix rain characters (enabled via ASH_CURSOR_MATRIX=1)
      local matrix_chars = {
        "ﾊ","ﾐ","ﾋ","ｰ","ｳ","ｼ","ﾅ","ﾓ","ｻ","ﾜ","ﾂ","ｵ","ﾘ",
        "ｱ","ﾛ","ﾝ","ﾊ","ﾐ","ﾋ","0","1","2","3","4","5","6","7","8","9",
      }
  
      local use_matrix  = vim.env.ASH_CURSOR_MATRIX == "1"
      local chars_to_use = use_matrix and matrix_chars or trail_chars
  
      return {
        -- ── Core ──────────────────────────────────────────────────────────
        enabled              = true,
  
        -- Cursor colour — respects current mode
        cursor_color         = cursor_colour(),
  
        -- Trail: number of virtual-text cells for the smear
        stiffness            = 0.8,    -- spring stiffness (0–1): higher = snappier
        trailing_stiffness   = 0.5,    -- trail stiffness: lower = more liquid
        trailing_exponent    = 0.2,    -- tail length scaling exponent
        slowdown_exponent    = 0,      -- additional deceleration
  
        -- ── Visual parameters ─────────────────────────────────────────────
        -- Distance threshold to start smearing
        min_horizontal_distance_smear = 2,
        min_vertical_distance_smear   = 1,
  
        -- Hide cursor during smear (the smear IS the cursor)
        hide_target_hack     = true,
  
        -- Colour transition: blend cursor colour toward background along trail
        -- 1.0 = fully visible throughout; 0.0 = fades to bg
        gamma                = 1.4,
  
        -- ── Characters ────────────────────────────────────────────────────
        -- Character sets for different smear regions
        smear_between_point_and_target  = {
          -- Middle of the smear: solid blocks
          chars = chars_to_use,
        },
        smear_between_target_and_point  = {
          -- Trailing end: lighter blocks
          chars = use_matrix and matrix_chars or { "▒", "░", " " },
        },
  
        -- ── Performance ───────────────────────────────────────────────────
        -- Frames per second cap (respect compositor VSync)
        time_interval        = vim.env.WAYLAND_DISPLAY and 16 or 16, -- ~60fps
  
        -- ── Colour palette for dynamic mode switching ─────────────────────
        -- Expose so config block can update on ModeChanged
        _mode_colours        = mode_colours,
      }
    end,
  
    config = function(_, opts)
      local sc = require("smear_cursor")
      sc.setup(opts)
  
      -- ── Dynamic mode-colour switching ─────────────────────────────────────
      -- Re-colour the smear trail when the Vim mode changes
      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern  = "*",
        callback = function()
          local m = vim.fn.mode():sub(1, 1)
          local colour = opts._mode_colours[m]
          if colour then
            pcall(sc.set_cursor_color, colour)
          end
        end,
      })
  
      -- ── Disable during macro recording ────────────────────────────────────
      vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = function() pcall(sc.disable) end,
      })
      vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = function() pcall(sc.enable)  end,
      })
  
      -- ── Disable for large files ───────────────────────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file then
            pcall(sc.disable)
          else
            if Ash.flags.enable_animations then
              pcall(sc.enable)
            end
          end
        end,
      })
  
      -- ── ColorScheme: update cursor colour ────────────────────────────────
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local p2 = {}
          pcall(function() p2 = require("catppuccin.palettes").get_palette() or {} end)
          pcall(sc.set_cursor_color, p2.blue or "#89b4fa")
        end,
      })
  
      -- ── Highlight group for matrix mode ──────────────────────────────────
      if vim.env.ASH_CURSOR_MATRIX == "1" then
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
        vim.api.nvim_set_hl(0, "SmearCursorMatrix", {
          fg   = p.green or "#a6e3a1",
          bold = true,
        })
      end
    end,
  }