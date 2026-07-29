-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/statuscol.lua — Ultra Status Column                         ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: luukvbaal/statuscol.nvim                                            ║
-- ║                                                                              ║
-- ║  Architecture:                                                               ║
-- ║    ┌──────────────────────────────────────────────────────────────┐          ║
-- ║    │ FOLD │ GIT │ DIAG │ MARK │ NUM  │ ← column order (L→R)      │          ║
-- ║    └──────────────────────────────────────────────────────────────┘          ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Fold column with open/close icons (Nerd Font v3)                       ║
-- ║    • Git signs (gitsigns) with per-hunk-type colouring                      ║
-- ║    • Diagnostic severity icons in dedicated sign slot                       ║
-- ║    • Named mark indicators (a-z, A-Z)                                       ║
-- ║    • Relative / absolute number hybrid                                       ║
-- ║    • Click handlers: fold toggle, gitsigns preview, diagnostic float        ║
-- ║    • Number column: current line bold + coloured, others dimmed             ║
-- ║    • Catppuccin-aware highlight groups with ColorScheme sync                ║
-- ║    • Per-filetype disable list                                               ║
-- ║    • Large-file performance guard                                            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "luukvbaal/statuscol.nvim",
    branch = "stable",
    event  = { "BufReadPost", "BufNewFile", "VimEnter" },
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  
    keys = {
      {
        "<leader>uG",
        function()
          local ok, sc = pcall(require, "statuscol")
          if not ok then return end
          vim.g.statuscol_disable = not vim.g.statuscol_disable
          if vim.g.statuscol_disable then
            vim.opt.statuscolumn = ""
          else
            sc.setup(require("statuscol").opts or {})
          end
          vim.notify(
            (vim.g.statuscol_disable and "󰅖 " or " ")
              .. "Status column " .. (vim.g.statuscol_disable and "disabled" or "enabled"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 2000 }
          )
        end,
        desc = "  Toggle status column",
      },
    },
  
    opts = function()
      local builtin = require("statuscol.builtin")
      local icons   = Ash.icons
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- § 01  CLICK HANDLERS
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      ---Fold-column click: toggle fold at clicked line
      ---@param args table  statuscol click args
      local function fold_click(args)
        if args.button == "l" then
          -- Left-click: toggle fold
          if vim.fn.foldlevel(args.mousepos.line) > 0 then
            local closed = vim.fn.foldclosed(args.mousepos.line) ~= -1
            if closed then
              vim.cmd(args.mousepos.line .. "foldopen")
            else
              vim.cmd(args.mousepos.line .. "foldclose")
            end
          end
        elseif args.button == "m" then
          -- Middle-click: open all folds
          vim.cmd("normal! zR")
        end
      end
  
      ---Gitsigns-column click: preview hunk under cursor
      ---@param args table
      local function gitsigns_click(args)
        if args.button == "l" then
          -- Left-click: stage hunk
          local ok, gs = pcall(require, "gitsigns")
          if ok then
            vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
            gs.preview_hunk_inline()
          end
        elseif args.button == "r" then
          -- Right-click: reset hunk
          local ok, gs = pcall(require, "gitsigns")
          if ok then
            vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
            gs.reset_hunk()
          end
        end
      end
  
      ---Diagnostic click: open float
      ---@param args table
      local function diag_click(args)
        if args.button == "l" then
          vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
          vim.diagnostic.open_float({ scope = "line" })
        end
      end
  
      ---Line-number click: set mark or select line
      ---@param args table
      local function num_click(args)
        if args.button == "l" then
          -- Single left-click: move cursor to line
          vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
        elseif args.button == "r" then
          -- Right-click: open context menu
          vim.ui.select(
            {
              "Go to line " .. args.mousepos.line,
              "Set mark on line " .. args.mousepos.line,
              "Add to quickfix",
            },
            { prompt = icons.ui.List .. "  Line actions", kind = "ash_statuscol" },
            function(choice)
              if not choice then return end
              if choice:match("^Go") then
                vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
              elseif choice:match("^Set mark") then
                vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
                vim.cmd("normal! ma")
                vim.notify(
                  " Mark 'a' set on line " .. args.mousepos.line,
                  vim.log.levels.INFO,
                  { title = "ASH NeoVim" }
                )
              elseif choice:match("^Add") then
                vim.fn.setqflist({{
                  bufnr = vim.api.nvim_get_current_buf(),
                  lnum  = args.mousepos.line,
                  text  = "Manually added from statuscol",
                }}, "a")
                vim.notify(
                  " Added line " .. args.mousepos.line .. " to quickfix",
                  vim.log.levels.INFO,
                  { title = "ASH NeoVim" }
                )
              end
            end
          )
        end
      end
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- § 02  CUSTOM SEGMENT BUILDERS
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      ---Build a fold indicator segment
      ---Returns the appropriate Nerd Font fold icon
      ---@return string  statuscolumn expression
      local function fold_segment()
        return table.concat({
          "%@v:lua.ScFa@",              -- click callback
          "%#FoldColumn#",              -- highlight
          "%C",                         -- fold column (builtin placeholder)
          "%*",                         -- reset highlight
          "%T",                         -- end click target
        })
      end
  
      ---Build a line-number segment with bold current line
      ---@return string
      local function number_segment()
        return table.concat({
          "%@v:lua.ScLa@",              -- click callback
          "%=",                         -- right-align
          "%{v:relnum == 0 "
            .. '? "%#StatusColCurrentLine#" .. v:lnum .. "%*"'
            .. ' : "%#StatusColRelNum#" .. v:relnum .. "%*"'
            .. "}",
          " ",                          -- padding
          "%T",
        })
      end
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- § 03  EXCLUDED FILETYPES
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      local excluded_ft = {
        "alpha",        "dashboard",    "neo-tree",
        "NvimTree",     "aerial",       "Trouble",
        "lazy",         "mason",        "notify",
        "toggleterm",   "help",         "checkhealth",
        "lspinfo",      "TelescopePrompt", "WhichKey",
        "noice",        "dap-repl",     "dapui_scopes",
        "dapui_watches","dapui_stacks", "dapui_breakpoints",
        "neotest-summary", "neotest-output", "neotest-output-panel",
        "OverseerList", "fugitive",     "DiffviewFiles",
        "gitcommit",    "man",          "scratch",
      }
  
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      -- § 04  MAIN OPTS
      -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
      return {
        -- Whether to set vim.o.statuscolumn
        setopt  = true,
  
        -- Relnum: enable relative numbers
        relculright = false,
  
        -- ── Filetype exclusions ──────────────────────────────────────────
        ft_ignore = excluded_ft,
        bt_ignore = {
          "terminal", "nofile", "quickfix",
          "prompt",   "help",   "nowrite",
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- SEGMENTS — left to right order in the status column
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        segments = {
  
          -- ── ❶ Fold column ─────────────────────────────────────────────
          {
            sign = {
              -- Custom fold segment using builtin fold provider
              name   = { ".*" },
              text   = { ".*" },
              colwidth = 1,
            },
            click  = "v:lua.ScFa",
            condition = {
              -- Only show fold column when folds exist
              function()
                return vim.fn.foldlevel(vim.v.lnum) > 0
                    or vim.fn.foldlevel(vim.v.lnum + 1) > 0
              end,
            },
            hl     = "FoldColumn",
          },
  
          -- ── ❷ Git signs (gitsigns) ────────────────────────────────────
          {
            sign = {
              -- Match all gitsigns sign names
              name     = {
                "GitSigns.*",
                "MiniDiffSign.*",
              },
              maxwidth = 1,
              colwidth = 1,
              auto     = true,
            },
            click = "v:lua.ScSa",
            hl    = "StatusColGit",
          },
  
          -- ── ❸ Diagnostic signs ────────────────────────────────────────
          {
            sign = {
              -- Match diagnostic sign names from nvim_lsp
              namespace = { "diagnostic.*" },
              name      = {
                "DiagnosticSign.*",
                "LspDiag.*",
              },
              maxwidth  = 1,
              colwidth  = 1,
              auto      = true,
            },
            click = "v:lua.ScSa",
            hl    = "StatusColDiag",
          },
  
          -- ── ❹ Mark signs ──────────────────────────────────────────────
          {
            sign = {
              name     = { ".*Mark.*", "mark.*" },
              maxwidth = 1,
              colwidth = 1,
              auto     = true,
            },
            click = "v:lua.ScSa",
            hl    = "StatusColMark",
          },
  
          -- ── ❺ Line numbers ────────────────────────────────────────────
          -- Right-aligned; current line absolute + bold, others relative
          {
            text = {
              -- Current line: absolute number with accent colour
              -- Other lines: relative number, dimmed
              function(lnum, relnum, virtnum)
                if virtnum ~= 0 then return "" end
                if relnum == 0 then
                  -- Current line
                  return "%#StatusColCurrentLine#"
                    .. tostring(lnum)
                    .. "%*"
                else
                  -- Relative line
                  return "%#StatusColRelNum#"
                    .. tostring(relnum)
                    .. "%*"
                end
              end,
            },
            click = "v:lua.ScLa",
            hl    = "StatusColNum",
          },
  
          -- ── ❻ Padding ─────────────────────────────────────────────────
          {
            text  = { " " },   -- single space between numcol and text area
            hl    = "StatusColPad",
          },
        },
  
        -- ── Click handler globals ────────────────────────────────────────
        -- statuscol uses v:lua.ScXa globals; we register our custom ones
        -- after setup (see config block)
      }
    end,
  
    config = function(_, opts)
      -- ── Register click handler globals ────────────────────────────────────
  
      ---Fold area click handler (registered as ScFa)
      _G.ScFa = function(args)
        if args.button == "l" then
          if vim.fn.foldlevel(args.mousepos.line) > 0 then
            local closed = vim.fn.foldclosed(args.mousepos.line) ~= -1
            vim.cmd(args.mousepos.line .. (closed and "foldopen" or "foldclose"))
          end
        elseif args.button == "m" then
          vim.cmd("normal! zR")
        end
      end
  
      ---Sign area click handler (registered as ScSa)
      _G.ScSa = function(args)
        -- Move cursor to clicked line
        vim.api.nvim_win_set_cursor(args.mousepos.winid, { args.mousepos.line, 0 })
        -- Check what's at this line: git hunk or diagnostic?
        local diags = vim.diagnostic.get(
          vim.api.nvim_win_get_buf(args.mousepos.winid),
          { lnum = args.mousepos.line - 1 }
        )
        if #diags > 0 and args.button == "l" then
          vim.diagnostic.open_float({ scope = "line" })
          return
        end
        -- Fall back to gitsigns preview
        if args.button == "l" then
          pcall(require("gitsigns").preview_hunk_inline)
        elseif args.button == "r" then
          pcall(require("gitsigns").reset_hunk)
        end
      end
  
      ---Line-number area click handler (registered as ScLa)
      _G.ScLa = function(args)
        local icons = Ash.icons
        if args.button == "l" then
          vim.api.nvim_win_set_cursor(args.mousepos.winid, { args.mousepos.line, 0 })
        elseif args.button == "r" then
          -- Context menu
          local line = args.mousepos.line
          vim.ui.select(
            {
              icons.ui.ChevronRight .. "  Go to line " .. line,
              icons.ui.BookMark     .. "  Set mark",
              icons.ui.List         .. "  Add to quickfix",
            },
            { prompt = " Line " .. line, kind = "ash_statuscol" },
            function(choice)
              if not choice then return end
              vim.api.nvim_win_set_cursor(args.mousepos.winid, { line, 0 })
              if choice:match("Set mark") then
                vim.cmd("normal! ma")
              elseif choice:match("Add to quickfix") then
                vim.fn.setqflist({{
                  bufnr = vim.api.nvim_win_get_buf(args.mousepos.winid),
                  lnum  = line,
                  text  = "Added from statuscolumn",
                }}, "a")
              end
            end
          )
        end
      end
  
      local icons = Ash.icons
  
      require("statuscol").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base    = p.base     or "#1e1e2e"
        local surface = p.surface0 or "#313244"
        local overlay = p.overlay0 or "#6c7086"
        local text    = p.text     or "#cdd6f4"
        local blue    = p.blue     or "#89b4fa"
        local green   = p.green    or "#a6e3a1"
        local yellow  = p.yellow   or "#f9e2af"
        local red     = p.red      or "#f38ba8"
        local mauve   = p.mauve    or "#cba6f7"
        local peach   = p.peach    or "#fab387"
        local teal    = p.teal     or "#94e2d5"
  
        local hls = {
          -- ── Number column ──────────────────────────────────────────────
          StatusColCurrentLine = {
            fg   = blue,
            bold = true,
            bg   = "NONE",
          },
          StatusColRelNum      = {
            fg = overlay,
            bg = "NONE",
          },
          StatusColNum         = {
            fg = overlay,
            bg = "NONE",
          },
          StatusColPad         = {
            fg = "NONE",
            bg = "NONE",
          },
          -- ── Sign columns ───────────────────────────────────────────────
          StatusColGit         = { bg = "NONE"                          },
          StatusColDiag        = { bg = "NONE"                          },
          StatusColMark        = { fg = peach,  bg = "NONE"            },
          -- ── Fold column ────────────────────────────────────────────────
          FoldColumn           = { fg = surface, bg = "NONE"            },
          -- ── Git sign overrides (keep gitsigns colours) ─────────────────
          GitSignsAdd          = { fg = green,  bg = "NONE"            },
          GitSignsChange       = { fg = yellow, bg = "NONE"            },
          GitSignsDelete       = { fg = red,    bg = "NONE"            },
          GitSignsTopdelete    = { fg = red,    bg = "NONE"            },
          GitSignsChangedelete = { fg = peach,  bg = "NONE"            },
          GitSignsUntracked    = { fg = overlay, bg = "NONE"           },
          -- ── Diagnostic sign overrides ──────────────────────────────────
          DiagnosticSignError  = { fg = red,    bg = "NONE"            },
          DiagnosticSignWarn   = { fg = yellow, bg = "NONE"            },
          DiagnosticSignInfo   = { fg = blue,   bg = "NONE"            },
          DiagnosticSignHint   = { fg = teal,   bg = "NONE"            },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── Large file guard ──────────────────────────────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file then
            vim.opt_local.statuscolumn = ""
          end
        end,
      })
    end,
  }