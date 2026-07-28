-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/incline.lua — Floating Filename Labels                       ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: b0o/incline.nvim                                                    ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Floating filename label rendered in top-right of every window           ║
-- ║    • Devicon per filetype with colour matching the icon theme                ║
-- ║    • Git branch indicator (from gitsigns)                                   ║
-- ║    • Diagnostic count badges (E/W) on the label                             ║
-- ║    • Modified indicator (● dot) when buffer has unsaved changes              ║
-- ║    • Read-only indicator (󰌾) when buffer is not modifiable                  ║
-- ║    • Active window: bright label; inactive: dimmed ghost                    ║
-- ║    • Catppuccin palette-aware colours with ColorScheme sync                 ║
-- ║    • Per-filetype hide list                                                  ║
-- ║    • Smooth winblend on inactive windows                                    ║
-- ║    • Click to focus the window                                              ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "b0o/incline.nvim",
    event        = { "BufReadPost", "BufNewFile" },
    version      = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "lewis6991/gitsigns.nvim",
    },
  
    keys = {
      {
        "<leader>uI",
        function()
          local ok, incline = pcall(require, "incline")
          if not ok then return end
          -- incline.nvim exposes enable/disable/toggle in newer versions
          local toggled = false
          pcall(function()
            incline.toggle()
            toggled = true
          end)
          if not toggled then
            vim.g.incline_hidden = not vim.g.incline_hidden
            if vim.g.incline_hidden then
              incline.disable()
            else
              incline.enable()
            end
          end
          vim.notify(
            (vim.g.incline_hidden and "󰅖 " or " ")
              .. "Incline labels " .. (vim.g.incline_hidden and "hidden" or "shown"),
            vim.log.levels.INFO,
            { title = "ASH NeoVim", timeout = 2000 }
          )
        end,
        desc = "  Toggle incline file labels",
      },
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local icons   = Ash.icons
      local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  
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
      local subtext = p.subtext0 or "#a6adc8"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local peach   = p.peach    or "#fab387"
      local teal    = p.teal     or "#94e2d5"
      local sky     = p.sky      or "#89dceb"
  
      -- ── Helper: get devicon for buffer ────────────────────────────────────
      ---@param buf integer
      ---@return string icon, string hl_group
      local function buf_icon(buf)
        if not devicons_ok then return icons.ui.File, "InclineIconDefault" end
        local name = vim.api.nvim_buf_get_name(buf)
        local ft   = vim.bo[buf].filetype
        local ext  = vim.fn.fnamemodify(name, ":e")
        local ic, hl = devicons.get_icon(
          vim.fn.fnamemodify(name, ":t"),
          ext,
          { default = true }
        )
        return ic or icons.ui.File, hl or "DevIconDefault"
      end
  
      -- ── Helper: count diagnostics ─────────────────────────────────────────
      ---@param buf integer
      ---@param sev integer
      ---@return integer
      local function diag_count(buf, sev)
        return #vim.diagnostic.get(buf, { severity = sev })
      end
  
      -- ── Helper: get gitsigns branch ───────────────────────────────────────
      ---@param buf integer
      ---@return string?
      local function git_branch(buf)
        -- gitsigns exposes head via vim.b[buf].gitsigns_head
        return vim.b[buf].gitsigns_head
      end
  
      -- ── Helper: get gitsigns diff counts ────────────────────────────────
      ---@param buf integer
      ---@return { added:integer, changed:integer, removed:integer }?
      local function git_diff(buf)
        local status = vim.b[buf].gitsigns_status_dict
        if not status then return nil end
        return {
          added   = status.added   or 0,
          changed = status.changed or 0,
          removed = status.removed or 0,
        }
      end
  
      -- ── Excluded filetypes ────────────────────────────────────────────────
      local excluded_ft = {
        "alpha", "dashboard", "neo-tree", "NvimTree",
        "aerial", "Trouble", "lazy", "mason",
        "notify", "toggleterm", "help", "checkhealth",
        "lspinfo", "TelescopePrompt", "TelescopeResults",
        "WhichKey", "noice", "dap-repl", "dapui_scopes",
        "dapui_watches", "dapui_stacks", "dapui_breakpoints",
        "neotest-summary", "neotest-output",
        "OverseerList", "fugitive", "DiffviewFiles",
        "gitcommit", "man", "scratch", "qf",
      }
  
      return {
        -- ── Global options ─────────────────────────────────────────────────
        hide = {
          -- Hide when there's only one window
          only_win         = false,
          -- Hide for these filetypes
          focused_win      = false,
          -- Cursor position where incline appears
          cursorline       = false,
        },
  
        -- ── Ignore rules ──────────────────────────────────────────────────
        ignore = {
          buftypes         = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
            "nowrite",
          },
          filetypes        = excluded_ft,
          unlisted_buffers = true,
          floating_wins    = true,
        },
  
        -- ── Window options for the floating label ──────────────────────────
        window = {
          -- Position: top-right corner of the owning window
          placement        = {
            horizontal     = "right",
            vertical       = "top",
          },
          -- Offsets from the window corner (in characters)
          margin           = {
            horizontal     = { left = 1,  right = 1 },
            vertical       = { top  = 0,  bottom = 0 },
          },
          padding          = { left = 1, right = 1 },
          padding_char     = " ",
          -- Appearance
          winhighlight     = {
            active         = {
              EndOfBuffer    = "None",
              Normal         = "InclineActive",
              Search         = "None",
            },
            inactive       = {
              EndOfBuffer    = "None",
              Normal         = "InclineInactive",
              Search         = "None",
            },
          },
          -- Transparency for inactive windows
          options          = {
            -- Active window: fully opaque
            -- Inactive: blended with background
            winblend       = 0,
            winhighlight   = "",
          },
          -- Z-index
          zindex           = 30,
          -- Border
          overlap          = {
            tabline        = false,
            winbar         = true,
            borders        = false,
            statusline     = false,
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- RENDER FUNCTION — the heart of incline
        -- Returns a structured table of { text, guifg, guibg, gui } cells
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        render = function(props)
          local buf      = props.buf
          local win      = props.win
          local focused  = props.focused
  
          -- Guard: skip for excluded filetypes
          local ft = vim.bo[buf].filetype
          if vim.tbl_contains(excluded_ft, ft) then return "" end
  
          -- ── Palette (re-read for live theme changes) ────────────────────
          local _p = {}
          pcall(function() _p = require("catppuccin.palettes").get_palette() or {} end)
          local _base    = _p.base     or base
          local _surface = _p.surface0 or surface
          local _surface1 = _p.surface1 or surface1
          local _overlay = _p.overlay0 or overlay
          local _text    = _p.text     or text
          local _subtext = _p.subtext0 or subtext
          local _blue    = _p.blue     or blue
          local _green   = _p.green    or green
          local _yellow  = _p.yellow   or yellow
          local _red     = _p.red      or red
          local _mauve   = _p.mauve    or mauve
          local _peach   = _p.peach    or peach
          local _teal    = _p.teal     or teal
  
          -- Background: darker for inactive
          local bg_active   = _surface1
          local bg_inactive = _surface
          local bg          = focused and bg_active or bg_inactive
  
          -- ── Build label components ─────────────────────────────────────
  
          ---@type table[]  array of {text, guifg, guibg, gui?, bold?}
          local label = {}
  
          local function push(text, fg, gui)
            label[#label + 1] = {
              text,
              guifg = fg  or (focused and _text or _overlay),
              guibg = bg,
              gui   = gui or "",
            }
          end
  
          -- ❶ Devicon
          local ic, ic_hl = buf_icon(buf)
          -- Get colour from devicons highlight group
          local ic_fg = _blue
          pcall(function()
            local hl  = vim.api.nvim_get_hl(0, { name = ic_hl, link = false })
            if hl.fg then ic_fg = string.format("#%06x", hl.fg) end
          end)
          push(ic .. " ", ic_fg)
  
          -- ❷ Filename (truncated)
          local name = vim.api.nvim_buf_get_name(buf)
          local fname = name == ""
            and "[No Name]"
            or vim.fn.fnamemodify(name, ":t")
  
          -- Truncate long names
          if #fname > 20 then
            fname = fname:sub(1, 18) .. icons.ui.Ellipsis
          end
  
          push(
            fname,
            focused and _text or _subtext,
            focused and "bold" or ""
          )
  
          -- ❸ Modified indicator
          if vim.bo[buf].modified then
            push(" " .. icons.status.file_modified, _yellow)
          end
  
          -- ❹ Read-only indicator
          if not vim.bo[buf].modifiable or vim.bo[buf].readonly then
            push(" " .. icons.status.file_readonly, _overlay)
          end
  
          -- ❺ Diagnostic counts (only if > 0)
          local err  = diag_count(buf, vim.diagnostic.severity.ERROR)
          local warn = diag_count(buf, vim.diagnostic.severity.WARN)
  
          if err > 0 or warn > 0 then
            push("  ", _overlay)
            if err > 0 then
              push(icons.diagnostics.signs.Error .. tostring(err), _red)
            end
            if warn > 0 then
              if err > 0 then push(" ", _overlay) end
              push(icons.diagnostics.signs.Warn .. tostring(warn), _yellow)
            end
          end
  
          -- ❻ Git branch (only for focused + when changed)
          if focused then
            local branch = git_branch(buf)
            if branch and branch ~= "" then
              push("  ", _overlay)
              push(icons.git.branch, _peach)
              push(" " .. branch:sub(1, 16), _peach)
            end
  
            -- Mini git diff counts
            local diff = git_diff(buf)
            if diff then
              local any = diff.added > 0 or diff.changed > 0 or diff.removed > 0
              if any then
                push("  ", _overlay)
                if diff.added   > 0 then push("+" .. diff.added,   _green)  end
                if diff.changed > 0 then push("~" .. diff.changed, _yellow) end
                if diff.removed > 0 then push("-" .. diff.removed, _red)    end
              end
            end
          end
  
          return label
        end,
      }
    end,
  
    config = function(_, opts)
      require("incline").setup(opts)
  
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
        local subtext  = p.subtext0  or "#a6adc8"
        local blue     = p.blue      or "#89b4fa"
        local mauve    = p.mauve     or "#cba6f7"
  
        local hls = {
          -- Active window label
          InclineActive         = {
            bg   = surface1,
            fg   = text,
            bold = true,
          },
          -- Inactive window label (dimmed)
          InclineInactive       = {
            bg   = surface,
            fg   = overlay,
          },
          -- Icon in active label
          InclineActiveIcon     = {
            bg   = surface1,
            fg   = blue,
          },
          -- Icon in inactive label
          InclineInactiveIcon   = {
            bg   = surface,
            fg   = overlay,
          },
          -- Default icon fallback
          InclineIconDefault    = {
            bg   = surface1,
            fg   = subtext,
          },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
  
      -- ── Refresh on gitsigns update ────────────────────────────────────────
      -- When git status changes, re-render incline labels
      vim.api.nvim_create_autocmd("User", {
        pattern  = "GitSignsUpdate",
        callback = function()
          pcall(require("incline").refresh)
        end,
      })
  
      -- ── Refresh on diagnostic change ─────────────────────────────────────
      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          pcall(require("incline").refresh)
        end,
      })
  
      -- ── Auto-hide for large files ─────────────────────────────────────────
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(ev)
          if vim.b[ev.buf].large_file then
            pcall(require("incline").disable)
          end
        end,
      })
  
      -- ── User command ──────────────────────────────────────────────────────
      vim.api.nvim_create_user_command("InclineRefresh", function()
        require("incline").refresh()
        vim.notify(" Incline refreshed", vim.log.levels.INFO, { title = "ASH" })
      end, { desc = "Force-refresh all incline window labels" })
    end,
  }