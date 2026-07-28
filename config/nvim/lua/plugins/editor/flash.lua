-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ⚡ FLASH.NVIM — ULTRA MOTION ENGINE v5.0 OMEGA                            ║
-- ║   Sub-word jumping · Treesitter node selection · remote operations               ║
-- ║   Incremental search enhancement · label persistence · ASH theme-aware          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 OPERATION REFERENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  JUMP          s{char}{char}    2-char jump anywhere on screen
--  JUMP BACK     S{char}{char}    reverse jump
--  TREESITTER    <C-s>            select enclosing TS node (visual/operator)
--  REMOTE        r{motion}        perform remote operation (e.g. yr3j → yank 3 lines)
--  REMOTE TS     R                remote treesitter select
--  ENHANCED /    /                slash-search with flash labels overlay
--  ENHANCED ?    ?                reverse search with flash labels overlay
--  CHAR          f/F/t/T          enhanced char motions with labels
--
--  LABEL CHARS   home row optimised: asdfghjklqwertyuiopzxcvbnm
--  MULTI-WINDOW  labels span ALL visible windows simultaneously

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT PALETTE — ASH theme-synced colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Primary label: bright accent (home-row char on target)
    hl(0, "FlashLabel", {
      bold      = true,
      italic    = false,
      fg        = "#ff007c",   -- hot-pink — overridden by ASH palette below
      bg        = "#1a1a2e",
    })
  
    -- Current match (the text being searched)
    hl(0, "FlashMatch", {
      bold      = false,
      fg        = "#c0caf5",
      bg        = "#3b4261",
    })
  
    -- Already-typed search chars
    hl(0, "FlashCurrent", {
      bold      = true,
      fg        = "#7aa2f7",
      bg        = "#3d59a1",
    })
  
    -- Background-dimmed non-matching text
    hl(0, "FlashBackdrop", {
      fg        = "#545c7e",
    })
  
    -- Prompt at the bottom
    hl(0, "FlashPrompt", {
      bold      = true,
      link      = "MsgArea",
    })
  
    -- Prompt icon
    hl(0, "FlashPromptIcon", {
      bold      = true,
      fg        = "#ff9e64",
    })
  
    -- Treesitter node highlight
    hl(0, "FlashTreesitter", {
      bold      = true,
      italic    = true,
      fg        = "#9ece6a",
      bg        = "#1a2b1a",
    })
  
    -- Remote operation target
    hl(0, "FlashRemote", {
      bold      = true,
      fg        = "#e0af68",
      bg        = "#2b2010",
    })
  
    -- ── Dynamically sync with ASH active palette ──────────────────────────────
    -- Read ASH colour vars if available
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.accent then
        hl(0, "FlashLabel", { bold = true, fg = p.accent, bg = p.surface0 or "#1a1a2e" })
      end
      if p.blue then
        hl(0, "FlashCurrent", { bold = true, fg = p.blue, bg = p.overlay0 or "#3d59a1" })
      end
      if p.green then
        hl(0, "FlashTreesitter", { bold = true, italic = true, fg = p.green })
      end
      if p.yellow then
        hl(0, "FlashRemote", { bold = true, fg = p.yellow })
      end
      if p.subtext0 then
        hl(0, "FlashBackdrop", { fg = p.subtext0 })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 CUSTOM MODES — reusable configuration presets
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Word-boundary-only jump (useful for code navigation)
  local MODE_WORD = {
    search    = { mode = "fuzzy" },
    highlight = { backdrop = false },
    jump      = { pos = "start" },
    label     = { after = false, before = { 0, 0 }, uppercase = false },
    pattern   = [[\b]],
  }
  
  -- Line-start jump (like EasyMotion line mode)
  local MODE_LINE = {
    search = {
      mode   = "search",
      max_length = 0,
    },
    label  = {
      after     = { 0, 0 },
      before    = false,
      uppercase = false,
      reuse     = "all",
    },
    highlight = { backdrop = false },
    pattern   = "^",
  }
  
  -- Diagnostics jump — jump to diagnostic signs in buffer
  local MODE_DIAG = {
    matcher = function(win)
      ---@param diag vim.Diagnostic
      return vim.tbl_map(function(diag)
        return {
          pos   = { diag.lnum + 1, diag.col },
          end_pos = { diag.end_lnum + 1, diag.end_col - 1 },
        }
      end, vim.diagnostic.get(vim.api.nvim_win_get_buf(win)))
    end,
    action = nil,
  }
  
  -- URL jump — flash over all URLs visible in the window
  local MODE_URL = {
    matcher = function(win)
      local results = {}
      local buf     = vim.api.nvim_win_get_buf(win)
      local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local url_pat = "https?://[^%s%)%]%}>\"']+"
      for lnum, line in ipairs(lines) do
        local s, e = 0, 0
        while true do
          s, e = line:find(url_pat, e + 1)
          if not s then break end
          table.insert(results, {
            pos     = { lnum, s - 1 },
            end_pos = { lnum, e - 1 },
          })
        end
      end
      return results
    end,
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  ACTION HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function flash_jump()        require("flash").jump()                    end
  local function flash_treesitter()  require("flash").treesitter()              end
  local function flash_remote()      require("flash").remote()                  end
  local function flash_ts_search()   require("flash").treesitter_search()       end
  local function flash_toggle()      require("flash").toggle()                  end
  
  local function flash_word()
    require("flash").jump({ mode = "word", search = { mode = "fuzzy" } })
  end
  
  local function flash_line()
    require("flash").jump(MODE_LINE)
  end
  
  local function flash_diag()
    require("flash").jump(MODE_DIAG)
  end
  
  local function flash_url()
    require("flash").jump(MODE_URL)
  end
  
  -- Jump to a specific line number with labels
  local function flash_linenum()
    require("flash").jump({
      search  = { mode = "search", max_length = 0 },
      pattern = "^",
      label   = { after = { 0, 0 } },
      action  = function(match, state)
        state:hide()
        vim.api.nvim_win_set_cursor(match.win, match.pos)
      end,
    })
  end
  
  -- Yank remote: press yr then a motion to yank from anywhere on screen
  local function flash_yank_remote()
    require("flash").remote({
      action = function(match, _state)
        vim.api.nvim_win_call(match.win, function()
          vim.api.nvim_win_set_cursor(match.win, match.pos)
          vim.cmd("normal! yiw")
        end)
      end,
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "folke/flash.nvim",
      event = "VeryLazy",
  
      ---@type Flash.Config
      opts = {
  
        -- ── Search engine ───────────────────────────────────────────────────────
        search = {
          -- Search across ALL open windows
          multi_window    = true,
          -- Forward direction by default
          forward         = true,
          -- Wrap around end of buffer
          wrap            = true,
          -- "exact" | "search" | "fuzzy" | fun(pattern)
          mode            = "exact",
          -- Include current position in results
          incremental     = false,
          -- Filetype-exclusion list
          exclude         = {
            "notify", "cmp_menu", "noice", "flash_prompt",
            "alpha", "dashboard", "neo-tree", "Trouble",
            "telescope", "fzf", "lazy", "mason",
            function(win)
              -- Exclude non-focusable or special windows
              return not vim.api.nvim_win_get_config(win).focusable
            end,
          },
          -- Trigger search on these characters
          trigger         = "",
          -- Max pattern length before search stops updating
          max_length      = false,
        },
  
        -- ── Jump behaviour ─────────────────────────────────────────────────────
        jump = {
          -- Jump immediately if only one match
          jumplist        = true,
          -- Position cursor at: "start" | "end" | "range"
          pos             = "start",
          -- Set history marks
          history         = false,
          -- Register jump in jump list
          register        = false,
          -- Don't break undo sequence
          nohlsearch      = false,
          -- Automatically jump if single match
          autojump        = false,
          -- Inclusive motion (for operator-pending)
          inclusive       = nil,
          -- Offset after jump: 0 = exact, -1 = before
          offset          = nil,
        },
  
        -- ── Label rendering ────────────────────────────────────────────────────
        label = {
          -- Uppercase labels (mixed case → more distinct)
          uppercase       = true,
          -- Label position: after/before the match, or false to disable
          after           = true,
          before          = false,
          -- Style: "eol" | "overlay" | "right_align" | "inline"
          style           = "overlay",
          -- Reuse labels across windows: "lowercase" | "all" | false
          reuse           = "lowercase",
          -- Labels are case-insensitive
          distance        = true,
          -- Minimum label characters to show
          min_jump_dist   = 2,
          -- Rainbow-colour labels (hue shift per label)
          rainbow         = {
            enabled = true,
            shade   = 5,
          },
          -- Format label text
          format          = function(opts2)
            return { { opts2.match.label, opts2.hl_group } }
          end,
        },
  
        -- ── Highlight settings ─────────────────────────────────────────────────
        highlight = {
          -- Dim non-matching text
          backdrop        = true,
          -- Highlight matched text
          matches         = true,
          -- Highlight priority
          priority        = 5000,
          -- Group overrides (managed by setup_highlights())
          groups          = {
            match         = "FlashMatch",
            current       = "FlashCurrent",
            backdrop      = "FlashBackdrop",
            label         = "FlashLabel",
          },
        },
  
        -- ── Action after jump ──────────────────────────────────────────────────
        action           = nil,
  
        -- ── Pattern matchers ───────────────────────────────────────────────────
        pattern          = "",
  
        -- ── Continue key (press again after landing to keep jumping) ──────────
        continue         = false,
  
        -- ── Config per mode (search / char / treesitter / remote …) ───────────
        modes = {
          -- Enhanced / and ? search
          search = {
            enabled       = true,
            highlight     = { backdrop = false },
            jump          = { history = true, register = true, nohlsearch = true },
            search = {
              -- Forward for / backward for ?
              mode        = "search",
              incremental = true,
            },
          },
  
          -- Enhanced f / F / t / T char motions
          char = {
            enabled       = true,
            -- Keys that activate char mode
            keys          = { "f", "F", "t", "T", ";", "," },
            search        = { wrap = false },
            highlight     = { backdrop = true },
            jump          = { register = false },
            -- Only show label when there are multiple matches
            label         = {
              exclude = "hjkliardc",   -- don't label these chars (too ambiguous)
              after   = true,
              before  = false,
            },
            -- Char jump across ALL windows
            multi_line    = true,
            -- After how many chars to switch to jump-to-any mode
            jump_labels   = false,
            autohide      = false,
            -- Cycle through matches on repeat
            char_actions  = function(motion)
              return {
                [";"] = "next",
                [","] = "prev",
              }
            end,
          },
  
          -- Treesitter incremental selection
          treesitter = {
            labels        = "abcdefghijklmnopqrstuvwxyz",
            jump          = { pos = "range", autojump = true },
            search        = { incremental = false },
            label         = {
              before    = true,
              after     = true,
              style     = "inline",
              reuse     = "all",
              rainbow   = { enabled = true, shade = 3 },
            },
            highlight     = {
              backdrop  = false,
              matches   = false,
            },
          },
  
          -- Treesitter search (for use in operator-pending)
          treesitter_search = {
            jump          = { pos = "range" },
            search        = { multi_window = true, wrap = true, incremental = false },
            remote_op     = { restore = true, motion = true },
            label         = { before = true, after = true, style = "inline" },
          },
  
          -- Remote operations (yr, yd, etc.)
          remote = {
            remote_op     = { restore = true, motion = true },
          },
        },
  
        -- ── Remote operations ──────────────────────────────────────────────────
        remote_op = {
          restore         = true,
          motion          = false,
        },
  
        -- ── Labels string ─────────────────────────────────────────────────────
        -- Home-row biased: most-used positions first
        labels = "asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM",
  
        -- ── Prompt ────────────────────────────────────────────────────────────
        prompt = {
          enabled         = true,
          prefix          = { { "⚡", "FlashPromptIcon" }, { " Flash", "FlashPrompt" } },
          win_config      = { relative = "editor", width = 1, height = 1, row = -1, col = 0, zindex = 1000 },
        },
      },
  
      -- ── Keymaps ──────────────────────────────────────────────────────────────
      keys = {
        -- ── Primary jump ─────────────────────────────────────────────────────
        {
          "s",
          flash_jump,
          mode  = { "n", "x", "o" },
          desc  = "⚡ Flash Jump",
        },
        {
          "S",
          flash_treesitter,
          mode  = { "n", "x", "o" },
          desc  = "⚡ Flash Treesitter",
        },
  
        -- ── Remote operations ─────────────────────────────────────────────────
        {
          "r",
          flash_remote,
          mode  = "o",
          desc  = "⚡ Flash Remote",
        },
        {
          "R",
          flash_ts_search,
          mode  = { "o", "x" },
          desc  = "⚡ Flash Treesitter Search",
        },
  
        -- ── Search integration (toggle labels in / ?) ─────────────────────────
        {
          "<C-s>",
          flash_toggle,
          mode  = "c",
          desc  = "⚡ Flash Toggle Search",
        },
  
        -- ── Extra motions ─────────────────────────────────────────────────────
        {
          "<leader>jw",
          flash_word,
          mode  = { "n", "x", "o" },
          desc  = "⚡ Flash Word Jump",
        },
        {
          "<leader>jl",
          flash_line,
          mode  = { "n", "x", "o" },
          desc  = "⚡ Flash Line Jump",
        },
        {
          "<leader>jn",
          flash_linenum,
          mode  = { "n", "x", "o" },
          desc  = "⚡ Flash Line Number",
        },
        {
          "<leader>jd",
          flash_diag,
          mode  = { "n" },
          desc  = "⚡ Flash Diagnostic",
        },
        {
          "<leader>ju",
          flash_url,
          mode  = { "n" },
          desc  = "⚡ Flash URL",
        },
        {
          "<leader>jy",
          flash_yank_remote,
          mode  = { "n" },
          desc  = "⚡ Flash Yank Remote Word",
        },
  
        -- ── Telescope integration: <C-s> to flash inside picker ───────────────
        -- (registered in telescope.lua; listed here for which-key discovery)
        {
          "<leader>js",
          function()
            require("flash").jump({
              search = { mode = "search", incremental = true },
            })
          end,
          mode  = { "n" },
          desc  = "⚡ Flash Incremental Search",
        },
      },
  
      -- ── Config ───────────────────────────────────────────────────────────────
      config = function(_, opts)
        require("flash").setup(opts)
  
        -- Apply ASH-synced highlights
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshFlash", { clear = true })
  
        -- Re-sync highlights on every colorscheme change
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload event
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Flash a quick demo jump to show the new colours
            vim.defer_fn(function()
              vim.notify(
                "⚡ Flash highlights updated for new ASH theme",
                vim.log.levels.INFO,
                { title = "ASH Flash", timeout = 1500 }
              )
            end, 200)
          end,
        })
  
        -- ── Telescope integration hook ─────────────────────────────────────────
        -- Pressing <C-s> inside any Telescope picker fires flash over results
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "TelescopeResults",
          callback = function(ev)
            vim.keymap.set({ "i", "n" }, "<C-s>",
              function() require("flash").jump({ pos = "start", search = { multi_window = false } }) end,
              { buffer = ev.buf, desc = "⚡ Flash in Telescope", silent = true }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("⚡ Flash.nvim loaded", vim.log.levels.DEBUG, { title = "ASH Flash" })
        end
      end,
    },
  }