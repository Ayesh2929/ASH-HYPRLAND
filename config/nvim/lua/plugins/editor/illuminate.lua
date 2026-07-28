-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       💡 VIM-ILLUMINATE — ULTRA REFERENCE HIGHLIGHTER v5.0 OMEGA               ║
-- ║   Treesitter · LSP · regex fallback · smart delay · per-filetype control       ║
-- ║   cursor-word emphasis · animated fade-in · ASH theme-synced highlights        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — three-layer illumination system
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Layer 1: Word under cursor (current) ──────────────────────────────────
    -- This is the exact word the cursor sits on
    hl(0, "IlluminatedWordText",  {
      bold      = false,
      underline = true,
      sp        = "#7aa2f7",     -- underline colour
    })
  
    -- ── Layer 2: Read references ──────────────────────────────────────────────
    -- Other locations where the symbol is read
    hl(0, "IlluminatedWordRead",  {
      bold      = false,
      bg        = "#1e2030",     -- subtle tinted background
      underline = false,
    })
  
    -- ── Layer 3: Write references ─────────────────────────────────────────────
    -- Locations where the symbol is written/modified
    hl(0, "IlluminatedWordWrite", {
      bold      = false,
      bg        = "#2d1b18",     -- reddish tint for write refs
      underline = false,
    })
  
    -- ── Fallback groups (for plugins that use the old group names) ────────────
    hl(0, "illuminatedWord",         { link = "IlluminatedWordText"  })
    hl(0, "illuminatedCurWord",      { link = "IlluminatedWordText"  })
    hl(0, "illuminatedWordCurWord",  { link = "IlluminatedWordText"  })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      -- Underline colour tracks the accent blue
      if p.blue then
        hl(0, "IlluminatedWordText", { underline = true, sp = p.blue })
      end
      -- Read background: subtle surface tint
      local read_bg = p.surface1 or p.overlay0 or "#1e2030"
      hl(0, "IlluminatedWordRead",  { bg = read_bg })
      -- Write background: subtle red/peach tint
      local write_bg
      if p.red then
        -- Darken the red for a subtle background
        write_bg = "#2d1b18"
      end
      if write_bg then
        hl(0, "IlluminatedWordWrite", { bg = write_bg })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📋 FILETYPES — exclusion list
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local DISABLED_FILETYPES = {
    -- UI / dashboards
    "alpha",
    "dashboard",
    "starter",
    "snacks_dashboard",
  
    -- File explorers
    "neo-tree",
    "NvimTree",
    "oil",
    "minifiles",
    "yazi",
  
    -- Git
    "fugitive",
    "fugitiveblame",
    "gitcommit",
    "NeogitStatus",
    "NeogitCommitMessage",
    "Diffview*",
  
    -- Diagnostics / lists
    "Trouble",
    "trouble",
    "qf",
    "quickfix",
    "loclist",
  
    -- Fuzzy finders
    "TelescopePrompt",
    "TelescopeResults",
    "fzf",
  
    -- Help / docs
    "help",
    "man",
  
    -- Plugins
    "lazy",
    "mason",
    "notify",
    "noice",
    "Noice",
    "toggleterm",
    "terminal",
    "spectre_panel",
    "undotree",
  
    -- Note-taking / markup
    "markdown",
    "text",
    "txt",
    "org",
    "neorg",
  
    -- Special
    "checkhealth",
    "lspinfo",
    "DressingInput",
    "DressingSelect",
    "codecompanion",
    "avante",
    "AvanteInput",
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART ACTIONS — illuminate-aware navigation
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Jump to next reference of word under cursor
  local function next_reference()
    require("illuminate").goto_next_reference(false)
  end
  
  -- Jump to previous reference of word under cursor
  local function prev_reference()
    require("illuminate").goto_prev_reference(false)
  end
  
  -- Toggle illuminate for current buffer
  local function toggle_illuminate()
    local ill = require("illuminate")
    if vim.b.illuminate_paused then
      ill.resume_buf()
      vim.b.illuminate_paused = false
      vim.notify(
        "💡 Illuminate  enabled",
        vim.log.levels.INFO,
        { title = "Illuminate", timeout = 1200 }
      )
    else
      ill.pause_buf()
      vim.b.illuminate_paused = true
      vim.notify(
        "💡 Illuminate  disabled",
        vim.log.levels.INFO,
        { title = "Illuminate", timeout = 1200 }
      )
    end
  end
  
  -- Show count of references to word under cursor
  local function show_reference_count()
    local ill = require("illuminate")
    local ref  = ill.get_refs()
    if not ref or #ref == 0 then
      vim.notify(
        "💡 No references found for word under cursor",
        vim.log.levels.WARN,
        { title = "Illuminate" }
      )
      return
    end
    vim.notify(
      string.format("💡 %d reference(s) to '%s'", #ref, vim.fn.expand("<cword>")),
      vim.log.levels.INFO,
      { title = "Illuminate" }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "RRethy/vim-illuminate",
      event = { "BufReadPre", "BufNewFile" },
  
      keys = {
        {
          "]]",
          next_reference,
          desc   = "💡 Next Reference",
          mode   = { "n", "x" },
          silent = true,
        },
        {
          "[[",
          prev_reference,
          desc   = "💡 Prev Reference",
          mode   = { "n", "x" },
          silent = true,
        },
        {
          "<leader>ui",
          toggle_illuminate,
          desc   = "💡 Toggle Illuminate",
          mode   = "n",
          silent = true,
        },
        {
          "<leader>uI",
          show_reference_count,
          desc   = "💡 Reference Count",
          mode   = "n",
          silent = true,
        },
      },
  
      opts = {
        -- ── Providers ─────────────────────────────────────────────────────────
        -- Priority order: LSP → Treesitter → regex fallback
        providers = {
          "lsp",
          "treesitter",
          "regex",
        },
  
        -- ── Delay ─────────────────────────────────────────────────────────────
        -- Time (ms) before highlighting references after cursor stops moving
        delay = 200,
  
        -- ── Filetypes ────────────────────────────────────────────────────────
        filetypes_denylist = DISABLED_FILETYPES,
  
        -- ── Buffer types ─────────────────────────────────────────────────────
        filetypes_allowlist = {},
  
        -- ── Modes ────────────────────────────────────────────────────────────
        -- Only highlight in these modes
        modes_denylist    = { "v", "vs", "V", "Vs", "<C-V>", "<C-Vs>" },
        modes_allowlist   = {},
  
        -- ── Provider timing ───────────────────────────────────────────────────
        providers_regex_syntax_denylist  = {},
        providers_regex_syntax_allowlist = {},
  
        -- ── Under cursor threshold ─────────────────────────────────────────────
        -- Minimum number of chars in word to trigger highlight
        under_cursor     = true,
  
        -- ── Large file threshold ──────────────────────────────────────────────
        -- Disable for files with more than N lines (performance)
        large_file_cutoff = 5000,
        large_file_overrides = {
          -- Still use regex on large files (fastest provider)
          providers = { "regex" },
          delay     = 500,
        },
  
        -- ── Minimum word length ────────────────────────────────────────────────
        min_count_to_highlight = 1,
  
        -- ── Case sensitivity ──────────────────────────────────────────────────
        case_insensitive_regex = false,
  
        -- ── Should highlight ─────────────────────────────────────────────────
        should_enable = function(bufnr)
          -- Extra dynamic check: disable in read-only / special buffers
          if vim.bo[bufnr].readonly then return false end
          if vim.bo[bufnr].buftype ~= "" then return false end
          -- Disable for very large files
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          return line_count < 50000
        end,
      },
  
      config = function(_, opts)
        local illuminate = require("illuminate")
        illuminate.configure(opts)
  
        setup_highlights()
  
        -- ── Textobjects: move between references ────────────────────────────
        -- These are also registered in keys[] above, but we set them here
        -- so that whichever loads first wins
        local function map(lhs, rhs, desc2)
          vim.keymap.set({ "n", "x", "o" }, lhs, rhs, {
            desc   = "💡 " .. desc2,
            silent = true,
          })
        end
  
        map("]]", next_reference, "Next reference")
        map("[[", prev_reference, "Prev reference")
  
        -- ── Autocmds ────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshIlluminate", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Force re-illuminate all loaded buffers with new colours
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_loaded(bufnr) then
                illuminate.refresh_buf(bufnr)
              end
            end
            vim.notify(
              "💡 Illuminate highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Illuminate", timeout = 1200 }
            )
          end,
        })
  
        -- Disable inside large files automatically
        vim.api.nvim_create_autocmd("BufReadPost", {
          group    = aug,
          callback = function(ev)
            if vim.api.nvim_buf_line_count(ev.buf) > 50000 then
              illuminate.pause_buf()
              vim.notify(
                "💡 Illuminate disabled (file too large)",
                vim.log.levels.DEBUG,
                { title = "Illuminate", timeout = 1500 }
              )
            end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "💡 Illuminate loaded — providers: lsp → treesitter → regex",
            vim.log.levels.DEBUG,
            { title = "ASH Illuminate" }
          )
        end
      end,
    },
  }