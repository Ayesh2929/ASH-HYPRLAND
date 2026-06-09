-- ╔═══════════════════════════════════════════════════════════════════════════════╗
-- ║           ASH DOTFILES v3.0 — NEOVIM KEYMAPS (200+ binds)                 ║
-- ║           Comprehensive keybinding configuration for all modes             ║
-- ╚═══════════════════════════════════════════════════════════════════════════════╝

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Helper to create maps with description
local function nmap(key, cmd, desc, extra_opts)
    local o = vim.tbl_extend("force", opts, { desc = desc }, extra_opts or {})
    map("n", key, cmd, o)
end
local function vmap(key, cmd, desc) map("v", key, cmd, vim.tbl_extend("force", opts, { desc = desc })) end
local function imap(key, cmd, desc) map("i", key, cmd, vim.tbl_extend("force", opts, { desc = desc })) end
local function tmap(key, cmd, desc) map("t", key, cmd, vim.tbl_extend("force", opts, { desc = desc })) end
local function xmap(key, cmd, desc) map("x", key, cmd, vim.tbl_extend("force", opts, { desc = desc })) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 BASIC REMAPS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Better escape
imap("jk",   "<Esc>",    "Escape insert mode")
imap("jj",   "<Esc>",    "Escape insert mode (alt)")
imap("kj",   "<Esc>",    "Escape insert mode (alt2)")

-- Don't yank on delete char
nmap("x",    '"_x',      "Delete char without yanking")
nmap("X",    '"_X',      "Delete char back without yanking")

-- Don't yank on paste in visual
vmap("p",    '"_dP',     "Paste without yanking selection")
vmap("P",    '"_dP',     "Paste without yanking selection (alt)")

-- Keep cursor centered when scrolling
nmap("<C-d>", "<C-d>zz", "Scroll down and center")
nmap("<C-u>", "<C-u>zz", "Scroll up and center")

-- Keep cursor centered on search
nmap("n",    "nzzzv",    "Next search result centered")
nmap("N",    "Nzzzv",    "Prev search result centered")

-- Keep cursor centered on join
nmap("J",    "mzJ`z",    "Join lines keep cursor position")

-- Better indenting in visual mode
vmap("<",    "<gv",      "Indent left and reselect")
vmap(">",    ">gv",      "Indent right and reselect")

-- Move lines up/down in visual mode
vmap("<A-j>", ":m '>+1<CR>gv=gv", "Move line down")
vmap("<A-k>", ":m '<-2<CR>gv=gv", "Move line up")
nmap("<A-j>", ":m .+1<CR>==",     "Move line down")
nmap("<A-k>", ":m .-2<CR>==",     "Move line up")
imap("<A-j>", "<Esc>:m .+1<CR>==gi", "Move line down")
imap("<A-k>", "<Esc>:m .-2<CR>==gi", "Move line up")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔍 SEARCH & REPLACE
-- ═══════════════════════════════════════════════════════════════════════════════

-- Clear search highlight
nmap("<Esc>",    "<cmd>nohlsearch<CR>",           "Clear search highlight")
nmap("<leader>/", "<cmd>nohlsearch<CR>",          "Clear search highlight")

-- Search word under cursor
nmap("*",    "*N",       "Search word under cursor (stay)")
nmap("#",    "#N",       "Search word under cursor back (stay)")

-- Global search & replace word under cursor
nmap("<leader>rw", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>",
    "Replace word under cursor (global)")

-- Search in project with Telescope
nmap("<leader>sg", "<cmd>Telescope live_grep<CR>",       "Search grep in project")
nmap("<leader>sw", "<cmd>Telescope grep_string<CR>",     "Search word in project")
nmap("<leader>sf", "<cmd>Telescope find_files<CR>",      "Search files")
nmap("<leader>sr", "<cmd>Telescope oldfiles<CR>",        "Recent files")
nmap("<leader>sb", "<cmd>Telescope buffers<CR>",         "Search open buffers")
nmap("<leader>sh", "<cmd>Telescope help_tags<CR>",       "Search help")
nmap("<leader>sk", "<cmd>Telescope keymaps<CR>",         "Search keymaps")
nmap("<leader>sc", "<cmd>Telescope commands<CR>",        "Search commands")
nmap("<leader>sm", "<cmd>Telescope marks<CR>",           "Search marks")
nmap("<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", "Search document symbols")
nmap("<leader>sS", "<cmd>Telescope lsp_workspace_symbols<CR>","Search workspace symbols")
nmap("<leader>sd", "<cmd>Telescope diagnostics<CR>",     "Search diagnostics")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📁 FILE NAVIGATION
-- ═══════════════════════════════════════════════════════════════════════════════

-- File explorer
nmap("<leader>e",   "<cmd>NvimTreeToggle<CR>",    "Toggle file explorer")
nmap("<leader>E",   "<cmd>NvimTreeFocus<CR>",     "Focus file explorer")
nmap("<leader>ef",  "<cmd>NvimTreeFindFile<CR>",  "Find current file in explorer")

-- Quick file access
nmap("<leader>ff",  "<cmd>Telescope find_files<CR>",               "Find file")
nmap("<leader>fp",  "<cmd>Telescope find_files cwd=~/.dotfiles<CR>","Find dotfile")
nmap("<leader>fc",  "<cmd>Telescope find_files cwd=~/.config<CR>", "Find config file")
nmap("<leader>fn",  "<cmd>enew<CR>",                               "New file")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🗂️ BUFFER MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════

-- Navigate buffers
nmap("<S-l>",       "<cmd>bnext<CR>",               "Next buffer")
nmap("<S-h>",       "<cmd>bprevious<CR>",            "Previous buffer")
nmap("<Tab>",       "<cmd>bnext<CR>",               "Next buffer")
nmap("<S-Tab>",     "<cmd>bprevious<CR>",            "Previous buffer")
nmap("<leader>bb",  "<cmd>Telescope buffers<CR>",   "Buffer list")
nmap("<leader>bp",  "<cmd>bprevious<CR>",            "Previous buffer")
nmap("<leader>bn",  "<cmd>bnext<CR>",               "Next buffer")
nmap("<leader>bd",  "<cmd>Bdelete<CR>",             "Delete buffer (keep window)")
nmap("<leader>bD",  "<cmd>Bdelete!<CR>",            "Force delete buffer")
nmap("<leader>ba",  "<cmd>bufdo Bdelete<CR>",       "Delete all buffers")
nmap("<leader>bo",  "<cmd>%Bdelete|edit#|bdelete#<CR>", "Close other buffers")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🪟 WINDOW MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════

-- Navigate splits (CTRL+hjkl)
nmap("<C-h>",   "<C-w>h",       "Move to left window")
nmap("<C-j>",   "<C-w>j",       "Move to bottom window")
nmap("<C-k>",   "<C-w>k",       "Move to top window")
nmap("<C-l>",   "<C-w>l",       "Move to right window")

-- Resize splits
nmap("<C-Up>",    "<cmd>resize +2<CR>",           "Increase window height")
nmap("<C-Down>",  "<cmd>resize -2<CR>",           "Decrease window height")
nmap("<C-Left>",  "<cmd>vertical resize -2<CR>",  "Decrease window width")
nmap("<C-Right>", "<cmd>vertical resize +2<CR>",  "Increase window width")

-- Split creation
nmap("<leader>wv", "<cmd>vsplit<CR>",             "Vertical split")
nmap("<leader>ws", "<cmd>split<CR>",              "Horizontal split")
nmap("<leader>we", "<C-w>=",                      "Equal split sizes")
nmap("<leader>wm", "<C-w>_<C-w>|",               "Maximize window")
nmap("<leader>wc", "<cmd>close<CR>",              "Close window")
nmap("<leader>wo", "<cmd>only<CR>",               "Close other windows")
nmap("<leader>wr", "<C-w>r",                      "Rotate windows")
nmap("<leader>wx", "<C-w>x",                      "Exchange windows")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🗂️ TAB MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader>tn",  "<cmd>tabnew<CR>",            "New tab")
nmap("<leader>tc",  "<cmd>tabclose<CR>",          "Close tab")
nmap("<leader>to",  "<cmd>tabonly<CR>",           "Close other tabs")
nmap("<leader>t1",  "1gt",                        "Go to tab 1")
nmap("<leader>t2",  "2gt",                        "Go to tab 2")
nmap("<leader>t3",  "3gt",                        "Go to tab 3")
nmap("]t",          "<cmd>tabnext<CR>",           "Next tab")
nmap("[t",          "<cmd>tabprevious<CR>",       "Previous tab")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💻 LSP KEYMAPS (set here, activated per buffer in after/plugin/lsp-attach.lua)
-- ═══════════════════════════════════════════════════════════════════════════════

-- These are set globally but work best when LSP is attached
-- See after/plugin/lsp-attach.lua for buffer-local LSP mappings
nmap("gd",      "<cmd>Telescope lsp_definitions<CR>",     "Go to definition")
nmap("gD",      "<cmd>lua vim.lsp.buf.declaration()<CR>", "Go to declaration")
nmap("gr",      "<cmd>Telescope lsp_references<CR>",      "Go to references")
nmap("gi",      "<cmd>Telescope lsp_implementations<CR>", "Go to implementation")
nmap("gt",      "<cmd>Telescope lsp_type_definitions<CR>","Go to type definition")
nmap("K",       "<cmd>lua vim.lsp.buf.hover()<CR>",       "Show hover docs")
nmap("<C-k>",   "<cmd>lua vim.lsp.buf.signature_help()<CR>","Show signature help")
nmap("<leader>ca","<cmd>lua vim.lsp.buf.code_action()<CR>","Code actions")
nmap("<leader>cr","<cmd>lua vim.lsp.buf.rename()<CR>",    "Rename symbol")
nmap("<leader>cf","<cmd>lua vim.lsp.buf.format({async=true})<CR>","Format file")

-- Diagnostics navigation
nmap("[d",      "<cmd>lua vim.diagnostic.goto_prev()<CR>",        "Previous diagnostic")
nmap("]d",      "<cmd>lua vim.diagnostic.goto_next()<CR>",        "Next diagnostic")
nmap("[e",      "<cmd>lua vim.diagnostic.goto_prev({severity=vim.diagnostic.severity.ERROR})<CR>","Previous error")
nmap("]e",      "<cmd>lua vim.diagnostic.goto_next({severity=vim.diagnostic.severity.ERROR})<CR>","Next error")
nmap("<leader>cd","<cmd>lua vim.diagnostic.open_float()<CR>",     "Show diagnostic")
nmap("<leader>cD","<cmd>Telescope diagnostics<CR>",               "All diagnostics")
nmap("<leader>cl","<cmd>lua vim.lsp.codelens.run()<CR>",          "Run code lens")
nmap("<leader>ci","<cmd>LspInfo<CR>",                             "LSP info")
nmap("<leader>cR","<cmd>LspRestart<CR>",                          "Restart LSP")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔧 GIT INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader>gg",  "<cmd>LazyGit<CR>",                "Open LazyGit")
nmap("<leader>gs",  "<cmd>Telescope git_status<CR>",   "Git status")
nmap("<leader>gb",  "<cmd>Telescope git_branches<CR>", "Git branches")
nmap("<leader>gc",  "<cmd>Telescope git_commits<CR>",  "Git commits")
nmap("<leader>gd",  "<cmd>Gitsigns diffthis<CR>",      "Git diff")
nmap("<leader>gD",  "<cmd>Gitsigns diffthis HEAD<CR>", "Git diff HEAD")
nmap("<leader>gp",  "<cmd>Gitsigns preview_hunk<CR>",  "Preview hunk")
nmap("<leader>gP",  "<cmd>Gitsigns preview_hunk_inline<CR>","Preview hunk inline")
nmap("<leader>gr",  "<cmd>Gitsigns reset_hunk<CR>",    "Reset hunk")
nmap("<leader>gR",  "<cmd>Gitsigns reset_buffer<CR>",  "Reset buffer")
nmap("<leader>gs",  "<cmd>Gitsigns stage_hunk<CR>",    "Stage hunk")
nmap("<leader>gS",  "<cmd>Gitsigns stage_buffer<CR>",  "Stage buffer")
nmap("<leader>gu",  "<cmd>Gitsigns undo_stage_hunk<CR>","Undo stage hunk")
nmap("<leader>gl",  "<cmd>Gitsigns blame_line<CR>",    "Blame line")
nmap("<leader>gL",  "<cmd>Gitsigns toggle_current_line_blame<CR>","Toggle blame")
nmap("]h",          "<cmd>Gitsigns next_hunk<CR>",     "Next git hunk")
nmap("[h",          "<cmd>Gitsigns prev_hunk<CR>",     "Previous git hunk")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔭 TELESCOPE
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader><leader>", "<cmd>Telescope find_files<CR>",  "Find files (quick)")
nmap("<leader>,",        "<cmd>Telescope buffers<CR>",     "Switch buffer (quick)")
nmap("<leader>.",        "<cmd>Telescope file_browser<CR>","File browser")
nmap("<leader>:",        "<cmd>Telescope command_history<CR>","Command history")
nmap("<leader>'",        "<cmd>Telescope registers<CR>",   "Registers")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🖥️ TERMINAL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Toggle terminal
nmap("<leader>ft", "<cmd>ToggleTerm<CR>",              "Toggle terminal")
nmap("<C-\\>",     "<cmd>ToggleTerm<CR>",              "Toggle terminal")

-- Terminal mode escape
tmap("<Esc>",   "<C-\\><C-n>",  "Escape terminal mode")
tmap("jk",      "<C-\\><C-n>",  "Escape terminal mode (alt)")
tmap("<C-h>",   "<C-\\><C-n><C-w>h", "Navigate left from terminal")
tmap("<C-j>",   "<C-\\><C-n><C-w>j", "Navigate down from terminal")
tmap("<C-k>",   "<C-\\><C-n><C-w>k", "Navigate up from terminal")
tmap("<C-l>",   "<C-\\><C-n><C-w>l", "Navigate right from terminal")

-- Specific terminal types
nmap("<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>","Horizontal terminal")
nmap("<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>",  "Vertical terminal")
nmap("<leader>tf", "<cmd>ToggleTerm direction=float<CR>",     "Float terminal")
nmap("<leader>tg", "<cmd>LazyGit<CR>",                        "LazyGit terminal")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔖 MARKS & JUMPS
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader>mb",  "<cmd>Telescope marks<CR>",        "Browse marks")
nmap("<leader>md",  "<cmd>delmarks!<CR>",              "Delete all marks")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎨 UI TOGGLES
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader>ul",  "<cmd>set number!<CR>",            "Toggle line numbers")
nmap("<leader>ur",  "<cmd>set relativenumber!<CR>",    "Toggle relative numbers")
nmap("<leader>uw",  "<cmd>set wrap!<CR>",              "Toggle line wrap")
nmap("<leader>us",  "<cmd>set spell!<CR>",             "Toggle spell check")
nmap("<leader>ui",  "<cmd>set list!<CR>",              "Toggle invisible chars")
nmap("<leader>uc",  "<cmd>set cursorline!<CR>",        "Toggle cursor line")
nmap("<leader>uf",  "<cmd>lua require('utils').toggle_fold()<CR>","Toggle fold method")
nmap("<leader>uz",  "<cmd>ZenMode<CR>",                "Toggle zen mode")
nmap("<leader>uT",  "<cmd>TransparentToggle<CR>",      "Toggle transparency")
nmap("<leader>uh",  "<cmd>nohlsearch<CR>",             "Clear highlights")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📋 CLIPBOARD & YANKING
-- ═══════════════════════════════════════════════════════════════════════════════

-- Yank to system clipboard
nmap("<leader>y",   '"+y',      "Yank to clipboard")
vmap("<leader>y",   '"+y',      "Yank selection to clipboard")
nmap("<leader>Y",   '"+Y',      "Yank line to clipboard")

-- Paste from system clipboard
nmap("<leader>p",   '"+p',      "Paste from clipboard (after)")
nmap("<leader>P",   '"+P',      "Paste from clipboard (before)")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📝 EDITING HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Insert blank line without entering insert mode
nmap("<leader>o",   "o<Esc>",   "Insert line below")
nmap("<leader>O",   "O<Esc>",   "Insert line above")

-- Duplicate line
nmap("<leader>d",   "yyp",      "Duplicate line")

-- Add semicolon/comma to end of line
nmap("<leader>;",   "A;<Esc>",  "Add semicolon to end of line")
nmap("<leader>,",   "A,<Esc>",  "Add comma to end of line")  -- conflicts with telescope, adjust

-- Sort lines
vmap("<leader>ss",  ":sort<CR>","Sort selected lines")
vmap("<leader>si",  ":sort i<CR>","Sort case-insensitive")
vmap("<leader>su",  ":sort u<CR>","Sort and remove duplicates")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔄 QUICKFIX & LOCATION LIST
-- ═══════════════════════════════════════════════════════════════════════════════

nmap("<leader>qo",  "<cmd>copen<CR>",   "Open quickfix")
nmap("<leader>qc",  "<cmd>cclose<CR>",  "Close quickfix")
nmap("<leader>qn",  "<cmd>cnext<CR>",   "Next quickfix")
nmap("<leader>qp",  "<cmd>cprev<CR>",   "Previous quickfix")
nmap("<leader>qf",  "<cmd>cfirst<CR>",  "First quickfix")
nmap("<leader>ql",  "<cmd>clast<CR>",   "Last quickfix")
nmap("]q",          "<cmd>cnext<CR>",   "Next quickfix")
nmap("[q",          "<cmd>cprev<CR>",   "Previous quickfix")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 💾 SAVE & QUIT
-- ═══════════════════════════════════════════════════════════════════════════════

-- Save
nmap("<leader>w",   "<cmd>w<CR>",       "Save file")
nmap("<leader>W",   "<cmd>wa<CR>",      "Save all files")
nmap("<C-s>",       "<cmd>w<CR>",       "Save file")
imap("<C-s>",       "<Esc><cmd>w<CR>",  "Save file from insert mode")

-- Quit
nmap("<leader>q",   "<cmd>confirm q<CR>","Quit")
nmap("<leader>Q",   "<cmd>confirm qa<CR>","Quit all")
nmap("<leader>!",   "<cmd>q!<CR>",      "Force quit")

-- Save and quit
nmap("<leader>x",   "<cmd>x<CR>",       "Save and quit")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🎮 MISC
-- ═══════════════════════════════════════════════════════════════════════════════

-- Run current file
nmap("<leader>rr",  "<cmd>lua require('utils').run_file()<CR>","Run current file")

-- Open file manager
nmap("<leader>fF",  "<cmd>!nemo %:h &<CR>",            "Open file manager here")

-- Reload config
nmap("<leader>cr",  "<cmd>source $MYVIMRC<CR>",        "Reload Neovim config")

-- Which-key popup
nmap("<leader>?",   "<cmd>WhichKey<CR>",               "Which-key")

-- Toggle diagnostics
nmap("<leader>uD",  "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>",
    "Toggle diagnostics")

-- Macro shortcut
nmap("Q",   "@q",           "Replay macro q")
vmap("Q",   ":norm @q<CR>", "Replay macro q on selection")

-- Center on various motions
nmap("gg",  "ggzz",         "Go to top centered")
nmap("G",   "Gzz",          "Go to bottom centered")
nmap("{",   "{zz",          "Prev paragraph centered")
nmap("}",   "}zz",          "Next paragraph centered")

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚀 WHICH-KEY GROUPS (labels for keymap prefixes)
-- ═══════════════════════════════════════════════════════════════════════════════

local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
    wk.register({
        ["<leader>b"]  = { name = "󰓩 Buffers" },
        ["<leader>c"]  = { name = " Code/LSP" },
        ["<leader>d"]  = { name = " Debug" },
        ["<leader>e"]  = { name = "󰉋 Explorer" },
        ["<leader>f"]  = { name = "󰍉 Find/Files" },
        ["<leader>g"]  = { name = " Git" },
        ["<leader>m"]  = { name = " Marks" },
        ["<leader>q"]  = { name = " Quickfix" },
        ["<leader>r"]  = { name = " Run/Replace" },
        ["<leader>s"]  = { name = "󰍉 Search" },
        ["<leader>t"]  = { name = " Terminal" },
        ["<leader>u"]  = { name = "󰒓 UI/Toggle" },
        ["<leader>w"]  = { name = "󱂬 Windows" },
        ["<leader>x"]  = { name = "󰅩 Diagnostics" },
        ["]"]           = { name = " Next" },
        ["["]           = { name = " Prev" },
        ["g"]           = { name = "󰑕 Go to" },
    })
end