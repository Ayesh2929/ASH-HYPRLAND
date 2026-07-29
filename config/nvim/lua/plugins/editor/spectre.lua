-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🔍 SPECTRE — ULTRA PROJECT-WIDE SEARCH & REPLACE v5.0 OMEGA              ║
-- ║   Regex-powered · multi-engine · live preview · ASH theme-synced               ║
-- ║   ripgrep · sed · ast-grep · file-type filters · undo-safe operations          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 ICON DEFINITIONS — Nerd Font v3
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ICONS = {
    ui = {
      search       = "🔍",
      replace      = "🔄",
      file         = "󰈙 ",
      match        = "󰊕 ",
      selected     = "󰄬 ",
      unselected   = "󰄱 ",
      loading      = "󰔟 ",
      done         = "✅",
      error        = " ",
      warning      = " ",
      info         = " ",
      hint         = "󰌵 ",
      separator    = "─",
      arrow        = "→",
      branch       = " ",
      regex        = "󱗠 ",
      case         = "󰬵 ",
      word         = "󰬛 ",
    },
    engines = {
      rg           = " rg",
      sed          = " sed",
      ast_grep     = "󱘗 ast-grep",
    },
  }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎨 HIGHLIGHT SETUP — ASH palette-aware
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "SpectreNormal",          { link = "NormalFloat"       })
    hl(0, "SpectreWinSeparator",    { link = "WinSeparator"      })
    hl(0, "SpectreBorder",          { link = "FloatBorder"       })
    hl(0, "SpectreTitle",           { bold = true, link = "Title" })
  
    -- ── Search match highlighting ──────────────────────────────────────────────
    hl(0, "SpectreSearch",          {
      bold      = true,
      underline = true,
      fg        = "#ff9e64",
      bg        = "#2b1d0e",
    })
  
    -- ── Replace preview highlighting ───────────────────────────────────────────
    hl(0, "SpectreReplace",         {
      bold      = true,
      strikethrough = false,
      fg        = "#9ece6a",
      bg        = "#1a2b1a",
    })
  
    -- ── File name header ──────────────────────────────────────────────────────
    hl(0, "SpectreFile",            {
      bold   = true,
      italic = false,
      link   = "Directory",
    })
  
    -- ── Line number ───────────────────────────────────────────────────────────
    hl(0, "SpectreBody",            { link = "Normal"            })
    hl(0, "SpectreHeader",          { bold = true, link = "Title" })
  
    -- ── Changed/replaced indicator ────────────────────────────────────────────
    hl(0, "SpectreChangeAll",       { bold = true, fg = "#7aa2f7" })
    hl(0, "SpectreDeleteAll",       { bold = true, fg = "#f38ba8" })
  
    -- ── Cursor line inside spectre ────────────────────────────────────────────
    hl(0, "SpectreCursor",          { link = "CursorLine"        })
    hl(0, "SpectreCurrentQuery",    { bold = true, fg = "#e0af68" })
  
    -- ── Engine/option indicators ──────────────────────────────────────────────
    hl(0, "SpectreActive",          { bold = true, fg = "#9ece6a" })
    hl(0, "SpectreInactive",        { fg = "#545c7e"              })
  
    -- ── Match count badge ──────────────────────────────────────────────────────
    hl(0, "SpectreCount",           { bold = true, fg = "#7dcfff" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.orange then
        hl(0, "SpectreSearch",  { bold = true, underline = true, fg = p.orange })
      end
      if p.green then
        hl(0, "SpectreReplace", { bold = true, fg = p.green })
      end
      if p.blue then
        hl(0, "SpectreChangeAll", { bold = true, fg = p.blue })
      end
      if p.red then
        hl(0, "SpectreDeleteAll", { bold = true, fg = p.red })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART OPEN HELPERS — context-aware Spectre launches
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Open Spectre in a floating window with optional pre-filled search
  local function open_spectre(opts)
    return function()
      require("spectre").open(opts or {})
    end
  end
  
  -- Search for word under cursor project-wide
  local function search_current_word()
    return function()
      require("spectre").open_visual({
        select_word = true,
      })
    end
  end
  
  -- Search for visual selection project-wide
  local function search_visual_selection()
    return function()
      require("spectre").open_visual()
    end
  end
  
  -- Search in current file only (buffer-local mode)
  local function search_in_file()
    return function()
      require("spectre").open_file_search({ select_word = true })
    end
  end
  
  -- Search word under cursor in current file only
  local function search_word_in_file()
    return function()
      require("spectre").open_file_search()
    end
  end
  
  -- Resume last Spectre session
  local function resume_spectre()
    return function()
      require("spectre").resume_last_search()
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  RESULT FORMATTERS — custom display for each engine
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function make_vimgrep_format()
    return {
      -- Column number in output
      column = true,
      -- Show line number
      line   = true,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-pack/nvim-spectre",
      build        = false,
      cmd          = "Spectre",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
      },
  
      -- ── Keys ──────────────────────────────────────────────────────────────────
      keys = {
        -- ── Project-wide ──────────────────────────────────────────────────────
        {
          "<leader>sr",
          open_spectre(),
          desc  = "🔍 Spectre: Search & Replace (project)",
          mode  = "n",
        },
        {
          "<leader>sw",
          search_current_word(),
          desc  = "🔍 Spectre: Word under cursor (project)",
          mode  = "n",
        },
        {
          "<leader>sW",
          search_visual_selection(),
          desc  = "🔍 Spectre: Selection (project)",
          mode  = "v",
        },
        {
          "<leader>s.",
          resume_spectre(),
          desc  = "🔍 Spectre: Resume last search",
          mode  = "n",
        },
  
        -- ── Current file ──────────────────────────────────────────────────────
        {
          "<leader>sf",
          search_word_in_file(),
          desc  = "🔍 Spectre: Search in file",
          mode  = "n",
        },
        {
          "<leader>sF",
          search_in_file(),
          desc  = "🔍 Spectre: Word in file",
          mode  = "n",
        },
  
        -- ── With filters ──────────────────────────────────────────────────────
        {
          "<leader>sL",
          function()
            local ft = vim.bo.filetype
            require("spectre").open({
              is_insert_mode = true,
              search_text    = "",
              path           = "",
              replace_text   = "",
              -- Pre-set filetype filter
              selected_maintainer = ft,
            })
          end,
          desc  = "🔍 Spectre: Search in filetype",
          mode  = "n",
        },
      },
  
      -- ── Options ───────────────────────────────────────────────────────────────
      opts = {
        -- ── Window style ────────────────────────────────────────────────────────
        open_cmd         = "vnew",       -- command to open spectre panel
        live_update      = false,        -- auto-execute search while typing (performance)
        line_sep_start   = "┌──────────────────────────────────────────────────────────",
        result_padding   = "│  ",
        line_sep         = "└──────────────────────────────────────────────────────────",
  
        -- ── Highlight groups ──────────────────────────────────────────────────
        highlight = {
          ui           = "String",
          search       = "SpectreSearch",
          replace      = "SpectreReplace",
        },
  
        -- ── Mapping definitions ───────────────────────────────────────────────
        mapping = {
          -- Toggle options
          ["toggle_line"]         = {
            map  = "dd",
            cmd  = "<cmd>lua require('spectre').toggle_line()<cr>",
            desc = "Toggle current item",
          },
          ["enter_file"]          = {
            map  = "<cr>",
            cmd  = "<cmd>lua require('spectre.actions').select_entry()<cr>",
            desc = "Open file",
          },
          ["send_to_qf"]          = {
            map  = "<leader>q",
            cmd  = "<cmd>lua require('spectre.actions').send_to_qf()<cr>",
            desc = "Send to quickfix",
          },
          ["replace_cmd"]         = {
            map  = "<leader>c",
            cmd  = "<cmd>lua require('spectre.actions').replace_cmd()<cr>",
            desc = "Replace with command",
          },
          ["show_option_menu"]    = {
            map  = "<leader>o",
            cmd  = "<cmd>lua require('spectre').show_options()<cr>",
            desc = "Toggle options",
          },
          ["run_current_replace"] = {
            map  = "<leader>rc",
            cmd  = "<cmd>lua require('spectre.actions').run_current_replace()<cr>",
            desc = "Replace current line",
          },
          ["run_replace"]         = {
            map  = "<leader>R",
            cmd  = "<cmd>lua require('spectre.actions').run_replace()<cr>",
            desc = "Replace all",
          },
          ["change_view_mode"]    = {
            map  = "<leader>v",
            cmd  = "<cmd>lua require('spectre').change_view()<cr>",
            desc = "Change view mode",
          },
          ["change_replace_sed"]  = {
            map  = "trs",
            cmd  = "<cmd>lua require('spectre').change_engine_replace('sed')<cr>",
            desc = "Use sed engine",
          },
          ["change_replace_oxi"]  = {
            map  = "tro",
            cmd  = "<cmd>lua require('spectre').change_engine_replace('oxi')<cr>",
            desc = "Use oxi engine",
          },
          ["toggle_live_update"]  = {
            map  = "tu",
            cmd  = "<cmd>lua require('spectre').toggle_live_update()<cr>",
            desc = "Toggle live update",
          },
          ["toggle_ignore_case"]  = {
            map  = "ti",
            cmd  = "<cmd>lua require('spectre').change_options('ignore-case')<cr>",
            desc = "Toggle ignore case",
          },
          ["toggle_ignore_hidden"]= {
            map  = "th",
            cmd  = "<cmd>lua require('spectre').change_options('hidden')<cr>",
            desc = "Toggle hidden files",
          },
          ["resume_last_search"]  = {
            map  = "<leader>l",
            cmd  = "<cmd>lua require('spectre').resume_last_search()<cr>",
            desc = "Resume last search",
          },
          -- Navigation
          ["focus_search_input"]  = {
            map  = "i",
            cmd  = "<cmd>startinsert<cr>",
            desc = "Focus search input",
          },
        },
  
        -- ── Search engines ────────────────────────────────────────────────────
        find_engine = {
          ["rg"] = {
            cmd = "rg",
            args = {
              "--color=never",
              "--no-heading",
              "--with-filename",
              "--line-number",
              "--column",
              "--hidden",
            },
            options = {
              ["ignore-case"] = {
                value  = "--ignore-case",
                icon   = ICONS.ui.case .. " [I]",
                desc   = "ignore case",
              },
              ["hidden"] = {
                value  = "--hidden",
                icon   = "[H]",
                desc   = "hidden files",
              },
              ["word"] = {
                value  = "--word-regexp",
                icon   = ICONS.ui.word .. " [W]",
                desc   = "match whole word",
              },
            },
          },
          ["ag"] = {
            cmd = "ag",
            args = { "--vimgrep", "-s" },
            options = {
              ["ignore-case"] = {
                value  = "-i",
                icon   = ICONS.ui.case .. " [I]",
                desc   = "ignore case",
              },
              ["hidden"] = {
                value  = "--hidden",
                icon   = "[H]",
                desc   = "hidden files",
              },
            },
          },
        },
  
        -- ── Replace engines ────────────────────────────────────────────────────
        replace_engine = {
          ["sed"] = {
            cmd  = "sed",
            args = { "-i", "" },
            options = {
              ["ignore-case"] = {
                value  = "--regexp-extended",
                icon   = ICONS.ui.case .. " [I]",
                desc   = "ignore case",
              },
            },
          },
          ["oxi"] = {
            cmd  = "oxi",
            args = {},
            options = {
              ["ignore-case"] = {
                value  = "i",
                icon   = ICONS.ui.case .. " [I]",
                desc   = "ignore case",
              },
            },
          },
        },
  
        -- ── Default engine ────────────────────────────────────────────────────
        default = {
          find   = {
            cmd     = "rg",
            options = { "ignore-case" },
          },
          replace = {
            cmd     = "sed",
          },
        },
  
        -- ── Replace options ────────────────────────────────────────────────────
        replace_vim_cmd = "cdo",
        is_open_target_win = false,
        is_insert_mode     = false,
        is_block_ui_break  = false,
  
        -- ── Result display ────────────────────────────────────────────────────
        result_view = {
          -- Number of context lines above/below each match
          context = 0,
          -- Show filename header for each file group
          winbar  = true,
        },
      },
  
      config = function(_, opts)
        require("spectre").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshSpectre", { clear = true })
  
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
              "🔍 Spectre highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Spectre", timeout = 1200 }
            )
          end,
        })
  
        -- ── Spectre buffer settings ─────────────────────────────────────────────
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "spectre_panel",
          callback = function(ev)
            -- Disable interfering plugins
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number      = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn  = "no"
            vim.opt_local.statusline  = " 🔍 Spectre — Search & Replace"
            vim.opt_local.cursorline  = true
  
            -- Extra buffer-local keymaps
            local function bmap(lhs, rhs, desc2)
              vim.keymap.set("n", lhs, rhs, {
                buffer  = ev.buf,
                silent  = true,
                desc    = "🔍 " .. desc2,
              })
            end
  
            bmap("q",     "<cmd>lua require('spectre').close()<cr>", "Close Spectre")
            bmap("<esc>", "<cmd>lua require('spectre').close()<cr>", "Close Spectre")
            bmap("?",     function()
              vim.notify(
                table.concat({
                  "🔍 Spectre Keybinds",
                  "────────────────────────────",
                  "dd        Toggle line",
                  "<CR>      Open file",
                  "<leader>R Replace all",
                  "<leader>rc Replace current",
                  "<leader>q  Send to QF",
                  "ti        Toggle case",
                  "th        Toggle hidden",
                  "tu        Toggle live update",
                  "trs       Use sed engine",
                  "q / <esc> Close",
                }, "\n"),
                vim.log.levels.INFO,
                { title = "Spectre Help" }
              )
            end, "Show help")
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "🔍 Spectre loaded",
            vim.log.levels.DEBUG,
            { title = "ASH Spectre" }
          )
        end
      end,
    },
  }