-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM OPTIONS (100+ settings)               ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local opt = vim.opt
local g   = vim.g

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📄 EDITING
-- ═══════════════════════════════════════════════════════════════════════════════

opt.expandtab    = true          -- Use spaces instead of tabs
opt.tabstop      = 4             -- Tab width = 4 spaces
opt.shiftwidth   = 4             -- Indent width = 4 spaces
opt.softtabstop  = 4             -- Soft tab stop
opt.smarttab     = true          -- Smart tab behavior
opt.smartindent  = true          -- Smart indentation
opt.autoindent   = true          -- Auto-indent new lines
opt.wrap         = false         -- No line wrapping
opt.linebreak    = true          -- Break at word boundaries if wrap=true
opt.breakindent  = true          -- Maintain indent when wrapping
opt.textwidth    = 0             -- No hard text width limit
opt.colorcolumn  = "120"         -- Visual guide at 120 chars
opt.formatoptions = "tcqjron"    -- Formatting options

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔍 SEARCH
-- ═══════════════════════════════════════════════════════════════════════════════

opt.ignorecase   = true          -- Case-insensitive search
opt.smartcase    = true          -- Case-sensitive if uppercase in query
opt.incsearch    = true          -- Incremental search
opt.hlsearch     = true          -- Highlight search results
opt.grepprg      = "rg --vimgrep --smart-case"
opt.grepformat   = "%f:%l:%c:%m"

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 UI ELEMENTS
-- ═══════════════════════════════════════════════════════════════════════════════

opt.number           = true      -- Show line numbers
opt.relativenumber   = true      -- Relative line numbers
opt.numberwidth      = 4         -- Number column width
opt.signcolumn       = "yes:2"   -- Always show sign column (2 wide)
opt.cursorline       = true      -- Highlight current line
opt.cursorlineopt    = "line"    -- Only highlight the line, not number
opt.showmode         = false     -- Don't show mode (statusline handles it)
opt.ruler            = false     -- Don't show ruler (statusline handles it)
opt.showcmd          = false     -- Don't show partial command
opt.cmdheight        = 1         -- Command bar height
opt.laststatus       = 3         -- Global statusline
opt.showtabline      = 2         -- Always show tabline
opt.scrolloff        = 8         -- Keep 8 lines visible above/below cursor
opt.sidescrolloff    = 8         -- Keep 8 cols visible left/right
opt.pumheight        = 10        -- Popup menu max height
opt.pumwidth         = 20        -- Popup menu min width
opt.pumblend         = 10        -- Popup menu transparency
opt.winblend         = 10        -- Window transparency
opt.conceallevel     = 2         -- Conceal markup (for markdown, etc.)
opt.concealcursor    = ""        -- Don't conceal on cursor line
opt.shortmess:append("sI")       -- Shorten messages
opt.fillchars = {
    fold      = "·",
    foldopen  = "",
    foldclose = "",
    foldsep   = "│",
    diff      = "─",
    eob       = " ",             -- Hide ~ for empty lines
    horiz     = "─",
    horizup   = "┴",
    horizdown = "┬",
    vert      = "│",
    vertleft  = "┤",
    vertright = "├",
    verthoriz = "┼",
}
opt.listchars = {
    tab      = "→ ",
    space    = "·",
    nbsp     = "󱁐",
    extends  = "›",
    precedes = "‹",
    trail    = "·",
    eol      = "↲",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 COLORS & APPEARANCE
-- ═══════════════════════════════════════════════════════════════════════════════

opt.termguicolors    = true      -- True color support
opt.background       = "dark"    -- Dark background
opt.synmaxcol        = 300       -- Syntax highlight limit per line

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📁 FILES & ENCODING
-- ═══════════════════════════════════════════════════════════════════════════════

opt.encoding         = "utf-8"
opt.fileencoding     = "utf-8"
opt.fileencodings    = { "utf-8", "utf-16", "latin1" }
opt.fileformats      = { "unix", "dos", "mac" }
opt.fixeol           = true      -- Fix end-of-line at save
opt.bomb             = false     -- No BOM

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💾 BACKUP & UNDO
-- ═══════════════════════════════════════════════════════════════════════════════

local data_dir = vim.fn.stdpath("data")

opt.backup       = false         -- No backup files
opt.writebackup  = false         -- No backup before write
opt.swapfile     = false         -- No swap files
opt.undofile     = true          -- Persistent undo
opt.undodir      = data_dir .. "/undo"
opt.undolevels   = 10000         -- Undo history depth

-- Auto-create undo directory
vim.fn.mkdir(data_dir .. "/undo", "p")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔄 COMPLETION
-- ═══════════════════════════════════════════════════════════════════════════════

opt.completeopt = {
    "menu",        -- Show completion menu
    "menuone",     -- Show menu even with one item
    "noselect",    -- Don't auto-select
    "noinsert",    -- Don't auto-insert
    "preview",     -- Show preview window
}
opt.wildmenu         = true      -- Enhanced command completion
opt.wildmode         = "longest:full,full"
opt.wildignorecase   = true
opt.wildignore       = {
    "*.o", "*.obj", "*.pyc", "*.pyo", "*.pyd",
    "*.dll", "*.exe", "*.so", "*.a",
    ".git", ".hg", ".svn",
    "node_modules", "__pycache__", ".venv",
    "*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp",
    "*.zip", "*.tar", "*.gz", "*.rar",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⌨️ INPUT & KEYS
-- ═══════════════════════════════════════════════════════════════════════════════

opt.timeoutlen   = 300           -- Key sequence timeout (ms)
opt.ttimeoutlen  = 10            -- Key code timeout (ms)
opt.updatetime   = 200           -- Faster completion and CursorHold
opt.redrawtime   = 1500          -- Max time for syntax highlighting
opt.mouse        = "a"           -- Enable mouse in all modes
opt.mousemoveevent = true        -- Track mouse movement
opt.clipboard    = "unnamedplus" -- System clipboard integration
opt.backspace    = { "indent", "eol", "start" }  -- Backspace behavior

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🗂️ SPLITS & WINDOWS
-- ═══════════════════════════════════════════════════════════════════════════════

opt.splitbelow   = true          -- Horizontal splits go below
opt.splitright   = true          -- Vertical splits go right
opt.splitkeepmode = "cursor"     -- Keep cursor position when splitting
opt.equalalways  = false         -- Don't auto-resize splits

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔀 DIFF
-- ═══════════════════════════════════════════════════════════════════════════════

opt.diffopt = {
    "internal",
    "filler",
    "closeoff",
    "hiddenoff",
    "algorithm:patience",
    "linematch:60",
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📂 FILE BROWSER (netrw)
-- ═══════════════════════════════════════════════════════════════════════════════

g.netrw_banner      = 0          -- No banner
g.netrw_liststyle   = 3          -- Tree style
g.netrw_browse_split = 4         -- Open in previous window
g.netrw_altv        = 1          -- vsplit
g.netrw_winsize     = 25         -- 25% width

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 FOLD
-- ═══════════════════════════════════════════════════════════════════════════════

opt.foldmethod   = "expr"
opt.foldexpr     = "nvim_treesitter#foldexpr()"
opt.foldlevel    = 99            -- Start with all folds open
opt.foldlevelstart = 99
opt.foldnestmax  = 5

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🌐 SPELLING
-- ═══════════════════════════════════════════════════════════════════════════════

opt.spell        = false         -- Disabled by default
opt.spelllang    = { "en_us" }
opt.spelloptions = "camel"       -- CamelCase word splitting

-- ═══════════════════════════════════════════════════════════════════════════════
-- ⚡ PERFORMANCE
-- ═══════════════════════════════════════════════════════════════════════════════

opt.lazyredraw   = false         -- Don't defer redraws (causes issues)
opt.regexpengine = 1             -- Use old regexp engine (faster for some patterns)
opt.ttyfast      = true          -- Fast terminal connection