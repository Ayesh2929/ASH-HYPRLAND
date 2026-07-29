-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/dressing.lua — vim.ui Override Suite                        ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: stevearc/dressing.nvim                                              ║
-- ║                                                                              ║
-- ║  Overrides:                                                                  ║
-- ║    vim.ui.input  → beautiful floating prompt with icon prefix               ║
-- ║    vim.ui.select → Telescope / nui picker with devicon rows                 ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Context-aware backend selection (telescope → fzf → nui → builtin)     ║
-- ║    • Rounded borders, palette-aware highlight groups                        ║
-- ║    • Per-kind icon mapping (codeaction / lsp_rename / file / etc.)          ║
-- ║    • Animated slide-in via winblend                                         ║
-- ║    • Input: completion, history scroll, C-a select-all                      ║
-- ║    • Select: multi-select support, live preview                             ║
-- ║    • Fully typed with LuaLS annotations                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "stevearc/dressing.nvim",
    lazy = true,
    -- Load when vim.ui.input / vim.ui.select is first invoked
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
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
  
      -- ── Kind → icon + highlight map ───────────────────────────────────────
      -- Used to enrich vim.ui.select items based on the `kind` field
      ---@type table<string, { icon: string, hl: string }>
      local kind_icons = {
        -- LSP
        codeaction          = { icon = icons.ui.Lightbulb,  hl = "DressingKindCodeAction"  },
        lsp_code_action     = { icon = icons.ui.Lightbulb,  hl = "DressingKindCodeAction"  },
        lsp_rename          = { icon = icons.ui.Rename,      hl = "DressingKindRename"      },
        lsp_symbol          = { icon = icons.ui.Code,        hl = "DressingKindSymbol"      },
        -- Files
        file                = { icon = icons.ui.File,        hl = "DressingKindFile"        },
        directory           = { icon = icons.ui.Folder,      hl = "DressingKindDirectory"   },
        -- Git
        git_branch          = { icon = icons.git.branch,     hl = "DressingKindGit"         },
        git_commit          = { icon = icons.git.commit,     hl = "DressingKindGit"         },
        -- Themes
        ash_theme           = { icon = icons.ui.Star,        hl = "DressingKindTheme"       },
        ash_bufferline      = { icon = icons.ui.Files,       hl = "DressingKindBuffer"      },
        -- Generic
        option              = { icon = icons.ui.Gear,        hl = "DressingKindOption"      },
        error               = { icon = icons.diagnostics.signs.Error, hl = "DressingKindError" },
        warning             = { icon = icons.diagnostics.signs.Warn,  hl = "DressingKindWarn"  },
      }
  
      -- ── Telescope picker configuration ────────────────────────────────────
      ---@param opts table  dressing opts passed at call time
      local function telescope_select(opts)
        -- Determine window layout based on number of items
        local item_count = opts and opts.items and #opts.items or 10
        local layout = item_count > 20 and "vertical" or "cursor"
  
        return {
          layout_strategy  = layout,
          layout_config    = {
            cursor = {
              width    = 0.4,
              height   = math.min(item_count + 4, 20),
            },
            vertical = {
              width    = 0.5,
              height   = 0.7,
              preview_height = 0.4,
            },
          },
          borderchars = {
            prompt  = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
            results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
            preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          },
          initial_mode     = "insert",
          sorting_strategy = "ascending",
          prompt_prefix    = icons.ui.Search .. " ",
          selection_caret  = icons.ui.ChevronRight .. " ",
          path_display     = { "truncate" },
        }
      end
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- vim.ui.input
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        input = {
          enabled          = true,
          default_prompt   = icons.ui.Edit .. " Input:",
          title_pos        = "left",
          insert_only      = true,
          start_in_insert  = true,
          anchor           = "SW",
          border           = "rounded",
          relative         = "cursor",
  
          -- Position: just below the cursor
          prefer_width     = 40,
          max_width        = { 140, 0.9 },
          min_width        = { 20,  0.2 },
  
          -- Window options
          win_options      = {
            winblend      = 8,
            wrap          = false,
            list          = true,
            listchars     = "precedes:…,extends:…",
            sidescrolloff = 0,
            winhighlight  = table.concat({
              "Normal:DressingInputNormal",
              "FloatBorder:DressingInputBorder",
              "FloatTitle:DressingInputTitle",
              "CursorLine:DressingInputCursorLine",
            }, ","),
          },
  
          -- Mappings inside the input prompt
          mappings = {
            n = {
              ["<Esc>"]    = "Close",
              ["<CR>"]     = "Confirm",
            },
            i = {
              ["<C-c>"]    = "Close",
              ["<CR>"]     = "Confirm",
              ["<Up>"]     = "HistoryPrev",
              ["<Down>"]   = "HistoryNext",
              ["<C-p>"]    = "HistoryPrev",
              ["<C-n>"]    = "HistoryNext",
              -- Select-all
              ["<C-a>"]    = function()
                vim.cmd("normal! ggVG")
              end,
              -- Paste from system clipboard
              ["<C-v>"]    = function()
                local text = vim.fn.getreg("+")
                local pos  = vim.fn.col(".") - 1
                local line = vim.api.nvim_get_current_line()
                vim.api.nvim_set_current_line(
                  line:sub(1, pos) .. text .. line:sub(pos + 1)
                )
              end,
            },
          },
  
          override = function(conf)
            -- Nudge the window 1 row below cursor
            conf.row = 1
            return conf
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- vim.ui.select
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        select = {
          enabled          = true,
          backend          = { "telescope", "fzf_lua", "fzf", "nui", "builtin" },
          trim_prompt      = true,
  
          -- ── Telescope backend ──────────────────────────────────────────
          telescope        = telescope_select,
  
          -- ── fzf-lua backend ───────────────────────────────────────────
          fzf_lua          = {
            winopts = {
              width   = 0.5,
              height  = 0.4,
              border  = "rounded",
              preview = { hidden = "hidden" },
            },
          },
  
          -- ── nui backend ───────────────────────────────────────────────
          nui              = {
            position   = "50%",
            size       = nil,
            relative   = "editor",
            border     = {
              style    = "rounded",
              text     = {
                top      = " " .. icons.ui.List .. " Select ",
                top_align = "center",
              },
            },
            buf_options = {
              swapfile = false,
              filetype = "DressingSelect",
            },
            win_options = {
              winblend = 8,
              winhighlight = table.concat({
                "Normal:DressingSelectNormal",
                "FloatBorder:DressingSelectBorder",
                "FloatTitle:DressingSelectTitle",
                "CursorLine:DressingSelectCursorLine",
              }, ","),
            },
            max_width    = { 80, 0.8 },
            max_height   = { 40, 0.9 },
            min_width    = { 40, 0.2 },
            min_height   = { 4,  0.1 },
          },
  
          -- ── builtin backend ───────────────────────────────────────────
          builtin          = {
            anchor       = "NW",
            border       = "rounded",
            relative     = "editor",
            win_options  = {
              winblend = 8,
              cursorlineopt = "both",
              winhighlight = table.concat({
                "Normal:DressingSelectNormal",
                "FloatBorder:DressingSelectBorder",
                "CursorLine:DressingSelectCursorLine",
              }, ","),
            },
            width        = nil,
            max_width    = { 140, 0.8 },
            min_width    = { 40,  0.2 },
            max_height   = 0.9,
            min_height   = { 10,  0.2 },
            mappings     = {
              ["<Esc>"]   = "Close",
              ["<C-c>"]   = "Close",
              ["<CR>"]    = "Confirm",
              ["<Up>"]    = "Up",
              ["<Down>"]  = "Down",
              ["<C-p>"]   = "Up",
              ["<C-n>"]   = "Down",
              ["<C-u>"]   = "ScrollUp",
              ["<C-d>"]   = "ScrollDown",
              ["gg"]      = "First",
              ["G"]       = "Last",
            },
          },
  
          -- ── format_item_override: enrich items with kind icons ─────────
          format_item_override = {
            -- Code actions get a lightbulb icon
            codeaction = function(action)
              local icon = icons.ui.Lightbulb .. " "
              local title = action.title or tostring(action)
              -- Colour-code by action kind
              if action.kind then
                if action.kind:match("^quickfix")  then icon = icons.ui.Bug       .. " " end
                if action.kind:match("^refactor")  then icon = icons.ui.Hammer    .. " " end
                if action.kind:match("^source")    then icon = icons.ui.Gear      .. " " end
                if action.kind:match("^organize")  then icon = icons.ui.Package   .. " " end
              end
              return icon .. title
            end,
          },
  
          -- ── kind-specific telescope overrides ─────────────────────────
          kind_override    = {
            codeaction = telescope_select,
            lsp_code_action = telescope_select,
          },
  
          get_config       = function(opts)
            -- Context-aware: use bigger window for code actions
            if opts.kind == "codeaction" then
              return {
                backend   = "telescope",
                telescope = vim.tbl_extend("force", telescope_select(opts), {
                  layout_strategy = "cursor",
                  layout_config   = {
                    cursor = { width = 0.5, height = 0.4 },
                  },
                }),
              }
            end
            -- Large lists → vertical telescope
            if opts.items and #opts.items > 30 then
              return {
                backend   = "telescope",
                telescope = vim.tbl_extend("force", telescope_select(opts), {
                  layout_strategy = "vertical",
                }),
              }
            end
          end,
        },
      }
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      require("dressing").setup(opts)
  
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
          -- Input
          DressingInputNormal      = { bg = surface, fg = text                    },
          DressingInputBorder      = { bg = surface, fg = blue,    bold = true    },
          DressingInputTitle       = { fg = mauve,   bold = true,  italic = true  },
          DressingInputCursorLine  = { bg = base                                  },
          -- Select
          DressingSelectNormal     = { bg = surface, fg = text                    },
          DressingSelectBorder     = { bg = surface, fg = overlay                 },
          DressingSelectTitle      = { fg = mauve,   bold = true                  },
          DressingSelectCursorLine = { bg = base,    fg = blue,    bold = true    },
          -- Kind highlights
          DressingKindCodeAction   = { fg = yellow,  bold = true                  },
          DressingKindRename       = { fg = green,   bold = true                  },
          DressingKindSymbol       = { fg = blue                                  },
          DressingKindFile         = { fg = peach                                 },
          DressingKindDirectory    = { fg = teal                                  },
          DressingKindGit          = { fg = red                                   },
          DressingKindTheme        = { fg = mauve                                 },
          DressingKindBuffer       = { fg = text                                  },
          DressingKindOption       = { fg = overlay                               },
          DressingKindError        = { fg = red,     bold = true                  },
          DressingKindWarn         = { fg = yellow                                },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }