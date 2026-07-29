-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐍 PYTHON — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   pyright · ruff · black · isort · venv · pytest · type stubs                 ║
-- ║   docstrings · REPL · jupyter · ASH theme-synced                               ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Python semantic tokens ────────────────────────────────────────────────
    hl(0, "@lsp.type.class.python",          { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.function.python",       { bold = false,  fg = "#89b4fa"  })
    hl(0, "@lsp.type.method.python",         { fg = "#89b4fa"                 })
    hl(0, "@lsp.type.decorator.python",      { italic = true, fg = "#cba6f7"  })
    hl(0, "@lsp.type.typeParameter.python",  { italic = true, fg = "#94e2d5"  })
    hl(0, "@lsp.type.variable.python",       { fg = "#cdd6f4"                 })
    hl(0, "@lsp.type.parameter.python",      { italic = true, fg = "#c8c8c8"  })
    hl(0, "@lsp.type.selfParameter.python",  { bold = true,   fg = "#f9e2af"  })
    hl(0, "@lsp.type.clsParameter.python",   { bold = true,   fg = "#fab387"  })
    hl(0, "@lsp.type.builtinConstant.python",{ bold = true,   fg = "#fab387"  })
  
    -- ── f-string / format strings ─────────────────────────────────────────────
    hl(0, "@string.special.path.python",     { fg = "#a6e3a1"                 })
    hl(0, "@string.regex.python",            { fg = "#f5c2e7"                 })
  
    -- ── Type annotations ──────────────────────────────────────────────────────
    hl(0, "@type.python",                    { italic = true, fg = "#94e2d5"  })
    hl(0, "@type.builtin.python",            { italic = true, fg = "#89dceb"  })
  
    -- ── venv / tools status ───────────────────────────────────────────────────
    hl(0, "PythonVenvActive",    { bold = true, fg = "#9ece6a"  })
    hl(0, "PythonVenvInactive",  { fg = "#9399b2"               })
    hl(0, "PythonVersion",       { italic = true, fg = "#89b4fa" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.yellow then hl(0, "@lsp.type.class.python",    { bold = true, fg = p.yellow }) end
      if p.blue   then hl(0, "@lsp.type.function.python", { fg = p.blue                }) end
      if p.mauve  then hl(0, "@lsp.type.decorator.python",{ italic = true, fg = p.mauve}) end
      if p.teal   then
        hl(0, "@lsp.type.typeParameter.python", { italic = true, fg = p.teal })
        hl(0, "@type.python",                   { italic = true, fg = p.teal })
      end
      if p.green  then hl(0, "PythonVenvActive", { bold = true, fg = p.green }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "PythonVenvInactive", { fg = dim })
      if p.blue then hl(0, "PythonVersion", { italic = true, fg = p.blue }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 PYTHON ENVIRONMENT UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function find_python()
    local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
    if venv then
      local p = venv .. "/bin/python"
      if vim.fn.executable(p) == 1 then return p end
    end
  
    local cwd_venvs = { ".venv", "venv", ".env" }
    for _, name in ipairs(cwd_venvs) do
      local p = vim.fn.getcwd() .. "/" .. name .. "/bin/python"
      if vim.fn.executable(p) == 1 then return p end
    end
  
    local which = vim.fn.trim(vim.fn.system("which python3 2>/dev/null"))
    return which ~= "" and which or "python3"
  end
  
  local function get_python_version()
    local python = find_python()
    local ver    = vim.fn.trim(vim.fn.system(python .. " --version 2>&1"))
    return ver:match("Python%s+(.+)") or "unknown"
  end
  
  local function get_venv_name()
    local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
    if venv then return vim.fn.fnamemodify(venv, ":t") end
  
    for _, name in ipairs({ ".venv", "venv" }) do
      if vim.fn.isdirectory(vim.fn.getcwd() .. "/" .. name) == 1 then
        return name
      end
    end
    return nil
  end
  
  -- Activate virtualenv and restart LSP
  local function activate_venv()
    vim.ui.input(
      { prompt = "🐍 Venv path [.venv]: ", default = ".venv" },
      function(path)
        if not path or path == "" then path = ".venv" end
  
        local abs = vim.fn.fnamemodify(path, ":p")
        if vim.fn.isdirectory(abs) == 0 then
          vim.notify(
            "🐍 Directory not found: " .. abs,
            vim.log.levels.ERROR,
            { title = "Python" }
          )
          return
        end
  
        local python = abs .. "/bin/python"
        if vim.fn.executable(python) ~= 1 then
          vim.notify(
            "🐍 Python not found at: " .. python,
            vim.log.levels.ERROR,
            { title = "Python" }
          )
          return
        end
  
        vim.env.VIRTUAL_ENV = abs
        vim.env.PATH        = abs .. "/bin:" .. (vim.env.PATH or "")
  
        -- Restart LSP clients
        vim.cmd("LspRestart")
        vim.notify(
          string.format("🐍 Activated venv: %s", vim.fn.fnamemodify(abs, ":t")),
          vim.log.levels.INFO,
          { title = "Python", timeout = 2000 }
        )
      end
    )
  end
  
  -- Run Python REPL in terminal
  local function open_python_repl()
    local python = find_python()
  
    -- Try to use ipython if available
    if vim.fn.executable(vim.fn.fnamemodify(python, ":h") .. "/ipython") == 1 then
      python = vim.fn.fnamemodify(python, ":h") .. "/ipython"
    end
  
    local ok, term = pcall(require, "toggleterm.terminal")
    if ok then
      local Terminal = term.Terminal
      local repl     = Terminal:new({
        cmd         = python,
        direction   = "float",
        display_name= "🐍 Python REPL",
        float_opts  = { border = "rounded" },
        close_on_exit = false,
      })
      repl:toggle()
    else
      vim.cmd("split term://" .. python)
    end
  end
  
  -- Send visual selection to Python REPL
  local function send_to_repl()
    local s     = vim.api.nvim_buf_get_mark(0, "<")
    local e     = vim.api.nvim_buf_get_mark(0, ">")
    local lines = vim.api.nvim_buf_get_lines(0, s[1] - 1, e[1], false)
    local code  = table.concat(lines, "\n")
  
    -- Try to find an active terminal
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
        local chan = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
        if chan then
          vim.api.nvim_chan_send(chan, code .. "\n")
          vim.notify("🐍 Sent to REPL", vim.log.levels.INFO,
            { title = "Python", timeout = 800 })
          return
        end
      end
    end
    vim.notify("🐍 No active REPL found (use <leader>pr to open one)",
      vim.log.levels.WARN, { title = "Python" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- ── Treesitter: Python grammar ────────────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "python", "toml", "rst" })
      end,
    },
  
    -- ── Mason: Python tools ───────────────────────────────────────────────────────
    {
      "williamboman/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, {
          "pyright",
          "ruff",
          "ruff-lsp",
          "black",
          "isort",
          "mypy",
          "pylint",
          "debugpy",
          "python-lsp-server",
        })
      end,
    },
  
    -- ── nvim-lspconfig: Pyright setup ─────────────────────────────────────────────
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          pyright = {
            settings = {
              python = {
                analysis = {
                  typeCheckingMode         = "strict",
                  autoSearchPaths          = true,
                  useLibraryCodeForTypes   = true,
                  diagnosticMode           = "workspace",
                  autoImportCompletions    = true,
                  completeFunctionParens   = true,
                  inlayHints               = {
                    variableTypes          = true,
                    functionReturnTypes    = true,
                    callArgumentNames      = true,
                    pytestParameters       = true,
                  },
                },
                pythonPath = find_python(),
              },
            },
            before_init = function(_, config)
              local python = find_python()
              config.settings.python.pythonPath = python
            end,
          },
          ruff_lsp = {
            on_attach = function(client, bufnr)
              client.server_capabilities.hoverProvider = false
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            init_options = {
              settings = {
                args         = {},
                lint         = { enable = true },
                format       = { preview = true },
              },
            },
          },
        },
      },
    },
  
    -- ── venv-selector.nvim ────────────────────────────────────────────────────────
    {
      "linux-cultist/venv-selector.nvim",
      branch       = "regexp",
      dependencies = {
        "neovim/nvim-lspconfig",
        { "nvim-telescope/telescope.nvim", optional = true },
      },
      ft  = "python",
  
      keys = {
        { "<leader>pv",  "<cmd>VenvSelect<cr>",       ft = "python", desc = "🐍 Select virtualenv"          },
        { "<leader>pV",  "<cmd>VenvSelectCached<cr>", ft = "python", desc = "🐍 Select cached virtualenv"   },
        { "<leader>ppa", activate_venv,               ft = "python", desc = "🐍 Activate venv (manual path)" },
        { "<leader>ppr", open_python_repl,            ft = "python", desc = "🐍 Open Python REPL"            },
        {
          "<leader>pps",
          send_to_repl,
          mode  = "v",
          ft    = "python",
          desc  = "🐍 Send selection to REPL",
        },
        {
          "<leader>ppi",
          function()
            local python = find_python()
            local venv   = get_venv_name()
            local ver    = get_python_version()
            vim.notify(
              table.concat({
                "🐍 Python Environment",
                "──────────────────────────────────",
                string.format("  Python:  %s", python),
                string.format("  Version: %s", ver),
                string.format("  Venv:    %s", venv or "(none)"),
                string.format("  CONDA:   %s", os.getenv("CONDA_PREFIX") or "(none)"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Python" }
            )
          end,
          ft   = "python",
          desc = "🐍 Python environment info",
        },
      },
  
      opts = {
        settings = {
          search = {
            my_venvs = {
              command = "find "
                .. (os.getenv("HOME") or "~")
                .. " -name 'pyvenv.cfg' -not -path '*/proc/*' 2>/dev/null",
            },
          },
          changed_venv_hooks = { "LspRestart" },
          auto_refresh       = false,
          search_venv_managers = true,
          search_workspace   = true,
          parents            = 2,
          origin_venv        = { enabled = true, sources = { "workspace" } },
          notify_user_on_venv_activation = true,
        },
        options = {
          enable_default_searches = true,
          search_venv_managers    = true,
          search                  = true,
          fd_binary_name          = "fd",
          notify_user_on_activate = true,
        },
      },
  
      config = function(_, opts)
        require("venv-selector").setup(opts)
  
        setup_highlights()
  
        -- Expose venv status for statusline
        _G.AshPythonVenv = function()
          local venv = get_venv_name()
          if venv then
            return string.format(" 🐍 %s", venv)
          end
          return ""
        end
  
        local aug = vim.api.nvim_create_augroup("AshPython", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🐍 Python highlights synced", vim.log.levels.INFO,
              { title = "ASH Python", timeout = 1200 })
          end,
        })
  
        -- Auto-detect venv on BufEnter
        vim.api.nvim_create_autocmd("BufEnter", {
          group   = aug,
          pattern = "*.py",
          callback = function()
            local venv = get_venv_name()
            if venv and not os.getenv("VIRTUAL_ENV") then
              local abs = vim.fn.getcwd() .. "/" .. venv
              if vim.fn.isdirectory(abs) == 1 then
                vim.env.VIRTUAL_ENV = abs
              end
            end
          end,
          once = true,
        })
  
        -- Set python filetype options
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "python",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.textwidth   = 100
            vim.opt_local.colorcolumn = "101"
            vim.opt_local.spell       = false
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("🐍 Python loaded — %s", get_python_version()),
            vim.log.levels.DEBUG,
            { title = "ASH Python" }
          )
        end
      end,
    },
  }