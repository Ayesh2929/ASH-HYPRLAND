-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔍 GLANCE.NVIM — ULTRA PEEK WINDOW v5.0 OMEGA                            ║
-- ║   Peek definitions · references · implementations · type-defs                  ║
-- ║   split preview · jump list · filter · ASH theme-synced glass UI               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — glassmorphism-inspired
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── List panel ────────────────────────────────────────────────────────────
    hl(0, "GlanceListNormal",           { link = "NormalFloat"                 })
    hl(0, "GlanceListBorderBottom",     { link = "FloatBorder"                 })
    hl(0, "GlanceListCursorLine",       { link = "CursorLine"                  })
    hl(0, "GlanceListMatch",            {
      bold      = true,
      fg        = "#7aa2f7",
      bg        = "#1e2d4a",
    })
    hl(0, "GlanceListFilename",         { bold = true, link = "Directory"      })
    hl(0, "GlanceListFilepath",         { italic = true, link = "Comment"      })
    hl(0, "GlanceListCount",            { bold = true, fg = "#7dcfff"          })
  
    -- ── Preview panel ─────────────────────────────────────────────────────────
    hl(0, "GlancePreviewNormal",        { link = "Normal"                      })
    hl(0, "GlancePreviewBorderBottom",  { link = "FloatBorder"                 })
    hl(0, "GlancePreviewCursorLine",    { link = "CursorLine"                  })
    hl(0, "GlancePreviewMatch",         {
      bold      = true,
      underline = true,
      fg        = "#ff9e64",
      bg        = "#2b1d0e",
    })
    hl(0, "GlancePreviewLineNr",        { link = "LineNr"                      })
    hl(0, "GlancePreviewSignColumn",    { link = "SignColumn"                  })
  
    -- ── Border / chrome ───────────────────────────────────────────────────────
    hl(0, "GlanceBorderTop",            { link = "FloatBorder"                 })
    hl(0, "GlanceWinSeparator",         { link = "WinSeparator"                })
  
    -- ── Fold indicators ───────────────────────────────────────────────────────
    hl(0, "GlanceFoldIcon",             { fg = "#9399b2"                       })
    hl(0, "GlanceIndent",               { fg = "#313244"                       })
  
    -- ── Header / title ────────────────────────────────────────────────────────
    hl(0, "GlanceListBorderTop",        {
      bold  = true,
      fg    = "#7aa2f7",
      bg    = "#1a1b26",
    })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "GlanceListMatch",     { bold = true, fg = p.blue, bg = p.surface1 or "#1e2d4a" })
        hl(0, "GlanceListBorderTop", { bold = true, fg = p.blue, bg = p.base   or "#1a1b26"  })
        hl(0, "GlanceListCount",     { bold = true, fg = p.blue })
      end
      if p.orange then
        hl(0, "GlancePreviewMatch",  {
          bold      = true,
          underline = true,
          fg        = p.orange,
          bg        = p.surface0 or "#2b1d0e",
        })
      end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "GlanceFoldIcon",  { fg = dim })
      hl(0, "GlanceIndent",    { fg = p.surface2 or "#313244" })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART ACTION BUILDER — open glance or fallback to LSP
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function glance(method)
    return function()
      local ok, glance_mod = pcall(require, "glance")
      if ok then
        glance_mod.open(method)
      else
        -- Fallback to native LSP
        local fn_map = {
          definitions     = vim.lsp.buf.definition,
          references      = vim.lsp.buf.references,
          implementations = vim.lsp.buf.implementation,
          type_definitions= vim.lsp.buf.type_definition,
        }
        local fn = fn_map[method]
        if fn then fn() end
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "dnlhc/glance.nvim",
      event        = { "LspAttach" },
      dependencies = { "neovim/nvim-lspconfig" },
  
      keys = {
        -- ── Peek ───────────────────────────────────────────────────────────────
        {
          "gpd",
          glance("definitions"),
          desc   = "🔍 Glance: Definitions",
          silent = true,
        },
        {
          "gpr",
          glance("references"),
          desc   = "🔍 Glance: References",
          silent = true,
        },
        {
          "gpi",
          glance("implementations"),
          desc   = "🔍 Glance: Implementations",
          silent = true,
        },
        {
          "gpt",
          glance("type_definitions"),
          desc   = "🔍 Glance: Type Definitions",
          silent = true,
        },
        -- ── Quick access ──────────────────────────────────────────────────────
        {
          "<leader>lp",
          glance("definitions"),
          desc   = "🔍 Peek Definition",
          silent = true,
        },
        {
          "<leader>lP",
          glance("references"),
          desc   = "🔍 Peek References",
          silent = true,
        },
      },
  
      opts = function()
        local actions = require("glance").actions
  
        return {
          -- ── Window geometry ────────────────────────────────────────────────
          height     = 18,
          zindex     = 45,
  
          -- ── Detach conditions ─────────────────────────────────────────────
          detached   = function(winid)
            -- Open detached (no split) on small windows
            return vim.api.nvim_win_get_width(winid) < 100
          end,
  
          -- ── Preview window settings ───────────────────────────────────────
          preview_win_opts = {
            cursorline       = true,
            number           = true,
            wrap             = false,
            signcolumn       = "yes",
            foldenable       = false,
            -- Disable cursor blinking in preview
            cursorbind       = false,
            scrollbind       = false,
          },
  
          -- ── Border style ──────────────────────────────────────────────────
          border         = {
            enable       = true,
            top_char     = "─",
            bottom_char  = "─",
          },
  
          -- ── List panel ────────────────────────────────────────────────────
          list = {
            position     = "right",
            width        = 0.33,
          },
  
          -- ── Theme/highlight groups ────────────────────────────────────────
          theme = {
            enable       = true,
            mode         = "auto",   -- "auto" | "brighten" | "darken"
          },
  
          -- ── Mappings inside Glance windows ────────────────────────────────
          mappings = {
            list = {
              -- Navigation
              ["j"]           = actions.next,
              ["k"]           = actions.previous,
              ["<Tab>"]       = actions.next_location,
              ["<S-Tab>"]     = actions.previous_location,
              ["<C-u>"]       = actions.preview_scroll_win(-5),
              ["<C-d>"]       = actions.preview_scroll_win(5),
  
              -- Open
              ["<CR>"]        = actions.jump,
              ["v"]           = actions.jump_vsplit,
              ["s"]           = actions.jump_split,
              ["t"]           = actions.jump_tab,
              ["<C-t>"]       = actions.jump_tab,
              ["<C-v>"]       = actions.jump_vsplit,
              ["<C-x>"]       = actions.jump_split,
  
              -- Panel
              ["<leader>l"]   = actions.enter_win("preview"),
              ["q"]           = actions.close,
              ["<Esc>"]       = actions.close,
              ["Q"]           = actions.close,
  
              -- Folding
              ["zo"]          = actions.open_fold,
              ["zc"]          = actions.close_fold,
              ["za"]          = actions.toggle_fold,
              ["zR"]          = actions.open_all_folds,
              ["zM"]          = actions.close_all_folds,
            },
            preview = {
              ["q"]           = actions.close,
              ["<Esc>"]       = actions.close,
              ["<Tab>"]       = actions.next_location,
              ["<S-Tab>"]     = actions.previous_location,
              ["<leader>l"]   = actions.enter_win("list"),
              ["<C-u>"]       = actions.preview_scroll_win(-5),
              ["<C-d>"]       = actions.preview_scroll_win(5),
            },
          },
  
          -- ── Hooks ─────────────────────────────────────────────────────────
          hooks = {
            before_open = function(results, open, jump, method)
              -- If only one result, jump directly without opening glance
              if #results == 1 then
                jump(results[1])
              else
                open(results)
              end
            end,
          },
  
          -- ── Folds ─────────────────────────────────────────────────────────
          folds = {
            fold_closed      = "",
            fold_open        = "",
            folded           = true,
          },
  
          -- ── Indent ────────────────────────────────────────────────────────
          indent_lines = {
            enable         = true,
            icon           = "│",
          },
  
          -- ── Winbar ───────────────────────────────────────────────────────
          winbar = {
            enable         = true,
          },
        }
      end,
  
      config = function(_, opts)
        require("glance").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshGlance", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🔍 Glance highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Glance", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🔍 Glance loaded — gp{d/r/i/t} to peek",
            vim.log.levels.DEBUG,
            { title = "ASH Glance" }
          )
        end
      end,
    },
  }