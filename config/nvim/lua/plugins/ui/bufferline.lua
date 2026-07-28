-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/bufferline.lua — Tab / Buffer Line                          ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: akinsho/bufferline.nvim                                             ║
-- ║  Features:                                                                   ║
-- ║    • Slanted / powerline tab separators (theme-aware)                       ║
-- ║    • Devicon per buffer                                                      ║
-- ║    • Modified indicator with animated dot                                   ║
-- ║    • Pinned buffer support                                                   ║
-- ║    • Diagnostics badge (E W I H counts)                                     ║
-- ║    • Right-click context menu (close, pin, move)                            ║
-- ║    • Groups: tests, docs, config                                            ║
-- ║    • Custom close & duplicate buttons                                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "akinsho/bufferline.nvim",
    version = "*",
    event   = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "echasnovski/mini.bufremove",
    },
    keys = {
      { "<S-h>",         "<Cmd>BufferLineCyclePrev<CR>",           desc = "  Prev buffer"            },
      { "<S-l>",         "<Cmd>BufferLineCycleNext<CR>",           desc = "  Next buffer"            },
      { "[b",            "<Cmd>BufferLineCyclePrev<CR>",           desc = "  Prev buffer"            },
      { "]b",            "<Cmd>BufferLineCycleNext<CR>",           desc = "  Next buffer"            },
      { "<leader>bd",    "<Cmd>BufferLinePickClose<CR>",           desc = "  Pick buffer to close"   },
      { "<leader>bp",    "<Cmd>BufferLineTogglePin<CR>",           desc = "  Toggle pin buffer"      },
      { "<leader>bo",    "<Cmd>BufferLineCloseOthers<CR>",         desc = "  Close other buffers"    },
      { "<leader>bL",    "<Cmd>BufferLineCloseRight<CR>",          desc = "  Close buffers to right" },
      { "<leader>bH",    "<Cmd>BufferLineCloseLeft<CR>",           desc = "  Close buffers to left"  },
      { "<leader>b]",    "<Cmd>BufferLineMoveNext<CR>",            desc = "  Move buffer right"      },
      { "<leader>b[",    "<Cmd>BufferLineMovePrev<CR>",            desc = "  Move buffer left"       },
      { "<leader>bs",    "<Cmd>BufferLinePick<CR>",                desc = "  Pick buffer"            },
      { "<leader>b1",    "<Cmd>BufferLineGoToBuffer 1<CR>",        desc = "  Buffer 1"               },
      { "<leader>b2",    "<Cmd>BufferLineGoToBuffer 2<CR>",        desc = "  Buffer 2"               },
      { "<leader>b3",    "<Cmd>BufferLineGoToBuffer 3<CR>",        desc = "  Buffer 3"               },
      { "<leader>b4",    "<Cmd>BufferLineGoToBuffer 4<CR>",        desc = "  Buffer 4"               },
      { "<leader>b5",    "<Cmd>BufferLineGoToBuffer 5<CR>",        desc = "  Buffer 5"               },
      { "<leader>b$",    "<Cmd>BufferLineGoToBuffer -1<CR>",       desc = "  Last buffer"            },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Diagnostic count helper ──────────────────────────────────────────────
      ---@param buf integer
      ---@param sev integer  vim.diagnostic.severity.*
      ---@return integer
      local function diag_count(buf, sev)
        return #vim.diagnostic.get(buf, { severity = sev })
      end
  
      -- ── Custom close button ──────────────────────────────────────────────────
      ---@param buf integer
      local function close_buf(buf)
        local ok, mini = pcall(require, "mini.bufremove")
        if ok then
          if vim.bo[buf].modified then
            local choice = vim.fn.confirm(
              'Save changes to "' .. vim.fn.bufname(buf) .. '"?',
              "&Yes\n&No\n&Cancel"
            )
            if choice == 1 then
              vim.api.nvim_buf_call(buf, function() vim.cmd("w") end)
              mini.delete(buf, false)
            elseif choice == 2 then
              mini.delete(buf, true)
            end
          else
            mini.delete(buf, false)
          end
        else
          vim.cmd("bdelete " .. buf)
        end
      end
  
      return {
        options = {
          -- ── Layout ────────────────────────────────────────────────────────
          mode              = "buffers",
          themable          = true,
          numbers           = function(o)
            return string.format("%s", o.id)
          end,
          -- Separators
          indicator         = {
            icon  = "▎",
            style = "icon",
          },
          buffer_close_icon = icons.ui.Close,
          modified_icon     = icons.ui.tab.modified,
          close_icon        = icons.ui.Close,
          left_trunc_marker = icons.ui.BoldArrowLeft,
          right_trunc_marker = icons.ui.BoldArrowRight,
          -- Widths
          max_name_length   = 18,
          max_prefix_length = 13,
          truncate_names    = true,
          tab_size          = 22,
          -- Padding
          padding           = { left = 1, right = 1 },
          -- ── Offsets (side panels) ────────────────────────────────────────
          offsets           = {
            {
              filetype   = "neo-tree",
              text       = icons.ui.Tree .. "  Explorer",
              text_align = "center",
              separator  = true,
              highlight  = "BufferLineOffsetSeparator",
            },
            {
              filetype   = "aerial",
              text       = icons.ui.List .. "  Outline",
              text_align = "center",
              separator  = true,
            },
            {
              filetype   = "undotree",
              text       = icons.ui.History .. "  Undo History",
              text_align = "center",
              separator  = true,
            },
            {
              filetype   = "Outline",
              text       = icons.ui.List .. "  Symbols",
              text_align = "center",
              separator  = true,
            },
            {
              filetype   = "dapui_scopes",
              text       = icons.dap.play .. "  Debugger",
              text_align = "center",
              separator  = true,
            },
          },
          -- ── Icons ────────────────────────────────────────────────────────
          show_buffer_icons       = true,
          show_buffer_close_icons = true,
          show_close_icon         = false,
          show_tab_indicators     = true,
          show_duplicate_prefix   = true,
          get_element_icon        = function(buf)
            local ok, devicons = pcall(require, "nvim-web-devicons")
            if not ok then return "", "" end
            local icon, hl = devicons.get_icon_by_filetype(
              vim.bo[buf.id and buf.id or 0].filetype,
              { default = true }
            )
            return icon, hl
          end,
          -- ── Diagnostics ──────────────────────────────────────────────────
          diagnostics               = "nvim_lsp",
          diagnostics_update_in_insert = false,
          diagnostics_update_on_event  = true,
          diagnostics_indicator     = function(count, level, _buf_diag, _ctx)
            local sev = vim.diagnostic.severity
            local icon_map = {
              [sev.ERROR] = icons.diagnostics.signs.Error,
              [sev.WARN]  = icons.diagnostics.signs.Warn,
              [sev.INFO]  = icons.diagnostics.signs.Info,
              [sev.HINT]  = icons.diagnostics.signs.Hint,
            }
            return (icon_map[level] or "") .. count
          end,
          -- ── Pinned buffers ────────────────────────────────────────────────
          sort_by                   = function(a, b)
            -- Pinned buffers always first
            if a.pinned and not b.pinned then return true end
            if not a.pinned and b.pinned then return false end
            return a.id < b.id
          end,
          -- ── Custom close ─────────────────────────────────────────────────
          close_command             = close_buf,
          right_mouse_command       = function(buf)
            -- Minimal right-click context menu
            local choices = {
              "Close buffer",
              "Close others",
              "Close to the right",
              "Pin / Unpin",
              "Copy path",
            }
            vim.ui.select(choices, {
              prompt = "  Buffer menu",
              kind   = "ash_bufferline",
            }, function(choice)
              if not choice then return end
              if choice == "Close buffer" then
                close_buf(buf)
              elseif choice == "Close others" then
                vim.cmd("BufferLineCloseOthers")
              elseif choice == "Close to the right" then
                vim.cmd("BufferLineCloseRight")
              elseif choice == "Pin / Unpin" then
                vim.cmd("BufferLineTogglePin")
              elseif choice == "Copy path" then
                local path = vim.api.nvim_buf_get_name(buf)
                vim.fn.setreg("+", path)
                vim.notify(" Copied: " .. path, vim.log.levels.INFO, { title = "ASH" })
              end
            end)
          end,
          -- ── Groups (visual sections) ─────────────────────────────────────
          groups = {
            options = { toggle_hidden_on_enter = true },
            items   = {
              -- Test files
              require("bufferline.groups").builtin.pinned:with({
                icon = icons.ui.Pin,
              }),
              {
                name      = "Tests",
                icon      = icons.test.suite,
                highlight = { sp = "#a6e3a1", underline = true },
                priority  = 2,
                matcher   = function(buf)
                  return buf.filename:match("_spec")
                      or buf.filename:match("_test")
                      or buf.filename:match("%.test%.")
                      or buf.filename:match("%.spec%.")
                end,
              },
              {
                name      = "Docs",
                icon      = icons.ui.Note,
                highlight = { sp = "#89b4fa", underline = true },
                priority  = 1,
                matcher   = function(buf)
                  return buf.filename:match("%.md$")
                      or buf.filename:match("%.rst$")
                      or buf.filename:match("%.org$")
                      or buf.filename:match("%.norg$")
                end,
              },
              {
                name      = "Config",
                icon      = icons.ui.Gear,
                highlight = { sp = "#fab387", underline = true },
                priority  = 0,
                matcher   = function(buf)
                  return buf.filename:match("%.json$")
                      or buf.filename:match("%.toml$")
                      or buf.filename:match("%.ya?ml$")
                      or buf.filename:match("%.conf$")
                      or buf.filename:match("%.ini$")
                      or buf.filename:match("%.env")
                end,
              },
            },
          },
          -- ── Misc ─────────────────────────────────────────────────────────
          persist_buffer_sort       = true,
          move_wraps_at_ends        = true,
          color_icons               = true,
          separator_style           = "slant",
          enforce_regular_tabs      = false,
          always_show_bufferline    = true,
          hover = {
            enabled = true,
            delay   = 150,
            reveal  = { "close" },
          },
        },
  
        -- ── Highlight groups (populated from catppuccin at config time) ──────
        highlights = require("catppuccin.groups.integrations.bufferline").get(),
      }
    end,
  
    config = function(_, opts)
      -- Merge catppuccin highlights if available, else use defaults
      local ok, _ = pcall(function()
        opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
      end)
      if not ok then
        opts.highlights = nil -- let bufferline pick automatically
      end
  
      require("bufferline").setup(opts)
  
      -- Ensure tabline is always visible
      vim.opt.showtabline = 2
  
      -- Re-init on colorscheme change
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local ok2, cat = pcall(function()
            return require("catppuccin.groups.integrations.bufferline").get()
          end)
          require("bufferline").setup(vim.tbl_deep_extend("force", opts, {
            highlights = ok2 and cat or {},
          }))
        end,
      })
    end,
  }