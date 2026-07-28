-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰆍 TOGGLETERM — ULTRA TERMINAL MANAGER v5.0 OMEGA                        ║
-- ║   Float · horizontal · vertical · tab · custom terminals · send-line          ║
-- ║   lazygit · python · node · htop · ASH theme-synced                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "ToggleTermNormal",         { link = "Normal"      })
    hl(0, "ToggleTermBorder",         { link = "FloatBorder" })
    hl(0, "ToggleTermTitle",          { bold = true, fg = "#7aa2f7" })
    hl(0, "ToggleTermStatusLine",     { link = "StatusLine"  })
    hl(0, "ToggleTermStatusLineNC",   { link = "StatusLineNC"})
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue then hl(0, "ToggleTermTitle", { bold = true, fg = p.blue }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 TERMINAL DEFINITIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local Terminal = nil  -- populated after setup
  
  local TERMINALS = {
    -- ── Floating terminals ─────────────────────────────────────────────────────
  
    lazygit = function()
      if not Terminal then return end
      return Terminal:new({
        cmd          = "lazygit",
        dir          = "git_dir",
        direction    = "float",
        display_name = "󰊢 LazyGit",
        float_opts   = { border = "rounded", width = math.floor(vim.o.columns * 0.92), height = math.floor(vim.o.lines * 0.88) },
        hidden       = true,
        on_open      = function(term)
          vim.b[term.bufnr].miniindentscope_disable = true
          vim.keymap.set("t", "<esc>", "<C-\\><C-n>", { buffer = term.bufnr, silent = true })
        end,
      })
    end,
  
    python = function()
      if not Terminal then return end
      local python = vim.fn.exepath("ipython") ~= "" and "ipython" or "python3"
      return Terminal:new({
        cmd          = python,
        direction    = "float",
        display_name = "🐍 Python REPL",
        float_opts   = { border = "rounded", width = 100, height = 30 },
        hidden       = true,
        close_on_exit = false,
      })
    end,
  
    node = function()
      if not Terminal then return end
      return Terminal:new({
        cmd          = "node",
        direction    = "float",
        display_name = "⚡ Node REPL",
        float_opts   = { border = "rounded", width = 100, height = 30 },
        hidden       = true,
        close_on_exit = false,
      })
    end,
  
    htop = function()
      if not Terminal then return end
      local prog = vim.fn.executable("btop") == 1 and "btop" or "htop"
      return Terminal:new({
        cmd          = prog,
        direction    = "float",
        display_name = "📊 " .. prog,
        float_opts   = { border = "rounded", width = math.floor(vim.o.columns * 0.95), height = math.floor(vim.o.lines * 0.92) },
        hidden       = true,
      })
    end,
  
    yazi = function()
      if not Terminal then return end
      return Terminal:new({
        cmd          = "yazi " .. vim.fn.getcwd(),
        direction    = "float",
        display_name = "🗂️  Yazi",
        float_opts   = { border = "rounded", width = math.floor(vim.o.columns * 0.90), height = math.floor(vim.o.lines * 0.85) },
        hidden       = true,
      })
    end,
  
    gh_dash = function()
      if not Terminal then return end
      return Terminal:new({
        cmd          = "gh dash",
        direction    = "float",
        display_name = " GitHub Dashboard",
        float_opts   = { border = "rounded", width = math.floor(vim.o.columns * 0.90), height = math.floor(vim.o.lines * 0.85) },
        hidden       = true,
      })
    end,
  }
  
  -- Singleton cache
  local _terms = {}
  
  local function get_term(name)
    if not _terms[name] then
      local factory = TERMINALS[name]
      if factory then _terms[name] = factory() end
    end
    return _terms[name]
  end
  
  local function toggle_term(name)
    local term = get_term(name)
    if term then term:toggle() end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  SMART SEND HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function send_line()
    local line = vim.api.nvim_get_current_line()
    require("toggleterm").exec(line)
  end
  
  local function send_selection()
    local s     = vim.api.nvim_buf_get_mark(0, "<")
    local e     = vim.api.nvim_buf_get_mark(0, ">")
    local lines = vim.api.nvim_buf_get_lines(0, s[1] - 1, e[1], false)
    local text  = table.concat(lines, "\n")
    require("toggleterm").exec(text)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "akinsho/toggleterm.nvim",
      version = "*",
      event   = "VeryLazy",
  
      keys = {
        -- ── Numbered toggleterm ─────────────────────────────────────────────────
        { "<C-`>",     "<cmd>ToggleTerm<cr>",                                      mode = { "n", "t" }, desc = "󰆍 Term: Toggle"              },
        { "<C-1>",     "<cmd>1ToggleTerm direction=float<cr>",                      mode = { "n", "t" }, desc = "󰆍 Term: Float 1"             },
        { "<C-2>",     "<cmd>2ToggleTerm direction=horizontal<cr>",                 mode = { "n", "t" }, desc = "󰆍 Term: Horizontal 2"        },
        { "<C-3>",     "<cmd>3ToggleTerm direction=vertical<cr>",                   mode = { "n", "t" }, desc = "󰆍 Term: Vertical 3"          },
  
        -- ── Named terminals ────────────────────────────────────────────────────
        { "<leader>tg", function() toggle_term("lazygit") end,                     desc = "󰊢 Term: LazyGit"                                   },
        { "<leader>tp", function() toggle_term("python")  end,                     desc = "🐍 Term: Python REPL"                              },
        { "<leader>tn", function() toggle_term("node")    end,                     desc = "⚡ Term: Node REPL"                                },
        { "<leader>th", function() toggle_term("htop")    end,                     desc = "📊 Term: htop/btop"                                },
        { "<leader>ty", function() toggle_term("yazi")    end,                     desc = "🗂️  Term: Yazi"                                    },
        { "<leader>tG", function() toggle_term("gh_dash") end,                     desc = " Term: GitHub Dashboard"                          },
  
        -- ── Send code ──────────────────────────────────────────────────────────
        { "<leader>ts", send_line,      mode = "n", desc = "󰆍 Term: Send line"                                                               },
        { "<leader>ts", send_selection, mode = "v", desc = "󰆍 Term: Send selection"                                                          },
  
        -- ── ToggleTerm all ─────────────────────────────────────────────────────
        { "<leader>ta", "<cmd>ToggleTermToggleAll<cr>", desc = "󰆍 Term: Toggle all"                                                          },
  
        -- ── Terminal escape ────────────────────────────────────────────────────
        { "<esc><esc>", "<C-\\><C-n>",  mode = "t", desc = "󰆍 Term: Exit terminal mode"                                                     },
        { "<C-h>",      "<cmd>wincmd h<cr>", mode = "t", desc = "󰆍 Term: Window left"                                                       },
        { "<C-j>",      "<cmd>wincmd j<cr>", mode = "t", desc = "󰆍 Term: Window down"                                                       },
        { "<C-k>",      "<cmd>wincmd k<cr>", mode = "t", desc = "󰆍 Term: Window up"                                                         },
        { "<C-l>",      "<cmd>wincmd l<cr>", mode = "t", desc = "󰆍 Term: Window right"                                                      },
      },
  
      opts = {
        -- ── Shell ─────────────────────────────────────────────────────────────
        shell            = vim.o.shell,
  
        -- ── Auto-close ────────────────────────────────────────────────────────
        close_on_exit    = true,
        auto_scroll      = true,
        start_in_insert  = true,
  
        -- ── Appearance ────────────────────────────────────────────────────────
        highlights = {
          Normal          = { link = "ToggleTermNormal"     },
          NormalFloat     = { link = "NormalFloat"          },
          FloatBorder     = { link = "ToggleTermBorder"     },
          StatusLine      = { link = "ToggleTermStatusLine" },
          StatusLineNC    = { link = "ToggleTermStatusLineNC" },
        },
        winbar = {
          enabled        = false,
          name_formatter = function(term)
            return term.name
          end,
        },
  
        -- ── Default float ──────────────────────────────────────────────────────
        direction    = "float",
        float_opts   = {
          border       = "rounded",
          width        = function() return math.floor(vim.o.columns * 0.88) end,
          height       = function() return math.floor(vim.o.lines   * 0.82) end,
          winblend     = 0,
          zindex       = 50,
          title_pos    = "center",
        },
  
        -- ── Size (for split terminals) ─────────────────────────────────────────
        size = function(term)
          if term.direction == "horizontal" then
            return math.floor(vim.o.lines * 0.30)
          elseif term.direction == "vertical" then
            return math.floor(vim.o.columns * 0.38)
          end
          return 20
        end,
  
        -- ── Shade ─────────────────────────────────────────────────────────────
        shade_terminals  = false,
        shade_factor     = 1,
  
        -- ── Callbacks ─────────────────────────────────────────────────────────
        on_open = function(term)
          -- Disable interfering plugins in terminal buffers
          vim.b[term.bufnr].miniindentscope_disable = true
          vim.b[term.bufnr].minianimate_disable     = true
  
          vim.cmd("startinsert!")
          vim.opt_local.number         = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn     = "no"
          vim.opt_local.spell          = false
        end,
  
        on_close = function(_)
          -- Return focus to editor
          vim.cmd("stopinsert!")
        end,
  
        -- ── Persist size between opens ─────────────────────────────────────────
        persist_size     = true,
        persist_mode     = true,
  
        -- ── Insert-mode on focus ───────────────────────────────────────────────
        insert_mappings  = true,
        terminal_mappings= true,
  
        -- ── Hide terminal number in list ───────────────────────────────────────
        hide_numbers     = true,
      },
  
      config = function(_, opts)
        require("toggleterm").setup(opts)
  
        -- Populate singleton Terminal reference
        Terminal = require("toggleterm.terminal").Terminal
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshToggleTerm", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Clear cached terminals so they pick up new theme
            _terms = {}
            vim.notify("󰆍 ToggleTerm synced with ASH theme", vim.log.levels.INFO,
              { title = "ASH ToggleTerm", timeout = 1200 })
          end,
        })
  
        -- User command for quick terminal
        vim.api.nvim_create_user_command("Term", function(args)
          local dir  = args.args ~= "" and args.args or vim.fn.getcwd()
          require("toggleterm").exec("", 0, 20, dir, "float")
        end, {
          nargs = "?",
          desc  = "󰆍 Open toggleterm at path",
        })
  
        if vim.g.ash_debug then
          vim.notify("󰆍 ToggleTerm loaded", vim.log.levels.DEBUG, { title = "ASH ToggleTerm" })
        end
      end,
    },
  }