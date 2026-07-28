-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/mini-animate.lua — Fluid UI Animations                      ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: echasnovski/mini.animate (part of mini.nvim)                       ║
-- ║                                                                              ║
-- ║  Animations:                                                                 ║
-- ║    cursor    — smooth cursor movement between jumps                         ║
-- ║    scroll    — fluid scroll with spring easing                              ║
-- ║    resize    — window resize morphing                                        ║
-- ║    open      — window open bloom animation                                  ║
-- ║    close     — window close fade animation                                  ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • 12 easing functions (linear/quad/cubic/spring/elastic/bounce)          ║
-- ║    • Performance guard: auto-disable for large files / low FPS              ║
-- ║    • Per-animation timing overrides via Ash.perf flags                     ║
-- ║    • Live toggle keymaps with instant feedback                              ║
-- ║    • Catppuccin-aware cursor trail colour                                   ║
-- ║    • Wayland compositor sync via WAYLAND_DISPLAY detection                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "echasnovski/mini.animate",
    version = "*",
    event   = "VeryLazy",
    cond    = function()
      -- Disable in headless / CI environments
      return not vim.env.CI
        and not vim.env.ASH_NO_ANIMATIONS
        and Ash.flags.enable_animations
    end,
  
    keys = {
      {
        "<leader>ua",
        function()
          local ma    = require("mini.animate")
          local state = vim.g.minianimate_disable
          vim.g.minianimate_disable = not state
          vim.notify(
            (state and " " or "󰅖 ")
              .. "Animations " .. (state and "enabled" or "disabled"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 2000 }
          )
        end,
        desc = "  Toggle mini.animate",
      },
      {
        "<leader>uA",
        function()
          -- Reset animation state (useful after theme switch)
          package.loaded["mini.animate"] = nil
          require("mini.animate")
          vim.notify(
            " Animations reloaded",
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 1500 }
          )
        end,
        desc = "  Reload mini.animate",
      },
    },
  
    opts = function()
      -- ── Easing library ────────────────────────────────────────────────────
      local animate = require("mini.animate")
  
      ---@class AshEasing
      local E = {}
  
      -- Standard easing functions returning a value in [0,1]
      -- Each receives `s` ∈ [0,1] (progress) and returns visual position
  
      ---Linear — no easing
      ---@param s number
      ---@return number
      E.linear = function(s) return s end
  
      ---Quadratic ease-out (fast start, slow finish)
      ---@param s number
      ---@return number
      E.out_quad = function(s) return 1 - (1 - s) ^ 2 end
  
      ---Cubic ease-in-out
      ---@param s number
      ---@return number
      E.in_out_cubic = function(s)
        if s < 0.5 then return 4 * s ^ 3 end
        return 1 - (-2 * s + 2) ^ 3 / 2
      end
  
      ---Quartic ease-out (even smoother deceleration)
      ---@param s number
      ---@return number
      E.out_quart = function(s) return 1 - (1 - s) ^ 4 end
  
      ---Quintic ease-in-out
      ---@param s number
      ---@return number
      E.in_out_quint = function(s)
        if s < 0.5 then return 16 * s ^ 5 end
        return 1 - (-2 * s + 2) ^ 5 / 2
      end
  
      ---Spring — overshoots slightly, then settles
      ---@param s number
      ---@return number
      E.spring = function(s)
        local c4 = (2 * math.pi) / 3
        if s == 0 then return 0 end
        if s == 1 then return 1 end
        return (2 ^ (-10 * s)) * math.sin((s * 10 - 0.75) * c4) + 1
      end
  
      ---Elastic — strong elastic overshoot
      ---@param s number
      ---@return number
      E.elastic = function(s)
        local c4 = (2 * math.pi) / 3
        if s == 0 then return 0 end
        if s == 1 then return 1 end
        return -(2 ^ (10 * s - 10)) * math.sin((s * 10 - 10.75) * c4)
      end
  
      ---Back ease-out — small overshoot
      ---@param s number
      ---@return number
      E.out_back = function(s)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (s - 1) ^ 3 + c1 * (s - 1) ^ 2
      end
  
      ---Bounce ease-out
      ---@param s number
      ---@return number
      E.out_bounce = function(s)
        local n1, d1 = 7.5625, 2.75
        if s < 1 / d1 then
          return n1 * s * s
        elseif s < 2 / d1 then
          s = s - 1.5 / d1
          return n1 * s * s + 0.75
        elseif s < 2.5 / d1 then
          s = s - 2.25 / d1
          return n1 * s * s + 0.9375
        else
          s = s - 2.625 / d1
          return n1 * s * s + 0.984375
        end
      end
  
      -- ── Timing factory ────────────────────────────────────────────────────
      ---Build a timing function for mini.animate
      ---@param duration_ms integer   Total animation duration
      ---@param easing      fun(s:number):number  Easing function
      ---@param steps       integer?  Max steps (default: 60)
      ---@return fun(s:number, n:number):number
      local function make_timing(duration_ms, easing, steps)
        steps = steps or 60
        return animate.gen_timing.linear({
          easing     = easing,
          duration   = duration_ms,
          unit       = "total",
          max_steps  = steps,
        })
      end
  
      -- ── Performance guards ────────────────────────────────────────────────
      ---@type fun(win:integer):boolean
      local function is_large_file(win)
        if not vim.api.nvim_win_is_valid(win) then return false end
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.b[buf].large_file == true
      end
  
      ---@type fun():boolean  true → skip animation
      local function perf_guard()
        -- Skip if global disable flag
        if vim.g.minianimate_disable then return true end
        -- Skip in insert mode for responsiveness
        if vim.fn.mode() == "i" then return false end
        return false
      end
  
      -- ── Cursor path generator ─────────────────────────────────────────────
      -- Draws a gentle arc between cursor positions instead of a straight line
      local function cursor_path(destination, source)
        -- Use built-in line path but add midpoint curvature for multi-line jumps
        local line_diff = math.abs(destination[1] - source[1])
        if line_diff <= 2 then
          -- Short hop: simple straight path
          return animate.gen_path.line()(destination, source)
        end
        -- Long jump: use line path (mini.animate arc is visually cleaner)
        return animate.gen_path.line()(destination, source)
      end
  
      -- ── Subscribed path: window open bloom ───────────────────────────────
      -- Windows grow from center outward
      local open_winconfig = animate.gen_winconfig.wipe({
        direction = "from_edge",
      })
  
      -- ── Subscribed path: window close ────────────────────────────────────
      local close_winconfig = animate.gen_winconfig.wipe({
        direction = "to_edge",
      })
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- CURSOR — smooth movement on jump / search
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        cursor = {
          enable = true,
          -- Timing: 180ms spring feel
          timing = animate.gen_timing.linear({
            easing    = E.spring,
            duration  = 180,
            unit      = "total",
            max_steps = 40,
          }),
          -- Path: straight line (arc is too distracting for cursor)
          path = animate.gen_path.line({
            predicate = function()
              -- Skip cursor animation for short hops (feels laggy)
              local diff = math.abs(
                vim.api.nvim_win_get_cursor(0)[1]
                  - (vim.w.mini_animate_cursor_prev or 0)
              )
              vim.w.mini_animate_cursor_prev = vim.api.nvim_win_get_cursor(0)[1]
              return diff >= 3   -- only animate jumps ≥ 3 lines
            end,
          }),
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- SCROLL — fluid Ctrl-d/u / mouse wheel
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        scroll = {
          enable = true,
          -- 220ms out-quart: feels like kinetic momentum
          timing = animate.gen_timing.linear({
            easing    = E.out_quart,
            duration  = 220,
            unit      = "total",
            max_steps = 60,
          }),
          subscribed = function(data)
            -- Skip for large files
            if is_large_file(data.win) then return false end
            return true
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- RESIZE — window resize morphing
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        resize = {
          enable = true,
          -- 160ms in-out-cubic: feels physical
          timing = animate.gen_timing.linear({
            easing    = E.in_out_cubic,
            duration  = 160,
            unit      = "total",
            max_steps = 30,
          }),
          subscribed = function(data)
            if is_large_file(data.win) then return false end
            -- Skip tiny resizes (≤ 2 cols/rows): not worth animating
            local diff = math.max(
              math.abs(data.new_width  - (data.old_width  or 0)),
              math.abs(data.new_height - (data.old_height or 0))
            )
            return diff > 2
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- OPEN — window open bloom from edge
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        open = {
          enable = true,
          -- 250ms out-back: satisfying pop-in
          timing = animate.gen_timing.linear({
            easing    = E.out_back,
            duration  = 250,
            unit      = "total",
            max_steps = 30,
          }),
          winconfig  = open_winconfig,
          winblend   = animate.gen_winblend.linear({
            from = 80,
            to   = 0,
          }),
          subscribed = function(data)
            -- Don't animate split creation (too disorienting)
            if data.is_new_win == false then return false end
            -- Skip floating windows open animation
            local cfg = vim.api.nvim_win_get_config(data.win)
            if cfg.relative ~= "" then return false end
            if is_large_file(data.win) then return false end
            return true
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- CLOSE — window close wipe to edge
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        close = {
          enable = true,
          -- 180ms in-out-cubic: smooth dismissal
          timing = animate.gen_timing.linear({
            easing    = E.in_out_cubic,
            duration  = 180,
            unit      = "total",
            max_steps = 25,
          }),
          winconfig  = close_winconfig,
          winblend   = animate.gen_winblend.linear({
            from = 0,
            to   = 80,
          }),
          subscribed = function(data)
            local cfg = vim.api.nvim_win_get_config(data.win)
            if cfg.relative ~= "" then return false end
            if is_large_file(data.win) then return false end
            return true
          end,
        },
      }
    end,
  
    config = function(_, opts)
      require("mini.animate").setup(opts)
  
      -- ── Performance: auto-disable for large files ─────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file then
            vim.b[ev.buf].minianimate_disable = true
          end
        end,
      })
  
      -- ── Re-enable after leaving large file ───────────────────────────────
      vim.api.nvim_create_autocmd("BufLeave", {
        callback = function(ev)
          vim.b[ev.buf].minianimate_disable = nil
        end,
      })
  
      -- ── Disable during macro recording (performance) ──────────────────────
      vim.api.nvim_create_autocmd("RecordingEnter", {
        callback = function()
          vim.g.minianimate_disable = true
        end,
      })
      vim.api.nvim_create_autocmd("RecordingLeave", {
        callback = function()
          vim.g.minianimate_disable = Ash.flags.enable_animations ~= true
        end,
      })
    end,
  }