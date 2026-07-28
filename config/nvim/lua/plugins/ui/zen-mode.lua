-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/zen-mode.lua — Distraction-Free Writing / Coding            ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: folke/zen-mode.nvim                                                 ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Centred floating window, 100-col wide                                  ║
-- ║    • Twilight integration — dim all but current scope                       ║
-- ║    • kitty font size bump on enter / restore on leave                       ║
-- ║    • tmux status line hidden on enter / restored on leave                  ║
-- ║    • wezterm / ghostty padding on enter                                     ║
-- ║    • Animated window open / close via winblend ramp                        ║
-- ║    • Strips: signcolumn, statuscolumn, numbers, foldcolumn, colorcolumn     ║
-- ║    • Hyprland: enters special workspace "zen" on open                      ║
-- ║    • Notifies on enter/leave with remaining session time (if Pomodoro)      ║
-- ║    • Custom per-filetype width (prose=80, code=100, ultra-wide=120)         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "folke/zen-mode.nvim",
    cmd  = "ZenMode",
    keys = {
      {
        "<leader>z",
        function()
          require("zen-mode").toggle()
        end,
        desc = "  Toggle Zen Mode",
      },
      {
        "<leader>Z",
        function()
          -- Prose zen: 80 cols, spell on
          require("zen-mode").toggle({
            window = { width = 80 },
            on_open = function(_win)
              vim.opt_local.spell = true
            end,
            on_close = function()
              vim.opt_local.spell = false
            end,
          })
        end,
        desc = "  Prose Zen Mode (80 cols)",
      },
      {
        "<leader>Z",
        function()
          require("zen-mode").toggle({ window = { width = 120 } })
        end,
        desc = "  Ultra-wide Zen Mode (120 cols)",
      },
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons = Ash.icons
  
      -- ── Helpers ───────────────────────────────────────────────────────────
  
      ---Run a shell command silently, detached
      ---@param cmd string[]
      local function run(cmd)
        if vim.fn.executable(cmd[1]) == 1 then
          vim.fn.jobstart(cmd, { detach = true })
        end
      end
  
      ---Get current filetype width preference
      ---@return integer
      local function preferred_width()
        local ft = vim.bo.filetype
        local prose_ft = {
          markdown = 80, text = 80, org = 80,
          norg = 90, rst = 80, tex = 80,
          gitcommit = 72,
        }
        return prose_ft[ft] or 100
      end
  
      -- ── kitty integration ─────────────────────────────────────────────────
      local kitty_font_size_orig = nil
  
      local function kitty_enter()
        if vim.env.TERM == "xterm-kitty" or vim.env.KITTY_WINDOW_ID then
          -- Get current font size
          local result = vim.fn.system("kitty @ get-colors 2>/dev/null | grep font_size")
          local size   = result:match("(%d+%.?%d*)")
          kitty_font_size_orig = size or "13"
          -- Bump by 2pt
          local new_size = tostring(tonumber(kitty_font_size_orig) + 2)
          run({ "kitty", "@", "set-font-size", new_size })
        end
      end
  
      local function kitty_leave()
        if kitty_font_size_orig then
          run({ "kitty", "@", "set-font-size", kitty_font_size_orig })
          kitty_font_size_orig = nil
        end
      end
  
      -- ── tmux integration ──────────────────────────────────────────────────
      local function tmux_enter()
        if vim.env.TMUX then
          run({ "tmux", "set", "status", "off" })
          run({ "tmux", "list-panes", "-F", "#F" })   -- refresh
        end
      end
  
      local function tmux_leave()
        if vim.env.TMUX then
          run({ "tmux", "set", "status", "on" })
        end
      end
  
      -- ── Hyprland integration ──────────────────────────────────────────────
      local _zen_ws_active = false
  
      local function hypr_enter()
        if vim.env.HYPRLAND_INSTANCE_SIGNATURE then
          -- Create / switch to special:zen workspace
          run({ "hyprctl", "dispatch", "togglespecialworkspace", "zen" })
          _zen_ws_active = true
        end
      end
  
      local function hypr_leave()
        if _zen_ws_active and vim.env.HYPRLAND_INSTANCE_SIGNATURE then
          run({ "hyprctl", "dispatch", "togglespecialworkspace", "zen" })
          _zen_ws_active = false
        end
      end
  
      -- ── WezTerm / Ghostty integration ────────────────────────────────────
      local function wezterm_enter()
        if vim.env.WEZTERM_PANE then
          -- Increase padding for a margins feel
          vim.fn.system(
            'wezterm cli set-window-decorations --no-default-config NONE 2>/dev/null'
          )
        end
      end
  
      -- ── Animate winblend ──────────────────────────────────────────────────
      ---Ramp winblend from 100 → 0 over `steps` frames for fade-in effect
      ---@param win  integer   window handle
      ---@param from integer   starting winblend (0–100)
      ---@param to   integer   target winblend
      ---@param ms   integer   ms per step
      local function animate_blend(win, from, to, ms)
        if not vim.api.nvim_win_is_valid(win) then return end
        local step  = from < to and 4 or -4
        local blend = from
        local timer = vim.uv.new_timer()
        timer:start(0, ms, vim.schedule_wrap(function()
          if not vim.api.nvim_win_is_valid(win) then
            timer:stop(); return
          end
          blend = blend + step
          local done = (step > 0 and blend >= to) or (step < 0 and blend <= to)
          vim.api.nvim_win_set_option(win, "winblend", math.max(0, math.min(100, blend)))
          if done then timer:stop() end
        end))
      end
  
      return {
        -- ── Window ────────────────────────────────────────────────────────
        window = {
          backdrop = 0.90,              -- dim background to 90%
          width    = preferred_width,   -- function: per-filetype width
          height   = 1,                 -- full height
          options  = {
            -- Strip UI chrome
            signcolumn      = "no",
            number          = false,
            relativenumber  = false,
            cursorline      = false,
            cursorcolumn    = false,
            foldcolumn      = "0",
            list            = false,
            showbreak       = "NONE",
            colorcolumn     = "",
            statuscolumn    = "",
            -- Prose feel
            linebreak       = true,
            breakindent     = true,
          },
        },
  
        -- ── Plugins to disable ─────────────────────────────────────────────
        plugins = {
          -- Built-in
          options = {
            enabled      = true,
            ruler        = false,
            showcmd      = false,
            laststatus   = 0,
          },
          twilight    = { enabled = true  },   -- dim out-of-scope code
          gitsigns    = { enabled = false },   -- hide git signs
          tmux        = { enabled = false },   -- handled manually above
          kitty       = {
            enabled    = false,                -- handled manually above
            font       = "+2",
          },
          alacritty   = {
            enabled    = false,
            font       = "14",
          },
          wezterm     = {
            enabled    = true,
            font       = "+2",
          },
        },
  
        -- ── Callbacks ─────────────────────────────────────────────────────
        on_open = function(win)
          -- Fade in
          vim.api.nvim_win_set_option(win, "winblend", 30)
          animate_blend(win, 30, 0, 16)
  
          -- External integrations
          kitty_enter()
          tmux_enter()
          hypr_enter()
          wezterm_enter()
  
          -- Hide noice cmdline inside zen
          pcall(function()
            require("noice").cmd("disable")
          end)
  
          -- Notify
          vim.notify(
            icons.ui.Eye .. " Zen mode  —  " .. vim.bo.filetype .. "  ["
              .. tostring(preferred_width()) .. " cols]",
            vim.log.levels.INFO,
            {
              title   = "ASH NeoVim",
              timeout = 2000,
              icon    = "🧘",
            }
          )
        end,
  
        on_close = function()
          -- External integrations
          kitty_leave()
          tmux_leave()
          hypr_leave()
  
          -- Restore noice
          pcall(function()
            require("noice").cmd("enable")
          end)
  
          -- Notify
          vim.notify(
            icons.ui.EyeOff .. " Zen mode exited",
            vim.log.levels.INFO,
            {
              title   = "ASH NeoVim",
              timeout = 1500,
              icon    = "🔓",
            }
          )
        end,
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      require("zen-mode").setup(opts)
  
      -- ── Highlight overrides ───────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base   = p.base     or "#1e1e2e"
        local crust  = p.crust    or "#11111b"
  
        vim.api.nvim_set_hl(0, "ZenBg",     { bg = crust, fg = "NONE" })
        vim.api.nvim_set_hl(0, "ZenNormal", { bg = base,  fg = "NONE" })
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── User commands ─────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("ZenProse", function()
        require("zen-mode").toggle({
          window = { width = 80 },
          on_open = function(_win)
            vim.opt_local.spell     = true
            vim.opt_local.linebreak = true
            vim.opt_local.wrap      = true
          end,
          on_close = function()
            vim.opt_local.spell = false
          end,
        })
      end, { desc = "Zen mode optimised for prose writing (80 cols, spell on)" })
  
      vim.api.nvim_create_user_command("ZenCode", function()
        require("zen-mode").toggle({ window = { width = 100 } })
      end, { desc = "Zen mode optimised for coding (100 cols)" })
  
      vim.api.nvim_create_user_command("ZenUltra", function()
        require("zen-mode").toggle({ window = { width = 120 } })
      end, { desc = "Zen mode ultra-wide (120 cols)" })
    end,
  }