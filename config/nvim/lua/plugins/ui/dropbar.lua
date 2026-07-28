-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/dropbar.lua — IDE-Grade Breadcrumb / WinBar                 ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: Bekaboo/dropbar.nvim                                                ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Contextual breadcrumb path in the winbar                               ║
-- ║      File → Namespace → Class → Method → current symbol                    ║
-- ║    • Treesitter-powered live symbol tracking                                ║
-- ║    • LSP document symbols integration                                        ║
-- ║    • Markdown heading breadcrumb                                            ║
-- ║    • Foldable dropdown menu on click (fuzzy search inside)                 ║
-- ║    • Per-source icons: file/lsp/treesitter/markdown                        ║
-- ║    • Animated separator transitions                                         ║
-- ║    • Catppuccin palette-aware 20+ highlight groups                          ║
-- ║    • Per-filetype enable/disable                                            ║
-- ║    • Click-to-jump: click any breadcrumb to jump to that scope             ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "Bekaboo/dropbar.nvim",
    event        = { "BufReadPost", "BufNewFile" },
    version      = "*",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  
    keys = {
      {
        "<leader>cb",
        function() require("dropbar.api").pick() end,
        desc = "󰉹  Pick breadcrumb symbol",
      },
      {
        "[c",
        function() require("dropbar.api").goto_context_start() end,
        desc = "  Go to start of context (dropbar)",
      },
      {
        "]c",
        function() require("dropbar.api").select_next_context() end,
        desc = "  Select next context (dropbar)",
      },
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function()
        p = require("catppuccin.palettes").get_palette() or {}
      end)
  
      local base    = p.base     or "#1e1e2e"
      local mantle  = p.mantle   or "#181825"
      local surface = p.surface0 or "#313244"
      local surface1 = p.surface1 or "#45475a"
      local overlay = p.overlay0 or "#6c7086"
      local text    = p.text     or "#cdd6f4"
      local subtext = p.subtext1 or "#bac2de"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local peach   = p.peach    or "#fab387"
      local teal    = p.teal     or "#94e2d5"
      local sky     = p.sky      or "#89dceb"
      local lavend  = p.lavender or "#b4befe"
      local pink    = p.pink     or "#f5c2e7"
  
      -- ── Excluded filetypes ────────────────────────────────────────────────
      local excluded_ft = {
        "alpha", "dashboard", "neo-tree", "NvimTree",
        "aerial", "Trouble", "lazy", "mason",
        "notify", "toggleterm", "help", "checkhealth",
        "lspinfo", "TelescopePrompt", "WhichKey",
        "noice", "dap-repl", "dapui_scopes",
        "dapui_watches", "dapui_stacks", "dapui_breakpoints",
        "neotest-summary", "neotest-output",
        "OverseerList", "fugitive", "DiffviewFiles",
        "gitcommit", "man", "scratch", "qf",
      }
  
      -- ── Source icon mapping ───────────────────────────────────────────────
      -- Each dropbar source renders differently
      ---@param kind string  LSP kind name
      ---@return string icon, string hl
      local function kind_icon(kind)
        local icon = icons.kinds[kind] or icons.ui.Code
        return icon, "DropBarKind" .. kind
      end
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- General
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        general = {
          -- Enable dropbar only for listed buffer types
          enable = function(buf, win)
            -- Skip excluded filetypes
            if vim.tbl_contains(excluded_ft, vim.bo[buf].filetype) then
              return false
            end
            -- Skip special buffer types
            local bt = vim.bo[buf].buftype
            if bt ~= "" and bt ~= "acwrite" then return false end
            -- Skip floating windows
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative ~= "" then return false end
            -- Skip large files
            if vim.b[buf].large_file then return false end
            return vim.bo[buf].buftype == ""
              or vim.bo[buf].buftype == "acwrite"
          end,
  
          -- Attach events
          attach_events = {
            "BufWinEnter",
            "BufWritePost",
          },
  
          -- Update events that trigger winbar refresh
          update_events = {
            buf = {
              "BufModifiedSet",
              "FileChangedShellPost",
              "TextChanged",
              "ModeChanged",
            },
            win = {
              "CursorMoved",
              "WinResized",
            },
            global = {
              "DirChanged",
              "VimResized",
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Icons
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        icons = {
          -- ── Enable / disable icon kinds ──────────────────────────────
          enable        = {
            bar           = true,         -- show icons in the breadcrumb bar
            menu          = true,         -- show icons in the dropdown menu
          },
  
          -- ── Kind icons (LSP symbol kinds) ────────────────────────────
          kinds = {
            use_devicons  = true,         -- use nvim-web-devicons for file icons
            symbols       = vim.tbl_extend("force", icons.kinds, {
              -- Overrides for dropbar-specific display (slightly different sizing)
              File      = icons.kinds.File,
              Module    = icons.kinds.Module,
              Namespace = icons.kinds.Namespace,
              Package   = icons.kinds.Package,
              Class     = icons.kinds.Class,
              Method    = icons.kinds.Method,
              Property  = icons.kinds.Property,
              Field     = icons.kinds.Field,
              Constructor = icons.kinds.Constructor,
              Enum      = icons.kinds.Enum,
              Interface = icons.kinds.Interface,
              Function  = icons.kinds.Function,
              Variable  = icons.kinds.Variable,
              Constant  = icons.kinds.Constant,
              String    = icons.kinds.String,
              Number    = icons.kinds.Number,
              Boolean   = icons.kinds.Boolean,
              Array     = icons.kinds.Array,
              Object    = icons.kinds.Object,
              Key       = icons.kinds.Key,
              Null      = icons.kinds.Null,
              EnumMember = icons.kinds.EnumMember,
              Struct    = icons.kinds.Struct,
              Event     = icons.kinds.Event,
              Operator  = icons.kinds.Operator,
              TypeParameter = icons.kinds.TypeParameter,
            }),
          },
  
          -- ── UI chrome icons ──────────────────────────────────────────
          ui = {
            bar = {
              separator   = " " .. icons.ui.ChevronRight .. " ",
              extends     = icons.ui.Ellipsis,
            },
            menu = {
              separator   = " ",
              indicator   = icons.ui.ChevronRight,
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Bar (the winbar breadcrumb)
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        bar = {
          -- Padding inside the bar
          padding = {
            left  = 1,
            right = 1,
          },
  
          -- Sources: which providers feed the breadcrumb
          -- Ordered by priority — first match wins for each segment
          sources = function(buf, _win)
            local sources = require("dropbar.sources")
            local ft = vim.bo[buf].filetype
            -- Markdown: heading hierarchy
            if ft == "markdown" or ft == "norg" then
              return { sources.markdown }
            end
            -- Terminal / nofile: no breadcrumb
            if vim.bo[buf].buftype == "terminal" then
              return {}
            end
            -- Default: file path + treesitter/LSP symbols
            return {
              sources.path,               -- file system path segments
              {
                -- Prefer LSP, fall back to treesitter
                get_symbols = function(b, w, cursor)
                  local lsp_sym = sources.lsp.get_symbols(b, w, cursor)
                  if lsp_sym and #lsp_sym > 0 then return lsp_sym end
                  return sources.treesitter.get_symbols(b, w, cursor)
                end,
              },
            }
          end,
  
          -- Truncation strategy for long paths
          truncate = true,
  
          -- Pick mode: show letters beside each item for quick jump
          pick = {
            pivots = "asdfjkl;",         -- home-row keys for pick mode
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Dropdown Menu
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        menu = {
          -- Quick-access keymaps inside the dropdown
          keymaps = {
            ["<CR>"]         = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if menu then
                local cursor = vim.api.nvim_win_get_cursor(menu.win)
                local entry  = menu.entries and menu.entries[cursor[1]]
                if entry then
                  local component = entry:first_clickable(entry.padding.left)
                  if component then menu:click_on(component, nil, 1, "l") end
                end
              end
            end,
            ["<Esc>"]        = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if menu then menu:close() end
            end,
            ["q"]            = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if menu then menu:close() end
            end,
            ["<S-CR>"]       = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if menu then menu:close(nil, true) end
            end,
            ["<MouseMove>"]  = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if not menu then return end
              local mouse = vim.fn.getmousepos()
              menu:update_hover_hl({ mouse.line, mouse.column - 1 })
            end,
            ["<LeftMouse>"]  = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if not menu then return end
              local mouse = vim.fn.getmousepos()
              if vim.api.nvim_win_is_valid(mouse.winid) then
                if mouse.winid ~= menu.win then
                  menu:close()
                  vim.api.nvim_set_current_win(mouse.winid)
                  return
                end
                menu:click_at({ mouse.line, mouse.column - 1 }, nil, 1, "l")
              end
            end,
            -- Fuzzy search inside dropdown
            ["/"]            = function()
              local menu = require("dropbar.api").get_current_dropbar_menu()
              if menu then menu:fuzzy_find_open() end
            end,
          },
  
          -- Scrollbar inside dropdown menu
          scrollbar          = {
            enable           = true,
            background       = true,
          },
  
          -- Window options for the dropdown
          win_configs        = {
            border           = "rounded",
            style            = "minimal",
            col              = 1,
            zindex           = 60,
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Sources config
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        sources = {
          -- ── Path source ──────────────────────────────────────────────
          path = {
            -- Max breadcrumb path depth
            max_depth         = 4,
            -- Show relative path from project root
            relative_to       = function(_buf, _win)
              local ok, root = pcall(require, "project_nvim.project")
              if ok and root then
                local path = root.get_project_root()
                if path then return path end
              end
              return vim.fn.getcwd()
            end,
            -- Separator between path components
            path_to_symbols   = function(path_str)
              local ok, devicons = pcall(require, "nvim-web-devicons")
              local parts        = vim.split(path_str, "/", { plain = true })
              local symbols      = {}
              for i, part in ipairs(parts) do
                local icon, hl = icons.ui.Folder, "DropBarIconUIFolder"
                if i == #parts then
                  -- Last component = file
                  if ok then
                    icon, hl = devicons.get_icon(
                      part,
                      vim.fn.fnamemodify(part, ":e"),
                      { default = true }
                    )
                  end
                end
                symbols[#symbols + 1] = {
                  name       = part,
                  icon       = icon or icons.ui.File,
                  icon_hl    = hl   or "DropBarIconUIFile",
                }
              end
              return symbols
            end,
          },
  
          -- ── Treesitter source ─────────────────────────────────────────
          treesitter = {
            -- Max number of treesitter nodes to show
            max_depth         = 5,
            -- Node types to include as breadcrumb items
            valid_types       = {
              "array",         "boolean",       "break_statement",
              "call",          "case_statement", "class",
              "constant",      "constructor",    "continue_statement",
              "delete",        "do_statement",   "element",
              "enum",          "enum_member",    "event",
              "for_statement", "function",       "h1_marker",
              "h2_marker",     "h3_marker",      "h4_marker",
              "h5_marker",     "h6_marker",      "if_statement",
              "interface",     "keyword",        "macro",
              "method",        "module",         "namespace",
              "null",          "number",         "operator",
              "package",       "pair",           "property",
              "reference",     "repeat",         "scope",
              "specifier",     "string",         "struct",
              "switch_statement", "type",        "type_parameter",
              "unit",          "value",          "variable",
              "while_statement", "declaration",  "field",
              "identifier",    "object",         "statement",
              "text",
            },
          },
  
          -- ── LSP source ────────────────────────────────────────────────
          lsp = {
            request = {
              -- Timeout for LSP symbol request
              ttl_init  = 60,
              interval  = 1000,
            },
          },
  
          -- ── Markdown source ───────────────────────────────────────────
          markdown = {
            max_depth         = 6,       -- H1→H6
          },
        },
      }
    end,
  
    config = function(_, opts)
      require("dropbar").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base     = p.base      or "#1e1e2e"
        local mantle   = p.mantle    or "#181825"
        local surface  = p.surface0  or "#313244"
        local surface1 = p.surface1  or "#45475a"
        local overlay  = p.overlay0  or "#6c7086"
        local text     = p.text      or "#cdd6f4"
        local subtext  = p.subtext1  or "#bac2de"
        local blue     = p.blue      or "#89b4fa"
        local green    = p.green     or "#a6e3a1"
        local yellow   = p.yellow    or "#f9e2af"
        local red      = p.red       or "#f38ba8"
        local mauve    = p.mauve     or "#cba6f7"
        local peach    = p.peach     or "#fab387"
        local teal     = p.teal      or "#94e2d5"
        local lavend   = p.lavender  or "#b4befe"
        local pink     = p.pink      or "#f5c2e7"
        local sky      = p.sky       or "#89dceb"
  
        ---@type table<string, table>
        local hls = {
          -- ── Bar (winbar) ────────────────────────────────────────────────
          DropBarBar            = { bg = mantle,  fg = subtext               },
          DropBarBarActive      = { bg = mantle,  fg = text,  bold = true    },
          DropBarBarInactive    = { bg = mantle,  fg = overlay               },
          -- ── Separators ──────────────────────────────────────────────────
          DropBarIconUISeparator          = { fg = overlay, bg = mantle      },
          DropBarIconUISeparatorMenu      = { fg = overlay, bg = surface     },
          DropBarIconUIExtends            = { fg = overlay, bg = mantle      },
          DropBarIconUIIndicator          = { fg = blue,    bg = surface     },
          -- ── Menus ───────────────────────────────────────────────────────
          DropBarMenu               = { bg = surface, fg = text              },
          DropBarMenuNormalFloat    = { bg = surface, fg = text              },
          DropBarMenuFloatBorder    = { bg = surface, fg = overlay           },
          DropBarMenuCurrentContext = { bg = surface1, fg = text, bold = true },
          DropBarMenuHoverIcon      = { bg = surface1, fg = text             },
          DropBarMenuHoverEntry     = { bg = surface1, fg = text             },
          DropBarMenuHoverSymbol    = { bg = surface1, fg = blue, bold = true },
          DropBarMenuScrollbar      = { bg = surface,  fg = overlay          },
          -- ── File / folder icons ──────────────────────────────────────────
          DropBarIconUIFile         = { fg = blue,   bg = mantle             },
          DropBarIconUIFolder       = { fg = peach,  bg = mantle             },
          -- ── Preview ─────────────────────────────────────────────────────
          DropBarPreview            = { bg = surface1                        },
          -- ── Kind colours (LSP symbol kinds) ──────────────────────────────
          DropBarKindArray          = { fg = peach,  bg = mantle             },
          DropBarKindBoolean        = { fg = mauve,  bg = mantle             },
          DropBarKindClass          = { fg = yellow, bg = mantle             },
          DropBarKindConstant       = { fg = peach,  bg = mantle             },
          DropBarKindConstructor    = { fg = blue,   bg = mantle             },
          DropBarKindEnum           = { fg = green,  bg = mantle             },
          DropBarKindEnumMember     = { fg = teal,   bg = mantle             },
          DropBarKindEvent          = { fg = red,    bg = mantle             },
          DropBarKindField          = { fg = lavend, bg = mantle             },
          DropBarKindFile           = { fg = blue,   bg = mantle             },
          DropBarKindFolder         = { fg = peach,  bg = mantle             },
          DropBarKindFunction       = { fg = blue,   bg = mantle             },
          DropBarKindInterface      = { fg = teal,   bg = mantle             },
          DropBarKindKey            = { fg = red,    bg = mantle             },
          DropBarKindKeyword        = { fg = mauve,  bg = mantle             },
          DropBarKindMethod         = { fg = blue,   bg = mantle             },
          DropBarKindModule         = { fg = lavend, bg = mantle             },
          DropBarKindNamespace      = { fg = mauve,  bg = mantle             },
          DropBarKindNull           = { fg = overlay, bg = mantle            },
          DropBarKindNumber         = { fg = peach,  bg = mantle             },
          DropBarKindObject         = { fg = yellow, bg = mantle             },
          DropBarKindOperator       = { fg = sky,    bg = mantle             },
          DropBarKindPackage        = { fg = lavend, bg = mantle             },
          DropBarKindProperty       = { fg = lavend, bg = mantle             },
          DropBarKindReference      = { fg = lavend, bg = mantle             },
          DropBarKindSnippet        = { fg = mauve,  bg = mantle             },
          DropBarKindString         = { fg = green,  bg = mantle             },
          DropBarKindStruct         = { fg = yellow, bg = mantle             },
          DropBarKindText           = { fg = text,   bg = mantle             },
          DropBarKindTypeParameter  = { fg = yellow, bg = mantle             },
          DropBarKindUnit           = { fg = green,  bg = mantle             },
          DropBarKindValue          = { fg = peach,  bg = mantle             },
          DropBarKindVariable       = { fg = lavend, bg = mantle             },
          -- ── Markdown headings ────────────────────────────────────────────
          DropBarKindMarkdownH1     = { fg = red,    bold = true, bg = mantle },
          DropBarKindMarkdownH2     = { fg = peach,  bold = true, bg = mantle },
          DropBarKindMarkdownH3     = { fg = yellow, bold = true, bg = mantle },
          DropBarKindMarkdownH4     = { fg = green,  bold = true, bg = mantle },
          DropBarKindMarkdownH5     = { fg = teal,   bold = true, bg = mantle },
          DropBarKindMarkdownH6     = { fg = blue,   bold = true, bg = mantle },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }