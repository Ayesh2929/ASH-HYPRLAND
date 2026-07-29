-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/ui/alpha.lua — Dashboard / Startscreen                         ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: goolord/alpha-nvim                                                  ║
-- ║  Features:                                                                   ║
-- ║    • Animated ASCII art header (ASH logo)                                   ║
-- ║    • Dynamic greeting by time-of-day with emoji                             ║
-- ║    • Recent files with devicon prefix                                        ║
-- ║    • Quick-action buttons with live keybind hints                           ║
-- ║    • Session restore button                                                  ║
-- ║    • Live stats: plugins loaded, startup time, theme                        ║
-- ║    • Footer with fortune / motivational quote                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "goolord/alpha-nvim",
    event       = "VimEnter",
    priority    = 100,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-lua/plenary.nvim",
    },
  
    -- ── opts ──────────────────────────────────────────────────────────────────
    opts = function()
      local dashboard = require("alpha.themes.dashboard")
      local icons     = Ash.icons
  
      -- ── Helpers ─────────────────────────────────────────────────────────────
  
      ---Return greeting + emoji based on current hour
      ---@return string
      local function greeting()
        local hour = tonumber(os.date("%H"))
        if hour >= 5  and hour < 12 then return "  Good morning"   end
        if hour >= 12 and hour < 17 then return "  Good afternoon" end
        if hour >= 17 and hour < 21 then return "  Good evening"   end
        return "  Good night"
      end
  
      ---Pad a string to `width` chars, centered
      ---@param s     string
      ---@param width integer
      ---@return      string
      local function center(s, width)
        width = width or 60
        local pad = math.floor((width - #s) / 2)
        return string.rep(" ", math.max(0, pad)) .. s
      end
  
      ---Build a button spec for alpha
      ---@param sc    string  Shortcut key text
      ---@param txt   string  Button label
      ---@param keybind string  Vim keymap to execute
      ---@param opts  table?
      local function button(sc, txt, keybind, opts)
        local b = dashboard.button(sc, txt, keybind, opts)
        b.opts.hl        = "AlphaButton"
        b.opts.hl_shortcut = "AlphaShortcut"
        b.opts.position  = "center"
        b.opts.width     = 54
        b.opts.cursor    = 3
        b.opts.shortcut  = "[" .. sc .. "]"
        b.opts.align_shortcut = "right"
        return b
      end
  
      -- ── Header: ASH LOGO ────────────────────────────────────────────────────
      -- Carefully crafted Nerd-Font-compatible gradient ASCII art
      -- Width: 60 chars (padded to terminal centre by alpha)
  
      local header_lines = {
        [[                                                      ]],
        [[  ░█████╗░░██████╗██╗░░██╗  ██████╗░░█████╗░████████╗]],
        [[  ██╔══██╗██╔════╝██║░░██║  ██╔══██╗██╔══██╗╚══██╔══╝]],
        [[  ███████║╚█████╗░███████║  ██║░░██║██║░░██║░░░██║░░░]],
        [[  ██╔══██║░╚═══██╗██╔══██║  ██║░░██║██║░░██║░░░██║░░░]],
        [[  ██║░░██║██████╔╝██║░░██║  ██████╔╝╚█████╔╝░░░██║░░░]],
        [[  ╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝  ╚═════╝░░╚════╝░░░░╚═╝░░░]],
        [[                                                      ]],
        [[  ███████╗██╗██╗░░░░░███████╗░██████╗                 ]],
        [[  ██╔════╝██║██║░░░░░██╔════╝██╔════╝                 ]],
        [[  █████╗░░██║██║░░░░░█████╗░░╚█████╗░                 ]],
        [[  ██╔══╝░░██║██║░░░░░██╔══╝░░░╚═══██╗                 ]],
        [[  ██║░░░░░██║███████╗███████╗██████╔╝                 ]],
        [[  ╚═╝░░░░░╚═╝╚══════╝╚══════╝╚═════╝░                 ]],
        [[                                                      ]],
      }
  
      -- ── Sub-header (dynamic) ────────────────────────────────────────────────
      local function sub_header()
        local theme   = Ash.theme or "default"
        local version = Ash.version or "5.0.0"
        return {
          center(greeting() .. ",  " .. (vim.env.USER or "coder") .. "!", 60),
          center("", 60),
          center(
            icons.ui.Rocket .. " v" .. version
              .. "  " .. icons.ui.Star .. " " .. theme
              .. "  " .. icons.misc.lazy .. " " .. (
                pcall(require, "lazy") and tostring(require("lazy").stats().count) or "?"
              ) .. " plugins",
            60
          ),
          center("", 60),
        }
      end
  
      -- ── Buttons ─────────────────────────────────────────────────────────────
      local buttons = {
        button("e",       icons.ui.FileNew      .. "  New file",          "<Cmd>ene <BAR> startinsert<CR>"),
        button("f",       icons.ui.FindFile     .. "  Find file",         "<Cmd>Telescope find_files<CR>"),
        button("r",       icons.ui.History      .. "  Recent files",      "<Cmd>Telescope oldfiles<CR>"),
        button("g",       icons.ui.FindText     .. "  Find text",         "<Cmd>Telescope live_grep<CR>"),
        button("s",       icons.ui.BookMark     .. "  Restore session",   "<Cmd>lua require('persistence').load()<CR>"),
        button("p",       icons.misc.lazy       .. "  Plugin manager",    "<Cmd>Lazy<CR>"),
        button("m",       icons.misc.mason      .. "  Mason (LSP tools)", "<Cmd>Mason<CR>"),
        button("t",       icons.ui.Gear         .. "  ASH theme picker",  "<Cmd>lua require('telescope').extensions.themes.themes()<CR>"),
        button("c",       icons.ui.Settings     .. "  Edit config",       "<Cmd>e " .. vim.fn.stdpath("config") .. "/init.lua<CR>"),
        button("h",       icons.ui.Shield       .. "  Health check",      "<Cmd>checkhealth ash<CR>"),
        button("u",       icons.ui.Refresh      .. "  Update plugins",    "<Cmd>Lazy update<CR>"),
        button("q",       icons.ui.Power        .. "  Quit",              "<Cmd>qa<CR>"),
      }
  
      -- ── Footer ──────────────────────────────────────────────────────────────
      local function footer()
        -- Pull lazy.nvim stats if available
        local stats_line = ""
        local ok, lazy = pcall(require, "lazy")
        if ok then
          local s = lazy.stats()
          stats_line = string.format(
            icons.misc.lazy .. " %d plugins  ⚡ loaded in %.0fms",
            s.count,
            s.startuptime
          )
        end
  
        -- Motivational quotes pool
        local quotes = {
          "\"First, solve the problem. Then, write the code.\" — John Johnson",
          "\"Code is read more often than it is written.\" — Guido van Rossum",
          "\"Make it work, make it right, make it fast.\" — Kent Beck",
          "\"Simplicity is the soul of efficiency.\" — Austin Freeman",
          "\"The best code is no code at all.\" — Jeff Atwood",
          "\"Talk is cheap. Show me the code.\" — Linus Torvalds",
          "\"Programs must be written for people to read.\" — Abelson & Sussman",
          "\"Any fool can write code a computer understands.\" — Martin Fowler",
          "\"Debugging is twice as hard as writing.\" — Brian Kernighan",
          "\"It's not a bug. It's an undocumented feature.\" — Anonymous",
        }
        math.randomseed(os.time())
        local quote = quotes[math.random(#quotes)]
  
        return {
          "",
          center(stats_line, 60),
          "",
          center("" .. quote, 64),
          center("", 60),
          center(
            icons.ui.Clock .. " " .. os.date("%A, %d %B %Y  %H:%M"),
            60
          ),
        }
      end
  
      -- ── Assemble layout ─────────────────────────────────────────────────────
  
      ---@type table  alpha section table
      local function build_layout()
        local sh = sub_header()
        local ft = footer()
  
        return {
          -- 1. Logo header
          {
            type    = "text",
            val     = header_lines,
            opts    = {
              position  = "center",
              hl        = "AlphaHeader",
            },
          },
          -- 2. Dynamic sub-header
          {
            type = "text",
            val  = sh,
            opts = {
              position = "center",
              hl       = "AlphaSubHeader",
            },
          },
          -- 3. Divider
          {
            type = "text",
            val  = { center(string.rep("─", 54), 60) },
            opts = { position = "center", hl = "AlphaDivider" },
          },
          -- 4. Buttons group
          {
            type    = "group",
            val     = buttons,
            opts    = { spacing = 0 },
          },
          -- 5. Divider
          {
            type = "text",
            val  = { center(string.rep("─", 54), 60) },
            opts = { position = "center", hl = "AlphaDivider" },
          },
          -- 6. Recent files section header
          {
            type = "text",
            val  = { center(icons.ui.History .. "  Recent Projects", 60) },
            opts = { position = "center", hl = "AlphaSectionHeader" },
          },
          -- 7. Recent files (MRU)
          {
            type    = "terminal",
            command = nil, -- populated at render time below
            width   = 54,
            height  = 0,
            opts    = {
              position  = "center",
              redraw    = true,
              window_config = {},
            },
          },
          -- 8. Footer
          {
            type = "text",
            val  = ft,
            opts = { position = "center", hl = "AlphaFooter" },
          },
        }
      end
  
      -- ── Recent files widget ──────────────────────────────────────────────────
      local mru = require("alpha.themes.dashboard").section.mru
      mru.val    = function()
        local cwd     = vim.fn.getcwd()
        local entries = {}
  
        for i, file in ipairs(vim.v.oldfiles or {}) do
          if i > 8 then break end
          if vim.fn.filereadable(file) == 1 then
            -- Devicon
            local icon_str, hl = "", "AlphaMruIcon"
            local ok_di, devicons = pcall(require, "nvim-web-devicons")
            if ok_di then
              local ic, ic_hl = devicons.get_icon(
                vim.fn.fnamemodify(file, ":t"),
                vim.fn.fnamemodify(file, ":e"),
                { default = true }
              )
              icon_str = (ic or "") .. " "
              hl = ic_hl or hl
            end
  
            -- Relative path
            local rel = vim.fn.fnamemodify(file, ":~:.")
            local short = #rel > 42
              and Ash.util.str.truncate(rel, 42, "…")
              or  rel
  
            local b = dashboard.button(
              tostring(i),
              icon_str .. short,
              "<Cmd>e " .. vim.fn.fnameescape(file) .. "<CR>"
            )
            b.opts.hl        = { { hl, 0, #icon_str } }
            b.opts.hl_shortcut = "AlphaShortcut"
            b.opts.width     = 54
            entries[#entries + 1] = b
          end
        end
  
        if #entries == 0 then
          return { dashboard.button("", "  No recent files", "") }
        end
        return entries
      end
  
      -- ── Final config ─────────────────────────────────────────────────────────
      local config = {
        layout = {
          { type = "padding", val = 2 },
          {
            type = "text",
            val  = header_lines,
            opts = { position = "center", hl = "AlphaHeader" },
          },
          { type = "padding", val = 1 },
          {
            type = "text",
            val  = sub_header(),
            opts = { position = "center", hl = "AlphaSubHeader" },
          },
          { type = "padding", val = 1 },
          {
            type = "text",
            val  = { center("  Quick Actions", 60) },
            opts = { position = "center", hl = "AlphaSectionHeader" },
          },
          { type = "padding", val = 1 },
          { type = "group", val = buttons, opts = { spacing = 0 } },
          { type = "padding", val = 1 },
          {
            type = "text",
            val  = { center(string.rep("─", 54), 60) },
            opts = { position = "center", hl = "AlphaDivider" },
          },
          { type = "padding", val = 1 },
          {
            type = "text",
            val  = { center(icons.ui.History .. "  Recent Files", 60) },
            opts = { position = "center", hl = "AlphaSectionHeader" },
          },
          { type = "padding", val = 1 },
          mru,
          { type = "padding", val = 1 },
          {
            type = "text",
            val  = footer(),
            opts = { position = "center", hl = "AlphaFooter" },
          },
          { type = "padding", val = 2 },
        },
        opts = {
          margin                = 5,
          setup                 = function()
            -- Disable statusline / tabline inside the dashboard
            vim.api.nvim_create_autocmd("User", {
              pattern  = "AlphaReady",
              once     = false,
              callback = function()
                local prev_showtabline = vim.o.showtabline
                local prev_laststatus  = vim.o.laststatus
                vim.o.showtabline = 0
                vim.o.laststatus  = 0
                vim.api.nvim_create_autocmd("BufUnload", {
                  buffer   = 0,
                  once     = true,
                  callback = function()
                    vim.o.showtabline = prev_showtabline
                    vim.o.laststatus  = prev_laststatus
                  end,
                })
              end,
            })
          end,
        },
      }
  
      return config
    end,
  
    -- ── config ────────────────────────────────────────────────────────────────
    config = function(_, opts)
      -- Apply highlight groups before alpha renders
      local function set_hl()
        local p = {
          bg      = "NONE",
          header  = "#cba6f7",  -- Catppuccin mauve
          sub     = "#89b4fa",  -- Catppuccin blue
          button  = "#cdd6f4",  -- Catppuccin text
          sc      = "#f38ba8",  -- Catppuccin red
          footer  = "#6c7086",  -- Catppuccin overlay0
          divider = "#313244",  -- Catppuccin surface0
          section = "#a6e3a1",  -- Catppuccin green
          mru_ic  = "#fab387",  -- Catppuccin peach
        }
  
        -- Attempt to pull colours from current theme
        local ok, c = pcall(function()
          return require("catppuccin.palettes").get_palette()
        end)
        if ok and c then
          p.header  = c.mauve
          p.sub     = c.blue
          p.button  = c.text
          p.sc      = c.red
          p.footer  = c.overlay0
          p.divider = c.surface0
          p.section = c.green
          p.mru_ic  = c.peach
        end
  
        local hls = {
          AlphaHeader        = { fg = p.header,  bg = p.bg, bold = true  },
          AlphaSubHeader     = { fg = p.sub,     bg = p.bg               },
          AlphaButton        = { fg = p.button,  bg = p.bg               },
          AlphaShortcut      = { fg = p.sc,      bg = p.bg, bold = true  },
          AlphaFooter        = { fg = p.footer,  bg = p.bg, italic = true },
          AlphaDivider       = { fg = p.divider, bg = p.bg               },
          AlphaSectionHeader = { fg = p.section, bg = p.bg, bold = true  },
          AlphaMruIcon       = { fg = p.mru_ic,  bg = p.bg               },
        }
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      set_hl()
  
      -- Re-apply highlights when colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_hl,
      })
  
      require("alpha").setup(opts)
  
      -- Re-render on Lazy install/update finish
      vim.api.nvim_create_autocmd("User", {
        pattern  = { "LazyInstall", "LazyUpdate", "LazySync" },
        callback = function()
          if vim.bo.filetype == "alpha" then
            require("alpha").redraw()
          end
        end,
      })
    end,
  }