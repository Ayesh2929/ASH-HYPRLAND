-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/keymaps.lua — Base Keymaps                                        ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Conventions:                                                                ║
-- ║    <leader>      = Space   (global actions)                                  ║
-- ║    <localleader> = Comma   (buffer-local / filetype actions)                 ║
-- ║    <C-...>       = Ctrl    (low-level / navigation)                          ║
-- ║    <M-...>       = Alt     (window / UI)                                     ║
-- ║                                                                              ║
-- ║  Plugin-specific keymaps live inside their plugin spec (lazy key = {})       ║
-- ║  This file only contains keys that work WITHOUT any plugin loaded.           ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ── Helpers ──────────────────────────────────────────────────────────────────

---Thin wrapper around vim.keymap.set with sane defaults
---@param modes string|string[]
---@param lhs   string
---@param rhs   string|function
---@param opts  table?
local function map(modes, lhs, rhs, opts)
    opts = vim.tbl_extend("force", {
      silent      = true,
      noremap     = true,
      nowait      = false,
      desc        = nil,
    }, opts or {})
    vim.keymap.set(modes, lhs, rhs, opts)
  end
  
  -- Convenience mode aliases
  local n   = "n"
  local i   = "i"
  local v   = "v"
  local x   = "x"
  local c   = "c"
  local t   = "t"
  local o   = "o"
  local nv  = { "n", "v" }
  local ni  = { "n", "i" }
  local nvi = { "n", "v", "i" }
  local nx  = { "n", "x" }
  local nix = { "n", "i", "x" }
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 01  BETTER DEFAULTS (ergonomic overrides for built-ins)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Move through wrapped visual lines, not logical lines
  map(nv, "j",  "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down (visual line)" })
  map(nv, "k",  "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up (visual line)" })
  
  -- Keep the cursor centred when jumping through search matches
  map(n, "n",  "nzzzv",  { desc = "Next match (centred)" })
  map(n, "N",  "Nzzzv",  { desc = "Prev match (centred)" })
  
  -- Keep the cursor centred on <C-d>/<C-u>
  map(n, "<C-d>", "<C-d>zz", { desc = "Scroll down (centred)" })
  map(n, "<C-u>", "<C-u>zz", { desc = "Scroll up (centred)" })
  
  -- Join lines without moving cursor
  map(n, "J", "mzJ`z", { desc = "Join lines (preserve cursor)" })
  
  -- Y yanks to end of line (consistent with D, C)
  map(n, "Y", "y$", { desc = "Yank to end of line" })
  
  -- Better paste in visual: keep register after paste
  map(x, "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })
  
  -- Delete to black hole register (don't pollute clipboard)
  map(nv, "<leader>d", [["_d]], { desc = "Delete to black hole" })
  
  -- Redo with U (more intuitive complement to u)
  map(n, "U", "<C-r>", { desc = "Redo" })
  
  -- Select-all
  map(n, "<C-a>", "ggVG", { desc = "Select all" })
  
  -- Save anywhere
  map(nix, "<C-s>", "<Cmd>w<CR><Esc>", { desc = "Save file" })
  
  -- Quit
  map(n, "<leader>q", "<Cmd>q<CR>",  { desc = "󰗼  Quit" })
  map(n, "<leader>Q", "<Cmd>qa!<CR>", { desc = "󰗼  Force quit all" })
  
  -- Force write (sudo)
  map(c, "w!!", "w !sudo tee % > /dev/null", { desc = "Sudo write" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 02  ESCAPE
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- jk / jj to escape insert mode (fastest ergonomic combos)
  map(i, "jk", "<Esc>",     { desc = "Exit insert mode" })
  map(i, "jj", "<Esc>",     { desc = "Exit insert mode" })
  
  -- Clear search highlight on Escape
  map(n, "<Esc>", function()
    vim.cmd("nohlsearch")
    -- Also dismiss any floating windows
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative ~= "" then
        vim.api.nvim_win_close(win, false)
      end
    end
  end, { desc = "Clear highlights & close floats" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 03  WINDOW MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Split creation
  map(n, "<leader>wv", "<C-w>v",          { desc = " Split vertical" })
  map(n, "<leader>ws", "<C-w>s",          { desc = " Split horizontal" })
  map(n, "<leader>we", "<C-w>=",          { desc = "  Equalise splits" })
  map(n, "<leader>wx", "<Cmd>close<CR>",  { desc = "  Close split" })
  
  -- Navigate splits with Ctrl+hjkl (works with tmux-navigator)
  map(nix, "<C-h>", "<C-w>h", { desc = "  Window left" })
  map(nix, "<C-j>", "<C-w>j", { desc = "  Window down" })
  map(nix, "<C-k>", "<C-w>k", { desc = "  Window up" })
  map(nix, "<C-l>", "<C-w>l", { desc = "  Window right" })
  
  -- Resize with Alt+arrow keys
  map(n, "<M-Up>",    "<Cmd>resize +2<CR>",           { desc = "Resize window ↑" })
  map(n, "<M-Down>",  "<Cmd>resize -2<CR>",           { desc = "Resize window ↓" })
  map(n, "<M-Left>",  "<Cmd>vertical resize -2<CR>",  { desc = "Resize window ←" })
  map(n, "<M-Right>", "<Cmd>vertical resize +2<CR>",  { desc = "Resize window →" })
  
  -- Window zoom toggle (expand current split to full)
  map(n, "<leader>wz", function()
    if vim.t.zoomed then
      vim.cmd(vim.t.zoom_winrestcmd)
      vim.t.zoomed = false
    else
      vim.t.zoom_winrestcmd = vim.fn.winrestcmd()
      vim.cmd("resize | vertical resize")
      vim.t.zoomed = true
    end
  end, { desc = "  Toggle window zoom" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 04  BUFFER MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(n, "<S-l>",      "<Cmd>bnext<CR>",             { desc = "  Next buffer" })
  map(n, "<S-h>",      "<Cmd>bprevious<CR>",          { desc = "  Prev buffer" })
  map(n, "<leader>bd", "<Cmd>bdelete<CR>",            { desc = "  Delete buffer" })
  map(n, "<leader>bD", "<Cmd>bdelete!<CR>",           { desc = "  Force delete buffer" })
  map(n, "<leader>bo", "<Cmd>%bdelete|edit#|bdelete#<CR>", { desc = "  Delete other buffers" })
  map(n, "<leader>bn", "<Cmd>enew<CR>",               { desc = "  New buffer" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 05  TAB MANAGEMENT
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(n, "<leader><Tab>n", "<Cmd>tabnew<CR>",   { desc = "  New tab" })
  map(n, "<leader><Tab>x", "<Cmd>tabclose<CR>", { desc = "  Close tab" })
  map(n, "<leader><Tab>]", "<Cmd>tabnext<CR>",  { desc = "  Next tab" })
  map(n, "<leader><Tab>[", "<Cmd>tabprev<CR>",  { desc = "  Prev tab" })
  map(n, "<leader><Tab>f", "<Cmd>tabfirst<CR>", { desc = "  First tab" })
  map(n, "<leader><Tab>l", "<Cmd>tablast<CR>",  { desc = "  Last tab" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 06  INDENTATION (keep visual selection)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(v, "<", "<gv", { desc = "Indent left (keep selection)" })
  map(v, ">", ">gv", { desc = "Indent right (keep selection)" })
  map(v, "<Tab>",   ">gv", { desc = "Indent right" })
  map(v, "<S-Tab>", "<gv", { desc = "Indent left" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 07  MOVE LINES (Alt+j/k — works in all modes)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(n, "<M-j>", "<Cmd>m .+1<CR>==",       { desc = "  Move line down" })
  map(n, "<M-k>", "<Cmd>m .-2<CR>==",       { desc = "  Move line up" })
  map(i, "<M-j>", "<Esc><Cmd>m .+1<CR>==gi", { desc = "  Move line down" })
  map(i, "<M-k>", "<Esc><Cmd>m .-2<CR>==gi", { desc = "  Move line up" })
  map(v, "<M-j>", ":m '>+1<CR>gv=gv",       { desc = "  Move selection down" })
  map(v, "<M-k>", ":m '<-2<CR>gv=gv",       { desc = "  Move selection up" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 08  DIAGNOSTIC NAVIGATION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(n, "]d", function()
    vim.diagnostic.goto_next({ float = true })
  end, { desc = "  Next diagnostic" })
  
  map(n, "[d", function()
    vim.diagnostic.goto_prev({ float = true })
  end, { desc = "  Prev diagnostic" })
  
  map(n, "]e", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
  end, { desc = "  Next error" })
  
  map(n, "[e", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
  end, { desc = "  Prev error" })
  
  map(n, "]w", function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
  end, { desc = "  Next warning" })
  
  map(n, "[w", function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
  end, { desc = "  Prev warning" })
  
  map(n, "<leader>e", vim.diagnostic.open_float,   { desc = "  Show diagnostic float" })
  map(n, "<leader>xl", "<Cmd>Trouble diagnostics toggle<CR>",
    { desc = "  Diagnostic list (Trouble)" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 09  QUICKFIX & LOCATION LIST
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(n, "]q", "<Cmd>cnext<CR>zz",     { desc = "  Next quickfix" })
  map(n, "[q", "<Cmd>cprev<CR>zz",     { desc = "  Prev quickfix" })
  map(n, "]Q", "<Cmd>clast<CR>zz",     { desc = "  Last quickfix" })
  map(n, "[Q", "<Cmd>cfirst<CR>zz",    { desc = "  First quickfix" })
  map(n, "<leader>xq", "<Cmd>copen<CR>",  { desc = "  Open quickfix" })
  map(n, "<leader>xQ", "<Cmd>cclose<CR>", { desc = "  Close quickfix" })
  
  map(n, "]l", "<Cmd>lnext<CR>zz",     { desc = "  Next location" })
  map(n, "[l", "<Cmd>lprev<CR>zz",     { desc = "  Prev location" })
  map(n, "<leader>xl", "<Cmd>lopen<CR>",  { desc = "  Open location list" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 10  TERMINAL
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Escape from terminal mode with Escape
  map(t, "<Esc><Esc>", "<C-\\><C-n>",   { desc = "Exit terminal mode" })
  map(t, "<C-h>",      "<Cmd>wincmd h<CR>", { desc = "Window left" })
  map(t, "<C-j>",      "<Cmd>wincmd j<CR>", { desc = "Window down" })
  map(t, "<C-k>",      "<Cmd>wincmd k<CR>", { desc = "Window up" })
  map(t, "<C-l>",      "<Cmd>wincmd l<CR>", { desc = "Window right" })
  
  -- Open a terminal in a bottom split
  map(n, "<leader>tt", function()
    vim.cmd("botright 12split | terminal")
    vim.cmd("startinsert")
  end, { desc = "  Open terminal (split)" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 11  CLIPBOARD & REGISTERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Yank to system clipboard explicitly
  map(nv, "<leader>y", [["+y]],   { desc = "  Yank to clipboard" })
  map(n,  "<leader>Y", [["+Y]],   { desc = "  Yank line to clipboard" })
  
  -- Paste from system clipboard
  map(nv, "<leader>P", [["+p]],   { desc = "  Paste from clipboard" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 12  UTILITY
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Toggle wrap
  map(n, "<leader>uw", "<Cmd>set wrap!<CR>", { desc = "  Toggle line wrap" })
  
  -- Toggle spell
  map(n, "<leader>us", "<Cmd>set spell!<CR>", { desc = "  Toggle spell check" })
  
  -- Toggle list chars
  map(n, "<leader>ul", "<Cmd>set list!<CR>", { desc = "  Toggle list chars" })
  
  -- Toggle relative numbers
  map(n, "<leader>un", function()
    vim.o.relativenumber = not vim.o.relativenumber
  end, { desc = "  Toggle relative numbers" })
  
  -- Toggle conceal level
  map(n, "<leader>uc", function()
    vim.o.conceallevel = vim.o.conceallevel == 0 and 2 or 0
  end, { desc = "  Toggle conceal" })
  
  -- Highlight word under cursor (without moving)
  map(n, "<leader>uh", function()
    local word = vim.fn.expand("<cword>")
    vim.fn.setreg("/", "\\<" .. word .. "\\>")
    vim.opt.hlsearch = true
  end, { desc = "  Highlight word" })
  
  -- Source current file (Lua / Vim)
  map(n, "<leader>so", function()
    if vim.bo.filetype == "lua" then
      vim.cmd("luafile %")
    else
      vim.cmd("source %")
    end
    vim.notify(" File sourced: " .. vim.fn.expand("%:t"), vim.log.levels.INFO, {
      title = "ASH NeoVim",
    })
  end, { desc = "  Source current file" })
  
  -- Inspect highlight group under cursor
  map(n, "<leader>ui", vim.show_pos, { desc = "  Inspect position" })
  
  -- Reload config
  map(n, "<leader>ur", function()
    vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua")
    vim.notify(" Config reloaded!", vim.log.levels.INFO, { title = "ASH NeoVim" })
  end, { desc = "  Reload config" })
  
  -- Open lazy.nvim UI
  map(n, "<leader>l", "<Cmd>Lazy<CR>", { desc = "󰒲  Lazy Plugin Manager" })
  
  -- Open mason.nvim UI
  map(n, "<leader>cm", "<Cmd>Mason<CR>", { desc = "  Mason (LSP/Tool installer)" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 13  TEXT OBJECTS (additional — no plugin required)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Select inside / around line (il / al)
  map(x, "il", "g_o^",       { desc = "Inside line" })
  map(o, "il", ":<C-u>normal! g_o^<CR>", { desc = "Inside line" })
  map(x, "al", "$o0",        { desc = "Around line" })
  map(o, "al", ":<C-u>normal! $o0<CR>",  { desc = "Around line" })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 14  COMMAND-LINE ERGONOMICS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  map(c, "<C-a>", "<Home>",   { desc = "Go to beginning of command" })
  map(c, "<C-e>", "<End>",    { desc = "Go to end of command" })
  map(c, "<C-b>", "<Left>",   { desc = "Move cursor left" })
  map(c, "<C-f>", "<Right>",  { desc = "Move cursor right" })
  map(c, "<C-d>", "<Del>",    { desc = "Delete char forward" })
  map(c, "<M-b>", "<S-Left>", { desc = "Move word left" })
  map(c, "<M-f>", "<S-Right>",{ desc = "Move word right" })