-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🛢️  OIL.NVIM — ULTRA FILE MANAGER v5.0 OMEGA                             ║
-- ║   Edit filesystem like a buffer · split · float · git status · preview        ║
-- ║   columns · keymaps · trash · ASH theme-synced glassmorphism                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — premium filesystem colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "OilNormal",              { link = "NormalFloat"       })
    hl(0, "OilNormalNC",            { link = "NormalFloat"       })
    hl(0, "OilBorder",              { link = "FloatBorder"       })
    hl(0, "OilPreviewBorder",       { link = "FloatBorder"       })
    hl(0, "OilTitle",               { bold = true, fg = "#7aa2f7" })
  
    -- ── File type indicators ───────────────────────────────────────────────────
    hl(0, "OilDir",                 { bold = true,   fg = "#7aa2f7" })
    hl(0, "OilDirIcon",             { bold = true,   fg = "#7aa2f7" })
    hl(0, "OilFile",                { fg = "#cdd6f4"                })
    hl(0, "OilLink",                { italic = true, fg = "#94e2d5" })
    hl(0, "OilLinkTarget",          { italic = true, fg = "#94e2d5" })
    hl(0, "OilSocket",              { fg = "#cba6f7"                })
    hl(0, "OilNamedPipe",           { fg = "#f9e2af"                })
    hl(0, "OilBlockDevice",         { fg = "#fab387"                })
    hl(0, "OilCharDevice",          { fg = "#fab387"                })
    hl(0, "OilExecutable",          { bold = true,   fg = "#9ece6a" })
    hl(0, "OilHidden",              { italic = true, fg = "#9399b2" })
  
    -- ── Permissions column ────────────────────────────────────────────────────
    hl(0, "OilPermissionRead",      { bold = true,   fg = "#f9e2af" })
    hl(0, "OilPermissionWrite",     { bold = true,   fg = "#f38ba8" })
    hl(0, "OilPermissionExecute",   { bold = true,   fg = "#9ece6a" })
    hl(0, "OilPermissionNone",      { fg = "#9399b2"                })
  
    -- ── Size column ────────────────────────────────────────────────────────────
    hl(0, "OilSize",                { italic = true, fg = "#9399b2" })
    hl(0, "OilSizeLarge",           { bold = true,   fg = "#f9e2af" })
    hl(0, "OilSizeHuge",            { bold = true,   fg = "#f38ba8" })
  
    -- ── Mtime column ──────────────────────────────────────────────────────────
    hl(0, "OilMtime",               { italic = true, fg = "#9399b2" })
    hl(0, "OilMtimeRecent",         { italic = true, fg = "#7dcfff" })
  
    -- ── Git status ────────────────────────────────────────────────────────────
    hl(0, "OilGitAdded",            { bold = true,   fg = "#9ece6a" })
    hl(0, "OilGitModified",         { bold = true,   fg = "#f9e2af" })
    hl(0, "OilGitDeleted",          { bold = true,   fg = "#f38ba8" })
    hl(0, "OilGitRenamed",          { bold = true,   fg = "#7dcfff" })
    hl(0, "OilGitUntracked",        { fg = "#9399b2"                })
    hl(0, "OilGitIgnored",          { fg = "#9399b2"                })
    hl(0, "OilGitConflict",         { bold = true,   fg = "#f38ba8" })
  
    -- ── Cursor / selection ────────────────────────────────────────────────────
    hl(0, "OilCursor",              { link = "CursorLine"        })
    hl(0, "OilDirPath",             { italic = true, fg = "#9399b2" })
  
    -- ── Modified indicator ────────────────────────────────────────────────────
    hl(0, "OilModified",            { bold = true,   fg = "#f9e2af" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "OilDir",      { bold = true, fg = p.blue })
        hl(0, "OilDirIcon",  { bold = true, fg = p.blue })
        hl(0, "OilTitle",    { bold = true, fg = p.blue })
      end
      if p.teal   then
        hl(0, "OilLink",       { italic = true, fg = p.teal })
        hl(0, "OilLinkTarget", { italic = true, fg = p.teal })
      end
      if p.green  then
        hl(0, "OilExecutable",    { bold = true, fg = p.green })
        hl(0, "OilGitAdded",      { bold = true, fg = p.green })
        hl(0, "OilPermissionExecute", { bold = true, fg = p.green })
      end
      if p.yellow then
        hl(0, "OilGitModified",    { bold = true, fg = p.yellow })
        hl(0, "OilPermissionRead", { bold = true, fg = p.yellow })
        hl(0, "OilModified",       { bold = true, fg = p.yellow })
      end
      if p.red    then
        hl(0, "OilGitDeleted",       { bold = true, fg = p.red })
        hl(0, "OilGitConflict",      { bold = true, fg = p.red })
        hl(0, "OilPermissionWrite",  { bold = true, fg = p.red })
      end
      if p.mauve  then hl(0, "OilSocket", { fg = p.mauve }) end
      local dim = p.overlay0 or p.subtext0 or "#9399b2"
      hl(0, "OilHidden",      { italic = true, fg = dim })
      hl(0, "OilGitUntracked",{ fg = dim })
      hl(0, "OilGitIgnored",  { fg = dim })
      hl(0, "OilSize",        { italic = true, fg = dim })
      hl(0, "OilMtime",       { italic = true, fg = dim })
      hl(0, "OilDirPath",     { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 SIGN DEFINITIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function register_signs()
    vim.fn.sign_define("OilGitAdded",    { text = "+", texthl = "OilGitAdded"    })
    vim.fn.sign_define("OilGitModified", { text = "~", texthl = "OilGitModified" })
    vim.fn.sign_define("OilGitDeleted",  { text = "-", texthl = "OilGitDeleted"  })
    vim.fn.sign_define("OilGitRenamed",  { text = "→", texthl = "OilGitRenamed"  })
    vim.fn.sign_define("OilGitUntracked",{ text = "?", texthl = "OilGitUntracked"})
    vim.fn.sign_define("OilGitConflict", { text = "‼", texthl = "OilGitConflict" })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART OPEN HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Open oil at the directory of the current buffer
  local function open_oil_here()
    local file = vim.api.nvim_buf_get_name(0)
    local dir  = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
    require("oil").open(dir)
  end
  
  -- Open oil as floating window
  local function open_oil_float()
    require("oil").open_float()
  end
  
  -- Open oil at git root
  local function open_oil_root()
    local root = vim.fn.trim(
      vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
    )
    local dir = vim.v.shell_error == 0 and root or vim.fn.getcwd()
    require("oil").open(dir)
  end
  
  -- Toggle oil: close if already open, else open
  local _oil_open = false
  local function toggle_oil()
    local oil = require("oil")
    if _oil_open then
      oil.close()
      _oil_open = false
    else
      open_oil_float()
      _oil_open = true
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎛️  COLUMN DEFINITIONS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Size column with human-readable units
  local function make_size_column()
    return {
      "size",
      highlight   = function(size)
        if not size then return "OilSize" end
        if size > 1024 * 1024 * 100 then return "OilSizeHuge"  end
        if size > 1024 * 1024 then       return "OilSizeLarge" end
        return "OilSize"
      end,
    }
  end
  
  -- Mtime column with relative time colouring
  local function make_mtime_column()
    return {
      "mtime",
      highlight = function(mtime)
        if not mtime then return "OilMtime" end
        local age = os.time() - mtime
        if age < 3600 then   return "OilMtimeRecent" end   -- < 1 hour
        return "OilMtime"
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "stevearc/oil.nvim",
      event        = "VeryLazy",
      dependencies = { "nvim-tree/nvim-web-devicons" },
  
      keys = {
        -- ── Primary opens ─────────────────────────────────────────────────────
        {
          "<leader>-",
          open_oil_here,
          desc   = "🛢️  Oil: Open (file dir)",
          silent = true,
        },
        {
          "<leader>_",
          open_oil_root,
          desc   = "🛢️  Oil: Open (git root)",
          silent = true,
        },
        {
          "<leader>o-",
          toggle_oil,
          desc   = "🛢️  Oil: Toggle float",
          silent = true,
        },
        {
          "<leader>of",
          open_oil_float,
          desc   = "🛢️  Oil: Float window",
          silent = true,
        },
        {
          "<leader>oc",
          function()
            require("oil").open(vim.fn.getcwd())
          end,
          desc   = "🛢️  Oil: Open cwd",
          silent = true,
        },
      },
  
      opts = {
        -- ── Default file manager ───────────────────────────────────────────────
        default_file_explorer = true,
  
        -- ── Columns to display ─────────────────────────────────────────────────
        columns = {
          -- Icon (file type icon)
          {
            "icon",
            add_padding   = false,
            show_hidden   = true,
            directory     = vim.fn.has("mac") == 1 and "" or "",
            default       = "",
            symlink       = "󰌹",
            symlink_dir   = "󰉒",
          },
          -- Git status
          {
            "git",
            show_untracked= true,
            show_ignored  = false,
          },
          -- Permissions (unix)
          "permissions",
          -- File size
          make_size_column(),
          -- Modified time
          make_mtime_column(),
        },
  
        -- ── Buffer options ────────────────────────────────────────────────────
        buf_options = {
          buflisted    = false,
          bufhidden    = "hide",
        },
  
        -- ── Window options ────────────────────────────────────────────────────
        win_options = {
          wrap         = false,
          signcolumn   = "no",
          cursorcolumn = false,
          foldcolumn   = "0",
          spell        = false,
          list         = false,
          conceallevel = 3,
          concealcursor= "nvic",
        },
  
        -- ── Confirm delete ────────────────────────────────────────────────────
        delete_to_trash         = true,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,
  
        -- ── Cleanup ───────────────────────────────────────────────────────────
        cleanup_delay_ms        = 2000,
  
        -- ── Lsp file methods ─────────────────────────────────────────────────
        lsp_file_methods = {
          enabled               = true,
          timeout_ms            = 1000,
          autosave_changes      = false,
        },
  
        -- ── Constraint cursor ────────────────────────────────────────────────
        constrain_cursor        = "editable",
  
        -- ── Watch for external changes ────────────────────────────────────────
        watch_for_changes       = true,
  
        -- ── Keymaps ───────────────────────────────────────────────────────────
        keymaps = {
          -- Navigation
          ["g?"]           = "actions.show_help",
          ["<CR>"]         = "actions.select",
          ["<C-v>"]        = { "actions.select", opts = { vertical = true } },
          ["<C-x>"]        = { "actions.select", opts = { horizontal = true } },
          ["<C-t>"]        = { "actions.select", opts = { tab = true } },
          ["-"]            = "actions.parent",
          ["_"]            = "actions.open_cwd",
          ["`"]            = "actions.cd",
          ["~"]            = { "actions.cd", opts = { scope = "tab" } },
          ["gs"]           = "actions.change_sort",
          ["gx"]           = "actions.open_external",
          ["<C-h>"]        = "actions.toggle_hidden",
          ["<C-r>"]        = "actions.refresh",
          ["<BS>"]         = "actions.parent",
          ["q"]            = "actions.close",
          ["<Esc>"]        = "actions.close",
  
          -- Preview
          ["<C-p>"]        = "actions.preview",
          ["<M-p>"]        = "actions.preview",
  
          -- Selection
          ["<Space>"]      = "actions.select",
  
          -- Copy path
          ["gY"]           = {
            callback = function()
              local oil   = require("oil")
              local entry = oil.get_cursor_entry()
              if entry then
                local path = oil.get_current_dir() .. entry.name
                vim.fn.setreg("+", path)
                vim.notify("📋 Copied: " .. path, vim.log.levels.INFO,
                  { title = "Oil", timeout = 1000 })
              end
            end,
            desc = "Copy path to clipboard",
          },
  
          -- Open terminal here
          ["<C-`>"]        = {
            callback = function()
              local oil = require("oil")
              local dir = oil.get_current_dir()
              local ok, term = pcall(require, "toggleterm.terminal")
              if ok then
                term.Terminal:new({
                  dir          = dir,
                  direction    = "float",
                  display_name = "🛢️  " .. vim.fn.fnamemodify(dir, ":t"),
                  float_opts   = { border = "rounded" },
                  close_on_exit = false,
                }):toggle()
              else
                vim.cmd("split term://cd " .. vim.fn.shellescape(dir) .. " && $SHELL")
              end
            end,
            desc = "Open terminal here",
          },
  
          -- New file
          ["n"]            = {
            callback = function()
              local oil = require("oil")
              vim.ui.input({ prompt = "🛢️  New file: " }, function(name)
                if name and name ~= "" then
                  local path = oil.get_current_dir() .. name
                  local f    = io.open(path, "w")
                  if f then f:close() end
                  oil.open(oil.get_current_dir())
                  vim.notify("🛢️  Created: " .. name, vim.log.levels.INFO,
                    { title = "Oil", timeout = 1200 })
                end
              end)
            end,
            desc = "New file",
          },
  
          -- New directory
          ["N"]            = {
            callback = function()
              local oil = require("oil")
              vim.ui.input({ prompt = "🛢️  New dir: " }, function(name)
                if name and name ~= "" then
                  local path = oil.get_current_dir() .. name
                  vim.fn.mkdir(path, "p")
                  oil.open(oil.get_current_dir())
                  vim.notify("🛢️  Created dir: " .. name, vim.log.levels.INFO,
                    { title = "Oil", timeout = 1200 })
                end
              end)
            end,
            desc = "New directory",
          },
  
          -- Open with system default
          ["go"]           = {
            callback = function()
              local oil   = require("oil")
              local entry = oil.get_cursor_entry()
              if entry then
                local path   = oil.get_current_dir() .. entry.name
                local open_cmd = vim.fn.has("mac") == 1 and "open"
                  or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or "start")
                vim.fn.jobstart({ open_cmd, path }, { detach = true })
              end
            end,
            desc = "Open with system default",
          },
        },
  
        -- ── Use default keymaps ────────────────────────────────────────────────
        use_default_keymaps = true,
  
        -- ── View options ──────────────────────────────────────────────────────
        view_options = {
          -- Show hidden files (toggle with <C-h>)
          show_hidden    = false,
          -- Natural sort (directories first)
          is_always_hidden = function(name, _bufnr)
            return name == ".." or name == ".DS_Store"
          end,
          -- Natural sort
          natural_order  = "fast",
          -- Case-insensitive sort
          case_insensitive = false,
          sort           = {
            { "type",  "asc" },
            { "name",  "asc" },
          },
        },
  
        -- ── Extra padding ─────────────────────────────────────────────────────
        extra_scp_args          = {},
  
        -- ── SSH files ─────────────────────────────────────────────────────────
        ssh                     = { border = "rounded" },
  
        -- ── KeyPress ─────────────────────────────────────────────────────────
        keymaps_help            = { border = "rounded" },
  
        -- ── Float window ─────────────────────────────────────────────────────
        float = {
          padding         = 2,
          max_width       = 0,
          max_height      = 0,
          border          = "rounded",
          win_options     = { winblend = 0 },
          override        = function(conf)
            -- Custom sizing for float
            local width  = math.floor(vim.o.columns * 0.7)
            local height = math.floor(vim.o.lines   * 0.7)
            conf.width   = width
            conf.height  = height
            conf.col     = math.floor((vim.o.columns - width)  / 2)
            conf.row     = math.floor((vim.o.lines   - height) / 2)
            return conf
          end,
        },
  
        -- ── Preview window ────────────────────────────────────────────────────
        preview = {
          max_width       = 0.9,
          min_width       = { 40, 0.4 },
          width           = nil,
          max_height      = 0.9,
          min_height      = { 5, 0.1 },
          height          = nil,
          border          = "rounded",
          win_options     = { winblend = 0 },
          update_on_cursor_moved = true,
        },
  
        -- ── Progress window ───────────────────────────────────────────────────
        progress = {
          max_width       = 0.9,
          min_width       = { 40, 0.4 },
          width           = nil,
          max_height      = { 10, 0.9 },
          min_height      = { 5, 0.1 },
          height          = nil,
          border          = "rounded",
          minimized_border= "none",
          win_options     = { winblend = 0 },
        },
      },
  
      config = function(_, opts)
        require("oil").setup(opts)
  
        setup_highlights()
        register_signs()
  
        -- ── Override netrw (hijack directory opens) ──────────────────────────
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern  = "*",
          callback = function(ev)
            local path = vim.api.nvim_buf_get_name(ev.buf)
            if vim.fn.isdirectory(path) == 1 then
              vim.cmd("bd " .. ev.buf)
              require("oil").open(path)
            end
          end,
        })
  
        local aug = vim.api.nvim_create_augroup("AshOil", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "oil",
          callback = function(ev)
            -- Disable interfering plugins
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.spell          = false
            vim.opt_local.foldcolumn     = "0"
            vim.opt_local.statuscolumn   = ""
  
            -- Track float state
            vim.api.nvim_create_autocmd("WinClosed", {
              buffer   = ev.buf,
              once     = true,
              callback = function() _oil_open = false end,
            })
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = function()
            setup_highlights()
            register_signs()
          end,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            register_signs()
            vim.notify("🛢️  Oil highlights synced with ASH theme", vim.log.levels.INFO,
              { title = "ASH Oil", timeout = 1200 })
          end,
        })
  
        -- ── Expose statusline component ────────────────────────────────────────
        _G.AshOilPath = function()
          local ok, oil = pcall(require, "oil")
          if not ok then return "" end
          local dir = oil.get_current_dir()
          if not dir then return "" end
          return " 🛢️  " .. vim.fn.fnamemodify(dir, ":~") .. " "
        end
  
        if vim.g.ash_debug then
          vim.notify("🛢️  Oil loaded — default file explorer active", vim.log.levels.DEBUG,
            { title = "ASH Oil" })
        end
      end,
    },
  }