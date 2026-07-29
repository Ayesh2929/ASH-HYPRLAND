-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/autocmds.lua — Autocommands                                       ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  All autocommands are placed in named augroups so they can be:              ║
-- ║    • Cleared and reloaded cleanly on config hot-reload                      ║
-- ║    • Individually disabled by name                                          ║
-- ║    • Inspected via :autocmd AshCore*                                        ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local api  = vim.api
local cmd  = vim.cmd
local fn   = vim.fn

-- ── Augroup factory ───────────────────────────────────────────────────────────

---Create (or clear) a named augroup and return its id
---@param name string
---@return integer
local function augroup(name)
  return api.nvim_create_augroup("AshCore_" .. name, { clear = true })
end

---Thin wrapper around nvim_create_autocmd
---@param events  string|string[]
---@param opts    table
local function au(events, opts)
  api.nvim_create_autocmd(events, opts)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  HIGHLIGHT ON YANK
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("YankHighlight")
  au("TextYankPost", {
    group    = g,
    desc     = "Flash yanked region",
    callback = function()
      vim.highlight.on_yank({
        higroup  = "IncSearch",
        timeout  = 180,
        on_macro = false,
        on_visual = true,
      })
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  RESTORE CURSOR POSITION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("RestoreCursor")
  au("BufReadPost", {
    group    = g,
    desc     = "Restore cursor to last known position",
    callback = function(ev)
      local mark = api.nvim_buf_get_mark(ev.buf, '"')
      local lcount = api.nvim_buf_line_count(ev.buf)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(api.nvim_win_set_cursor, 0, mark)
        cmd("normal! zz")
      end
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  AUTO-RESIZE SPLITS ON TERMINAL RESIZE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("ResizeSplits")
  au("VimResized", {
    group    = g,
    desc     = "Resize splits when terminal is resized",
    callback = function()
      local current_tab = fn.tabpagenr()
      cmd("tabdo wincmd =")
      cmd("tabnext " .. current_tab)
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  AUTO-CLOSE SPECIFIC BUFFERS WITH q
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("CloseWithQ")
  au("FileType", {
    group   = g,
    desc    = "Close certain filetypes with q",
    pattern = {
      "help", "man", "lspinfo", "startuptime",
      "checkhealth", "qf", "nofile",
      "notify", "lazy", "mason",
      "toggleterm", "aerial",
      "spectre_panel", "tsplayground",
      "PlenaryTestPopup",
    },
    callback = function(ev)
      vim.bo[ev.buf].buflisted = false
      vim.keymap.set("n", "q", "<Cmd>close<CR>", {
        buffer  = ev.buf,
        silent  = true,
        nowait  = true,
        desc    = "Close window",
      })
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  SPELL & TEXT WRAPPING FOR PROSE FILETYPES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("ProseSettings")
  au("FileType", {
    group   = g,
    desc    = "Enable spell + wrap for prose filetypes",
    pattern = {
      "markdown", "text", "tex", "rst",
      "org", "norg", "asciidoc",
      "gitcommit", "NeogitCommitMessage",
    },
    callback = function()
      vim.opt_local.spell    = true
      vim.opt_local.wrap     = true
      vim.opt_local.linebreak = true
      vim.opt_local.textwidth = 80
      vim.opt_local.conceallevel = 2
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 06  TRIM TRAILING WHITESPACE ON SAVE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("TrimWhitespace")
  au("BufWritePre", {
    group    = g,
    desc     = "Remove trailing whitespace before save",
    pattern  = "*",
    callback = function()
      -- Don't trim binary files or diff buffers
      if vim.bo.binary or vim.bo.filetype == "diff" then return end
      local view = fn.winsaveview()
      cmd([[keeppatterns %s/\s\+$//e]])
      fn.winrestview(view)
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 07  AUTO-CREATE MISSING DIRECTORIES ON SAVE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("AutoMkdir")
  au("BufWritePre", {
    group    = g,
    desc     = "Auto-create parent directories on write",
    callback = function(ev)
      if ev.match:match("^%w%w+:[\\/][\\/]") then return end -- skip remote
      local file = vim.uv.fs_realpath(ev.match) or ev.match
      local dir  = fn.fnamemodify(file, ":p:h")
      if not vim.uv.fs_stat(dir) then
        fn.mkdir(dir, "p")
      end
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 08  BIG FILE OPTIMISATIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("BigFile")
  local BIG = Ash.perf.bigfile_size -- 256 KB (from Ash global)

  au({ "BufReadPre" }, {
    group    = g,
    desc     = "Disable heavy features for large files",
    callback = function(ev)
      local stat = vim.uv.fs_stat(ev.match)
      if not stat or stat.size < BIG then return end

      vim.b[ev.buf].large_file = true

      -- Disable expensive features
      vim.opt_local.foldmethod    = "manual"
      vim.opt_local.foldexpr      = ""
      vim.opt_local.spell         = false
      vim.opt_local.swapfile      = false
      vim.opt_local.undofile      = false
      vim.opt_local.breakindent   = false
      vim.opt_local.colorcolumn   = ""
      vim.opt_local.statuscolumn  = ""

      -- Disable treesitter for this buffer
      au("BufReadPost", {
        buffer   = ev.buf,
        once     = true,
        callback = function()
          pcall(vim.treesitter.stop)
        end,
      })

      vim.notify(
        string.format(
          "📦 Large file detected (%dKB). Performance mode enabled.",
          math.floor(stat.size / 1024)
        ),
        vim.log.levels.WARN,
        { title = "ASH NeoVim" }
      )
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 09  ACTIVE WINDOW LINE NUMBER STYLE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Active window: relative numbers. Inactive: absolute.
do
  local g = augroup("SmartNumbers")
  au({ "WinEnter", "BufEnter", "InsertLeave" }, {
    group    = g,
    desc     = "Relative numbers in active window",
    callback = function()
      if vim.bo.buftype ~= "" then return end
      vim.opt_local.relativenumber = true
      vim.opt_local.number         = true
    end,
  })
  au({ "WinLeave", "BufLeave", "InsertEnter" }, {
    group    = g,
    desc     = "Absolute numbers in inactive windows / insert mode",
    callback = function()
      if vim.bo.buftype ~= "" then return end
      vim.opt_local.relativenumber = false
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10  SMART CURSORLINE (only in active window)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("SmartCursorLine")
  au({ "WinEnter", "BufEnter" }, {
    group    = g,
    desc     = "Enable cursorline in active window",
    callback = function() vim.opt_local.cursorline = true end,
  })
  au({ "WinLeave" }, {
    group    = g,
    desc     = "Disable cursorline in inactive windows",
    callback = function() vim.opt_local.cursorline = false end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 11  RELOAD FILE WHEN CHANGED EXTERNALLY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("AutoRead")
  au({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group    = g,
    desc     = "Check if file changed on disk",
    callback = function()
      if fn.mode() ~= "c" and fn.getcmdwintype() == "" then
        cmd("checktime")
      end
    end,
  })
  au("FileChangedShellPost", {
    group    = g,
    desc     = "Notify when file is changed externally",
    callback = function()
      vim.notify(
        " File changed on disk. Buffer reloaded.",
        vim.log.levels.WARN,
        { title = "ASH NeoVim" }
      )
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 12  FORMAT OPTIONS: DISABLE AUTO-COMMENT-LEADER INSERTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Many ftplugins reset formatoptions; ensure ours always wins.
do
  local g = augroup("FormatOptions")
  au("BufEnter", {
    group    = g,
    desc     = "Prevent comment leader on newline",
    callback = function()
      vim.opt_local.formatoptions:remove("o") -- no comment on o/O
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 13  ASH THEME HOT-RELOAD TRIGGER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- When the ASH theme engine writes a new colorscheme into the theme socket,
-- we listen for the custom User event `AshThemeChanged` (fired by the watcher).
do
  local g = augroup("AshThemeSync")
  au("User", {
    group   = g,
    pattern = "AshThemeChanged",
    desc    = "Hot-reload colorscheme when ASH theme changes",
    callback = function(ev)
      local scheme = ev.data and ev.data.colorscheme or Ash.colorscheme
      vim.schedule(function()
        pcall(cmd.colorscheme, scheme)
        vim.notify(
          " Theme synced: " .. scheme,
          vim.log.levels.INFO,
          { title = "ASH NeoVim", timeout = 2000 }
        )
      end)
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 14  TERMINAL: ENTER INSERT MODE AUTOMATICALLY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("TerminalInsert")
  au({ "TermOpen", "BufEnter" }, {
    group    = g,
    desc     = "Start terminal in insert mode",
    pattern  = "term://*",
    callback = function()
      vim.opt_local.number         = false
      vim.opt_local.relativenumber = false
      vim.opt_local.signcolumn     = "no"
      cmd("startinsert")
    end,
  })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 15  CLOSE EMPTY UNNAMED BUFFER (left by :new / startscreen)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
do
  local g = augroup("CloseEmptyBuffer")
  au("BufAdd", {
    group    = g,
    desc     = "Close empty unnamed buffer after opening a real file",
    callback = function()
      if #api.nvim_list_bufs() > 1 then
        local bufs = vim.tbl_filter(function(b)
          return api.nvim_buf_get_name(b) == ""
            and not vim.bo[b].modified
            and api.nvim_buf_is_loaded(b)
        end, api.nvim_list_bufs())
        for _, b in ipairs(bufs) do
          pcall(api.nvim_buf_delete, b, { force = false })
        end
      end
    end,
  })
end