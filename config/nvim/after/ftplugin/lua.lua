-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌙 LUA FTPLUGIN — ASH v5.0 OMEGA                                         ║
-- ║   Editor settings · keymaps · eval · module reload · Neovim API helpers        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "-- %s"
opt.conceallevel = 0

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- Complete from buffer + tags
opt.complete:append("kspell")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🌙 Lua: " .. desc,
  })
end

-- ── Execute / Source ──────────────────────────────────────────────────────────
map("n", "<leader>lx", "<cmd>source %<cr>",
    "Source file")

map("n", "<leader>le", function()
  -- Eval entire buffer
  local code = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local fn, err = load(code, "=(eval)")
  if not fn then
    vim.notify("🌙 Eval error:\n" .. tostring(err), vim.log.levels.ERROR,
      { title = "Lua Eval" })
    return
  end
  local ok, result = xpcall(fn, function(e) return debug.traceback(e, 2) end)
  if not ok then
    vim.notify("🌙 Runtime error:\n" .. tostring(result), vim.log.levels.ERROR,
      { title = "Lua Eval" })
  else
    local out = result ~= nil and vim.inspect(result) or "nil"
    vim.notify("🌙 → " .. out, vim.log.levels.INFO, { title = "Lua Eval" })
  end
end, "Eval buffer")

map("v", "<leader>le", function()
  -- Eval visual selection
  local s = vim.api.nvim_buf_get_mark(buf, "<")
  local e = vim.api.nvim_buf_get_mark(buf, ">")
  local lines = vim.api.nvim_buf_get_lines(buf, s[1] - 1, e[1], false)
  local code  = table.concat(lines, "\n")
  local fn, err = load(code, "=(eval-selection)")
  if not fn then
    vim.notify("🌙 Eval error:\n" .. tostring(err), vim.log.levels.ERROR,
      { title = "Lua Eval" })
    return
  end
  local ok, result = xpcall(fn, function(er) return debug.traceback(er, 2) end)
  if not ok then
    vim.notify("🌙 Runtime error:\n" .. tostring(result), vim.log.levels.ERROR,
      { title = "Lua Eval" })
  else
    local out = result ~= nil and vim.inspect(result) or "nil"
    vim.notify("🌙 → " .. out, vim.log.levels.INFO, { title = "Lua Eval" })
  end
end, "Eval selection")

-- ── Module reload ─────────────────────────────────────────────────────────────
map("n", "<leader>lX", function()
  local file = vim.api.nvim_buf_get_name(buf)
  local cfg  = vim.fn.stdpath("config")
  local rel  = file:match(vim.pesc(cfg .. "/lua/") .. "(.+)%.lua$")

  if not rel then
    vim.notify("🌙 Not inside config/lua/", vim.log.levels.WARN,
      { title = "Lua Reload" })
    return
  end

  local mod_name = rel:gsub("/", ".")
  package.loaded[mod_name] = nil

  local ok, err = pcall(require, mod_name)
  if ok then
    vim.notify("🌙 Reloaded: " .. mod_name, vim.log.levels.INFO,
      { title = "Lua Reload", timeout = 1500 })
  else
    vim.notify("🌙 Error:\n" .. tostring(err), vim.log.levels.ERROR,
      { title = "Lua Reload" })
  end
end, "Reload module")

-- ── Lazy ─────────────────────────────────────────────────────────────────────
map("n", "<leader>ll", "<cmd>Lazy<cr>",              "Open Lazy")
map("n", "<leader>lL", "<cmd>Lazy sync<cr>",         "Lazy sync")
map("n", "<leader>lu", "<cmd>Lazy update<cr>",        "Lazy update")

-- ── Inspect under cursor ─────────────────────────────────────────────────────
map("n", "<leader>li", function()
  local word = vim.fn.expand("<cWORD>")
  local ok, val = pcall(load("return " .. word))
  if ok and val ~= nil then
    vim.notify(vim.inspect(val), vim.log.levels.INFO, { title = word })
  else
    -- Fallback to :lua print
    vim.cmd("lua print(vim.inspect(" .. word .. "))")
  end
end, "Inspect word")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS (buffer-local)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtLua_" .. buf, { clear = true })

-- Format on save via stylua / conform
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = buf, async = false, timeout_ms = 3000 })
    end
  end,
})

-- Refresh treesitter on write (ensures highlights stay correct after edits)
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  callback = function()
    pcall(vim.treesitter.stop, buf)
    pcall(vim.treesitter.start, buf)
  end,
})