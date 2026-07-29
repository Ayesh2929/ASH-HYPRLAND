-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/options.lua — vim.opt.* Ultra Configuration                       ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Philosophy:                                                                 ║
-- ║    • Every option is documented — no mystery settings                       ║
-- ║    • Grouped by concern, not alphabetically                                 ║
-- ║    • Performance-first: sensible debounce / update intervals                ║
-- ║    • Wayland-native: clipboard via wl-copy / wl-paste                       ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local opt = vim.opt
local g   = vim.g

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  LEADER KEYS  (must be set before plugins / lazy.nvim loads)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Space as leader gives the most ergonomic reach on QWERTY/Colemak/Dvorak.
-- Comma as local-leader is a common convention for buffer/filetype bindings.
g.mapleader      = " "
g.maplocalleader = ","

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 02  APPEARANCE & UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.termguicolors  = true           -- 24-bit RGB colours (requires modern terminal)
opt.background     = "dark"         -- default; overridden by theme engine
opt.cursorline     = true           -- highlight the line under the cursor
opt.cursorlineopt  = "both"         -- highlight both number and line (Nvim ≥ 0.9)
opt.cursorcolumn   = false          -- column highlight is distracting in most work
opt.colorcolumn    = "100,120"      -- visual rulers at 100 and 120 columns
opt.signcolumn     = "yes:2"        -- always show; 2 cols for gitsigns + diagnostics
opt.number         = true           -- absolute line numbers
opt.relativenumber = true           -- relative numbers for fast motion (e.g. 5j, 12k)
opt.numberwidth    = 3              -- minimum gutter width
opt.showmode       = false          -- mode shown by lualine; hide the built-in echo
opt.showcmd        = false          -- hide partial command echo (noice handles this)
opt.cmdheight      = 0              -- 0 = hide cmdline when not typing (Nvim ≥ 0.8)
opt.laststatus     = 3              -- global statusline (one bar, not per-window)
opt.showtabline    = 2              -- always show tabline (bufferline controls it)
opt.pumheight      = 14            -- max items in the pop-up menu
opt.pumwidth       = 20            -- min width of the pop-up menu
opt.pumblend       = 8             -- transparency of the pop-up menu (0 = opaque)
opt.winblend       = 0             -- transparency of floating windows
opt.conceallevel   = 2             -- hide markup in markdown/org/norg
opt.concealcursor  = "nc"          -- conceal in normal + command mode
opt.listchars      = {             -- whitespace rendering characters
  tab      = "→ ",
  trail    = "·",
  nbsp     = "␣",
  extends  = "›",
  precedes = "‹",
  eol      = "↲",
}
opt.list           = false         -- only show listchars when :set list or mapped
opt.fillchars      = {             -- UI chrome characters
  eob        = " ",               -- hide ~ past end-of-buffer
  fold       = " ",               -- fold fill
  foldopen   = "",               -- open fold indicator
  foldclose  = "",               -- closed fold indicator
  foldsep    = " ",               -- fold separator
  diff       = "╱",               -- deleted lines in diff mode
  msgsep     = "─",               -- messages separator
  horiz      = "─",               -- horizontal window separator
  horizup    = "┴",
  horizdown  = "┬",
  vert       = "│",               -- vertical window separator
  vertleft   = "┤",
  vertright  = "├",
  verthoriz  = "┼",
}
opt.title          = true          -- set terminal window title
opt.titlestring    = "  nvim — %{expand('%:~:.')} [%{mode()}]"
opt.titlelen       = 85

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 03  FONTS & ICONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
g.have_nerd_font = true            -- tells plugins to use Nerd Font glyphs

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 04  EDITOR BEHAVIOUR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.mouse          = "a"           -- enable mouse in all modes
opt.mousemoveevent = true          -- trigger CursorMoved on mouse move (for hover)
opt.clipboard      = "unnamedplus" -- sync with system clipboard (wl-copy on Wayland)
opt.virtualedit    = "block"       -- block-select beyond end of line
opt.selectmode     = ""            -- never enter Select mode (use Visual)
opt.updatetime     = 100           -- ms after no-keystroke → CursorHold (LSP hover)
opt.timeoutlen     = 300           -- ms to wait for mapped-key sequence completion
opt.ttimeoutlen    = 0             -- no delay for terminal key codes
opt.confirm        = true          -- ask to save instead of erroring on :q
opt.autowrite      = true          -- save buffer before :make, :next, etc.
opt.autowriteall   = false         -- only auto-write on explicit triggers (above)
opt.hidden         = true          -- allow unsaved buffers in background
opt.switchbuf      = "useopen,uselast" -- reuse existing windows when switching buffers

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 05  SEARCH & REPLACE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.ignorecase     = true          -- case-insensitive search…
opt.smartcase      = true          -- …unless pattern contains uppercase
opt.hlsearch       = true          -- highlight all matches
opt.incsearch      = true          -- show matches as you type
opt.inccommand     = "split"       -- live preview of :s substitutions in split
opt.grepprg        = "rg --vimgrep --smart-case --hidden --follow"
opt.grepformat     = "%f:%l:%c:%m"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 06  INDENTATION & WHITESPACE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.expandtab      = true          -- <Tab> inserts spaces
opt.tabstop        = 2             -- visual width of a real tab character
opt.softtabstop    = 2             -- spaces inserted by <Tab> / removed by <BS>
opt.shiftwidth     = 2             -- spaces used by >> / << / auto-indent
opt.shiftround     = true          -- round indent to multiples of shiftwidth
opt.smartindent    = true          -- auto-indent after {, keywords, etc.
opt.autoindent     = true          -- copy indent from previous line
opt.breakindent    = true          -- wrapped lines continue at indent level
opt.breakindentopt = "shift:2,min:40,sbr"
opt.linebreak      = true          -- wrap at word boundaries, not mid-word
opt.wrap           = false         -- no soft-wrap by default; toggle with keymap
opt.showbreak      = "↪ "          -- prefix for wrapped lines

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 07  FOLDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Use treesitter-based folding when available; graceful fallback to indent.
opt.foldenable     = true
opt.foldlevel      = 99            -- start with everything open
opt.foldlevelstart = 99            -- same on BufEnter
opt.foldcolumn     = "1"           -- show fold gutter
opt.foldmethod     = "expr"        -- use foldexpr (set by Treesitter plugin)
opt.foldexpr       = "v:lua.vim.treesitter.foldexpr()" -- Nvim ≥ 0.10 built-in
opt.foldtext       = ""            -- use default (shows first line + count)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 08  SPLITS & WINDOWS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.splitright     = true          -- :vsplit opens to the right
opt.splitbelow     = true          -- :split opens below
opt.splitkeep      = "screen"      -- stabilise cursor position on split (Nvim ≥ 0.9)
opt.equalalways    = true          -- resize splits to equal size on open/close
opt.winminwidth    = 5             -- minimum window width

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 09  SCROLLING & MOTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.scrolloff      = 8             -- keep 8 lines above/below cursor
opt.sidescrolloff  = 8             -- keep 8 columns left/right of cursor
opt.sidescroll     = 1             -- minimal horizontal scroll
opt.smoothscroll   = true          -- smooth scrolling (Nvim ≥ 0.10)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 10  FILES & BACKUPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.undofile       = true          -- persistent undo across sessions
opt.undolevels     = 10000         -- maximum undo history depth
opt.undodir        = vim.fn.stdpath("state") .. "/undo//"

opt.backup         = false         -- no backup files (use git!)
opt.writebackup    = false         -- no write-backup (git covers this)
opt.swapfile       = false         -- no swap files (modern systems don't crash)

-- Automatically read a file when changed outside nvim (git checkout, etc.)
opt.autoread       = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 11  SPELL CHECKING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.spell          = false         -- off by default; enabled per-filetype in autocmds
opt.spelllang      = { "en_us" }
opt.spelloptions   = "camel"       -- treat camelCase as separate words
opt.spellfile      = vim.fn.stdpath("config") .. "/spell/en.utf-8.add"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 12  COMPLETION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.completeopt    = { "menu", "menuone", "noselect", "noinsert", "preview" }
opt.shortmess:append("c")          -- suppress "match N of M" completion messages
opt.shortmess:append("I")          -- suppress intro screen
opt.shortmess:append("W")          -- suppress "written" message
opt.shortmess:append("s")          -- suppress "search hit BOTTOM" messages

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 13  DIFF MODE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.diffopt        = {
  "internal",      -- use internal diff library
  "filler",        -- show filler lines in diff
  "closeoff",      -- close diff when one window closes
  "iwhite",        -- ignore whitespace changes
  "linematch:60",  -- improved diff algorithm (Nvim ≥ 0.9)
  "algorithm:histogram", -- histogram diff algorithm (better than myers)
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 14  WILD MENU & PATH
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.wildmode       = "longest:full,full"
opt.wildignorecase = true
opt.wildignore:append({
  "*.o", "*.a", "*.so", "*.pyc", "*.pyo",
  "*.class", "*.jar", "*.dll", "*.exe",
  "*.DS_Store", "Thumbs.db",
  ".git/", ".hg/", ".svn/",
  "node_modules/", ".cargo/", "target/",
  "__pycache__/", ".pytest_cache/",
  "*.egg-info/", ".tox/", ".venv/", "venv/",
  "dist/", "build/", ".next/", ".nuxt/",
  "*.min.js", "*.min.css",
})
opt.path:append("**")             -- search down into subfolders with :find
opt.suffixesadd:append({          -- file extensions for gf / <C-W>f
  ".lua", ".py", ".js", ".ts",
  ".tsx", ".jsx", ".rs", ".go",
  ".sh", ".fish", ".md", ".toml",
  ".json", ".yaml", ".yml",
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 15  FORMAT OPTIONS (how Vim auto-wraps and inserts comment leaders)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Managed here globally; filetype plugins may extend this.
opt.formatoptions  = vim.opt.formatoptions
  - "a"   -- no auto-format paragraphs
  - "t"   -- no auto-wrap text at textwidth
  + "c"   -- auto-wrap comments at textwidth
  + "q"   -- allow formatting of comments with gq
  + "j"   -- remove comment leader when joining lines
  + "r"   -- insert comment leader after <CR> in insert mode
  + "n"   -- recognise numbered lists
  + "l"   -- long lines not broken in insert mode
  + "1"   -- don't break after one-letter word

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 16  SESSION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.sessionoptions = {
  "buffers",
  "curdir",
  "folds",
  "globals",
  "help",
  "tabpages",
  "terminal",
  "winpos",
  "winsize",
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 17  PERFORMANCE TUNING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
opt.lazyredraw     = false         -- must be OFF for animations (noice, mini.animate)
opt.redrawtime     = 1500          -- max ms for syntax highlight before giving up
opt.synmaxcol      = 240           -- stop syntax highlight past column 240
opt.maxmempattern  = 2000          -- max KB for pattern matching

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 18  CLIPBOARD (Wayland-native via wl-clipboard)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- When running inside Wayland, configure the OSC 52 clipboard provider
-- for seamless copy-paste in Kitty / Ghostty / WezTerm.
if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-copy") == 1 then
  vim.g.clipboard = {
    name  = "wl-clipboard (Wayland)",
    copy  = {
      ["+"] = { "wl-copy", "--foreground", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--foreground", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = function()
        return vim.fn.systemlist("wl-paste --no-newline")
      end,
      ["*"] = function()
        return vim.fn.systemlist("wl-paste --no-newline --primary")
      end,
    },
    cache_enabled = true,
  }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 19  DIAGNOSTICS GLOBAL CONFIG
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.diagnostic.config({
  -- Virtual text: inline after the line
  virtual_text = {
    spacing  = 4,
    prefix   = "●",
    severity = { min = vim.diagnostic.severity.HINT },
    format   = function(d)
      local icons = {
        [vim.diagnostic.severity.ERROR] = Ash.icons.diagnostics.Error,
        [vim.diagnostic.severity.WARN]  = Ash.icons.diagnostics.Warn,
        [vim.diagnostic.severity.INFO]  = Ash.icons.diagnostics.Info,
        [vim.diagnostic.severity.HINT]  = Ash.icons.diagnostics.Hint,
      }
      return (icons[d.severity] or "") .. d.message
    end,
  },
  -- Signs in the gutter
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = Ash.icons.diagnostics.Error,
      [vim.diagnostic.severity.WARN]  = Ash.icons.diagnostics.Warn,
      [vim.diagnostic.severity.INFO]  = Ash.icons.diagnostics.Info,
      [vim.diagnostic.severity.HINT]  = Ash.icons.diagnostics.Hint,
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticLineError",
      [vim.diagnostic.severity.WARN]  = "DiagnosticLineWarn",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticNumError",
      [vim.diagnostic.severity.WARN]  = "DiagnosticNumWarn",
    },
  },
  -- Hover float
  float = {
    border   = "rounded",
    source   = "if_many",
    header   = "",
    prefix   = "  ",
    suffix   = "",
    focusable = false,
    max_width = 80,
  },
  underline      = true,
  update_in_insert = false,       -- don't update diagnostics in insert mode
  severity_sort  = true,
})