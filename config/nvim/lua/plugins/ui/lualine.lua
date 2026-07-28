-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/lualine.lua — Status Line                                   ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: nvim-lualine/lualine.nvim                                           ║
-- ║  Features:                                                                   ║
-- ║    • 6-section powerline layout with slant separators                       ║
-- ║    • Mode pill with colour per-mode                                         ║
-- ║    • Git branch + diff stats from gitsigns                                  ║
-- ║    • LSP client names + diagnostics counts                                  ║
-- ║    • Copilot / Codeium / Supermaven status spinner                          ║
-- ║    • Conform formatter + nvim-lint linter indicators                        ║
-- ║    • File encoding + line-ending type                                       ║
-- ║    • Macro recording indicator                                              ║
-- ║    • DAP status when debugging                                              ║
-- ║    • ASH mode + theme indicator                                             ║
-- ║    • Wakatime heartbeat indicator                                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "nvim-lualine/lualine.nvim",
    event        = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "AndreM222/copilot-lualine",
    },
  
    opts = function()
      local icons = Ash.icons
      local util  = Ash.util
  
      -- ── Colour palette (Catppuccin Mocha defaults) ───────────────────────────
      local c = {
        bg      = "#1e1e2e",
        fg      = "#cdd6f4",
        surface = "#313244",
        overlay = "#6c7086",
        blue    = "#89b4fa",
        green   = "#a6e3a1",
        yellow  = "#f9e2af",
        red     = "#f38ba8",
        mauve   = "#cba6f7",
        peach   = "#fab387",
        teal    = "#94e2d5",
        sky     = "#89dceb",
        sapph   = "#74c7ec",
        pink    = "#f5c2e7",
        lavend  = "#b4befe",
      }
  
      -- Attempt to pull from current palette
      pcall(function()
        local p = require("catppuccin.palettes").get_palette()
        if p then
          c.bg      = p.base
          c.fg      = p.text
          c.surface = p.surface1
          c.overlay = p.overlay0
          c.blue    = p.blue
          c.green   = p.green
          c.yellow  = p.yellow
          c.red     = p.red
          c.mauve   = p.mauve
          c.peach   = p.peach
          c.teal    = p.teal
          c.sky     = p.sky
          c.sapph   = p.sapphire
          c.pink    = p.pink
          c.lavend  = p.lavender
        end
      end)
  
      -- ── Mode colour map ──────────────────────────────────────────────────────
      local mode_colours = {
        n      = c.blue,
        i      = c.green,
        v      = c.mauve,
        V      = c.mauve,
        ["\22"] = c.mauve,
        c      = c.yellow,
        s      = c.peach,
        S      = c.peach,
        ["\19"] = c.peach,
        R      = c.red,
        r      = c.red,
        ["!"]  = c.red,
        t      = c.teal,
      }
  
      local function mode_colour()
        return mode_colours[vim.fn.mode()] or c.blue
      end
  
      -- ── Custom components ────────────────────────────────────────────────────
  
      -- Mode pill
      local mode_component = {
        function()
          local mode_map = {
            n      = icons.status.modes.NORMAL,
            i      = icons.status.modes.INSERT,
            v      = icons.status.modes.VISUAL,
            V      = icons.status.modes.V_LINE,
            ["\22"] = icons.status.modes.V_BLOCK,
            c      = icons.status.modes.COMMAND,
            s      = icons.status.modes.SELECT,
            S      = icons.status.modes.SELECT,
            R      = icons.status.modes.REPLACE,
            t      = icons.status.modes.TERMINAL,
          }
          return mode_map[vim.fn.mode()] or "  " .. vim.fn.mode():upper()
        end,
        color     = function() return { bg = mode_colour(), fg = c.bg, gui = "bold" } end,
        separator = { left = "", right = "" },
        padding   = { left = 0, right = 0 },
      }
  
      -- Macro recording
      local macro_component = {
        function()
          local reg = vim.fn.reg_recording()
          if reg == "" then return "" end
          return icons.ui.Circle .. " REC @" .. reg
        end,
        color   = { fg = c.red, gui = "bold" },
        cond    = function() return vim.fn.reg_recording() ~= "" end,
      }
  
      -- LSP clients
      local lsp_component = {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then
            return icons.status.lsp_inactive
          end
          local names = vim.tbl_map(function(c2) return c2.name end, clients)
          -- Deduplicate
          local seen, unique = {}, {}
          for _, n in ipairs(names) do
            if not seen[n] then seen[n] = true; unique[#unique + 1] = n end
          end
          -- Truncate if too many
          if #unique > 3 then
            unique = vim.list_slice(unique, 1, 3)
            unique[#unique + 1] = "+" .. (#clients - 3)
          end
          return icons.status.lsp_active .. table.concat(unique, ", ")
        end,
        color  = { fg = c.sapph },
        cond   = function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end,
      }
  
      -- Formatter
      local formatter_component = {
        function()
          local ok, conform = pcall(require, "conform")
          if not ok then return "" end
          local fmts = conform.list_formatters(0)
          if #fmts == 0 then return "" end
          local names = vim.tbl_map(function(f) return f.name end, fmts)
          return icons.status.formatter .. table.concat(names, ",")
        end,
        color  = { fg = c.teal },
        cond   = function()
          local ok, conform = pcall(require, "conform")
          if not ok then return false end
          return #conform.list_formatters(0) > 0
        end,
      }
  
      -- DAP status
      local dap_component = {
        function()
          local ok, dap = pcall(require, "dap")
          if not ok then return "" end
          local session = dap.session()
          if not session then return "" end
          return icons.dap.play .. " " .. session.config.name
        end,
        color  = { fg = c.yellow, gui = "bold" },
        cond   = function()
          local ok, dap = pcall(require, "dap")
          return ok and dap.session() ~= nil
        end,
      }
  
      -- AI / Copilot status with spinner
      local _spinner_idx = 0
      local ai_component = {
        function()
          local provider = Ash.ai.provider
          if provider == "copilot" then
            local ok, status = pcall(require, "copilot.api")
            if ok then
              local st = status.status and status.status.data
              if st == "InProgress" then
                _spinner_idx = (_spinner_idx % #icons.misc.spinner) + 1
                return icons.misc.spinner[_spinner_idx]
                    .. " " .. icons.misc.copilot
              end
              return icons.misc.copilot .. (st == "Warning" and "!" or "")
            end
          elseif provider == "codeium" then
            local ok, api = pcall(require, "codeium.api")
            if ok and api then
              return icons.misc.codeium
            end
          end
          return icons.misc.ai
        end,
        color = { fg = c.mauve },
      }
  
      -- ASH mode indicator
      local ash_mode_component = {
        function()
          local mode_icons = {
            game       = "󰊗 GAME",
            work       = "󰂓 WORK",
            focus      = "󰁌 FOCUS",
            cinema     = " CINEMA",
            stream     = "󰑋 STREAM",
            battery    = " BATTERY",
            privacy    = " PRIVACY",
            present    = "󱉟 PRESENT",
            default    = " DEFAULT",
          }
          local m = vim.env.ASH_MODE or "default"
          return mode_icons[m] or (" " .. m:upper())
        end,
        color = { fg = c.lavend, gui = "italic" },
        cond  = function()
          return vim.env.ASH_MODE ~= nil and vim.env.ASH_MODE ~= "default"
        end,
      }
  
      -- File encoding + EOL
      local encoding_component = {
        function()
          local enc  = (vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.enc):upper()
          local ff   = vim.bo.fileformat
          local eol_icon = {
            unix = icons.status.line_ending_unix,
            dos  = icons.status.line_ending_win,
            mac  = icons.status.line_ending_mac,
          }
          return enc .. " " .. (eol_icon[ff] or ff)
        end,
        cond  = function() return vim.fn.winwidth(0) > 70 end,
        color = { fg = c.overlay },
      }
  
      -- Scroll percentage with bar
      local scroll_component = {
        function()
          local cur  = vim.fn.line(".")
          local tot  = vim.fn.line("$")
          local pct  = math.floor(cur / tot * 100)
          local bars = { "▁","▂","▃","▄","▅","▆","▇","█" }
          local bar  = bars[math.ceil(pct / 100 * #bars)] or bars[1]
          if cur == 1   then return " TOP" end
          if cur == tot then return " BOT" end
          return bar .. " " .. string.format("%3d%%", pct)
        end,
        color  = function()
          return { fg = mode_colour(), bg = c.surface }
        end,
        separator = { left = "", right = "" },
      }
  
      -- ── Lualine theme ────────────────────────────────────────────────────────
      local theme = {
        normal = {
          a = { bg = c.blue,   fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
          c = { bg = c.bg,     fg = c.fg                    },
        },
        insert = {
          a = { bg = c.green,  fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
        },
        visual = {
          a = { bg = c.mauve,  fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
        },
        replace = {
          a = { bg = c.red,    fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
        },
        command = {
          a = { bg = c.yellow, fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
        },
        terminal = {
          a = { bg = c.teal,   fg = c.bg,      gui = "bold" },
          b = { bg = c.surface, fg = c.fg                   },
        },
        inactive = {
          a = { bg = c.bg,     fg = c.overlay               },
          b = { bg = c.bg,     fg = c.overlay               },
          c = { bg = c.bg,     fg = c.overlay               },
        },
      }
  
      -- ── Sections ─────────────────────────────────────────────────────────────
      return {
        options = {
          theme                 = theme,
          globalstatus          = true,
          always_divide_middle  = true,
          refresh               = { statusline = 100, tabline = 1000, winbar = 1000 },
          component_separators  = { left = "", right = "" },
          section_separators    = { left = "", right = "" },
          disabled_filetypes    = {
            statusline = {
              "alpha", "dashboard", "neo-tree", "Trouble",
              "lazy", "mason", "notify", "toggleterm",
              "lazyterm", "aerial",
            },
            winbar = {},
          },
          ignore_focus          = {
            "neo-tree", "aerial", "toggleterm",
          },
        },
  
        sections = {
          -- ── LEFT ─────────────────────────────────────────────────────────
          lualine_a = {
            mode_component,
          },
          lualine_b = {
            {
              "branch",
              icon  = icons.git.branch,
              color = { fg = c.peach, gui = "bold" },
            },
            {
              "diff",
              symbols = {
                added    = icons.git.added,
                modified = icons.git.changed,
                removed  = icons.git.removed,
              },
              diff_color = {
                added    = { fg = c.green  },
                modified = { fg = c.yellow },
                removed  = { fg = c.red    },
              },
              source = function()
                local gs = vim.b.gitsigns_status_dict
                if not gs then return nil end
                return {
                  added    = gs.added,
                  modified = gs.changed,
                  removed  = gs.removed,
                }
              end,
            },
            macro_component,
            dap_component,
          },
          lualine_c = {
            {
              "filetype",
              icon_only = true,
              separator = "",
              padding   = { left = 1, right = 0 },
            },
            {
              "filename",
              file_status    = true,
              newfile_status = true,
              path           = 1,
              shorting_target = 40,
              symbols = {
                modified  = icons.status.file_modified,
                readonly  = icons.status.file_readonly,
                unnamed   = "[No Name]",
                newfile   = icons.status.file_new,
              },
              color = { fg = c.fg, gui = "bold" },
            },
          },
  
          -- ── RIGHT ────────────────────────────────────────────────────────
          lualine_x = {
            ash_mode_component,
            ai_component,
            formatter_component,
            lsp_component,
            {
              "diagnostics",
              sources         = { "nvim_lsp", "nvim_diagnostic" },
              symbols = {
                error = icons.diagnostics.Error,
                warn  = icons.diagnostics.Warn,
                info  = icons.diagnostics.Info,
                hint  = icons.diagnostics.Hint,
              },
              diagnostics_color = {
                error = { fg = c.red    },
                warn  = { fg = c.yellow },
                info  = { fg = c.sapph  },
                hint  = { fg = c.teal   },
              },
              update_in_insert = false,
            },
          },
          lualine_y = {
            {
              "searchcount",
              icon  = icons.ui.Search,
              color = { fg = c.yellow },
              maxcount = 999,
            },
            {
              "selectioncount",
              icon  = icons.ui.Eye,
              color = { fg = c.mauve },
            },
            encoding_component,
            {
              "filesize",
              icon  = icons.ui.File,
              color = { fg = c.overlay },
              cond  = function() return vim.fn.winwidth(0) > 80 end,
            },
          },
          lualine_z = {
            {
              "location",
              icon  = icons.status.line,
              color = function()
                return { bg = mode_colour(), fg = c.bg, gui = "bold" }
              end,
              separator = { left = "", right = "" },
            },
            scroll_component,
          },
        },
  
        -- ── Inactive sections ─────────────────────────────────────────────────
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {
            {
              "filename",
              path  = 1,
              color = { fg = c.overlay },
            },
          },
          lualine_x = {
            {
              "location",
              color = { fg = c.overlay },
            },
          },
          lualine_y = {},
          lualine_z = {},
        },
  
        -- ── Extensions ────────────────────────────────────────────────────────
        extensions = {
          "lazy",
          "mason",
          "neo-tree",
          "trouble",
          "toggleterm",
          "quickfix",
          "fugitive",
          "nvim-dap-ui",
          "aerial",
          "oil",
          "man",
        },
      }
    end,
  }