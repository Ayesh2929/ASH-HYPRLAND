-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐠 FISH FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   fish_indent · syntax check · function navigation · abbr/alias helpers       ║
-- ║   completions scaffold · REPL · config reload · ASH fish integration           ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 4
opt.tabstop      = 4
opt.softtabstop  = 4
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "# %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- Fish-specific path for definitions
opt.define  = [[^\s*function\s]]
opt.include = [[^\s*source\s]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🐠 Fish: " .. desc,
  })
end

local function fish_exe()
  return vim.fn.exepath("fish") or "fish"
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🐠 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Run ──────────────────────────────────────────────────────────────────────
map("n", "<leader>fr", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_cmd(fish_exe() .. " " .. vim.fn.shellescape(file), "run")
end, "Run file")

map("n", "<leader>fn", function()
  run_cmd(fish_exe(), "REPL")
end, "Open fish REPL")

-- ── Syntax check ─────────────────────────────────────────────────────────────
map("n", "<leader>fc", function()
  local file   = vim.api.nvim_buf_get_name(buf)
  local result = vim.fn.system(
    fish_exe() .. " --no-execute " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  if vim.v.shell_error == 0 then
    vim.notify("🐠 ✅ Syntax OK", vim.log.levels.INFO,
      { title = "Fish", timeout = 1500 })
  else
    -- Parse errors into quickfix
    local qflist = {}
    for line in result:gmatch("[^\n]+") do
      local lnum, msg = line:match("%(line (%d+)%): (.+)")
      if lnum then
        table.insert(qflist, {
          filename = file,
          lnum     = tonumber(lnum),
          type     = "E",
          text     = msg,
        })
      end
    end
    if #qflist > 0 then
      vim.fn.setqflist(qflist)
      vim.cmd("copen")
      vim.notify(string.format("🐠 %d syntax error(s)", #qflist),
        vim.log.levels.ERROR, { title = "Fish" })
    else
      vim.notify("🐠 Syntax error:\n" .. result, vim.log.levels.ERROR,
        { title = "Fish" })
    end
  end
end, "Check syntax")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>ff", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("fish_indent") == 1 then
    vim.fn.system("fish_indent -w " .. vim.fn.shellescape(file))
    vim.cmd("checktime")
    vim.notify("🐠 Formatted with fish_indent", vim.log.levels.INFO,
      { title = "Fish", timeout = 1000 })
  else
    vim.notify("🐠 fish_indent not found", vim.log.levels.WARN, { title = "Fish" })
  end
end, "Format (fish_indent)")

-- ── Source / reload ───────────────────────────────────────────────────────────
map("n", "<leader>fs", function()
  local file = vim.api.nvim_buf_get_name(buf)
  -- Source in active fish shell (best effort via fish socket)
  local result = vim.fn.system(
    "fish -c 'source " .. vim.fn.shellescape(file) .. "' 2>&1"
  )
  if vim.v.shell_error == 0 then
    vim.notify("🐠 Sourced: " .. vim.fn.fnamemodify(file, ":t"),
      vim.log.levels.INFO, { title = "Fish", timeout = 1200 })
  else
    vim.notify("🐠 Source error:\n" .. result, vim.log.levels.WARN,
      { title = "Fish" })
  end
end, "Source file")

map("n", "<leader>fR", function()
  -- Reload fish config
  vim.fn.system("fish -c 'source ~/.config/fish/config.fish' 2>&1")
  vim.notify("🐠 Fish config reloaded", vim.log.levels.INFO,
    { title = "Fish", timeout = 1200 })
end, "Reload fish config")

-- ── Completions scaffold ──────────────────────────────────────────────────────
map("n", "<leader>fco", function()
  local file = vim.api.nvim_buf_get_name(buf)
  -- Guess command name from filename or function definitions
  local fn_name = vim.fn.fnamemodify(file, ":t:r")

  -- Try to find first function name in buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, line in ipairs(lines) do
    local fname = line:match("^function%s+([%w_%-]+)")
    if fname then fn_name = fname break end
  end

  local comp_dir = vim.fn.expand("~/.config/fish/completions")
  if vim.fn.isdirectory(comp_dir) == 0 then
    vim.fn.mkdir(comp_dir, "p")
  end

  local comp_file = comp_dir .. "/" .. fn_name .. ".fish"

  if vim.fn.filereadable(comp_file) == 0 then
    local template = {
      "# Completions for " .. fn_name,
      "# Place in ~/.config/fish/completions/" .. fn_name .. ".fish",
      "",
      "# Disable file completions for this command",
      "complete -c " .. fn_name .. " -f",
      "",
      "# Subcommands",
      "complete -c " .. fn_name .. " -n '__fish_use_subcommand' \\",
      "    -a 'help' -d 'Show help'",
      "",
      "# Global flags",
      "complete -c " .. fn_name .. " -s h -l help    -d 'Show help'",
      "complete -c " .. fn_name .. " -s v -l verbose -d 'Verbose output'",
    }
    local f = io.open(comp_file, "w")
    if f then
      f:write(table.concat(template, "\n"))
      f:close()
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(comp_file))
  vim.notify("🐠 Completions: " .. comp_file, vim.log.levels.INFO,
    { title = "Fish" })
end, "Open/create completions")

-- ── Navigate functions ────────────────────────────────────────────────────────
map("n", "]f", function()
  vim.fn.search("^function\\s", "W")
end, "Next function")

map("n", "[f", function()
  vim.fn.search("^function\\s", "Wb")
end, "Prev function")

-- ── ASH integration ───────────────────────────────────────────────────────────
map("n", "<leader>faf", function()
  -- Open ASH fish functions directory
  local ash_fn_dir = vim.fn.expand("~/.config/fish/functions")
  if vim.fn.isdirectory(ash_fn_dir) == 1 then
    local ok, tele = pcall(require, "telescope.builtin")
    if ok then
      tele.find_files({
        prompt_title = "🐠 Fish Functions",
        cwd          = ash_fn_dir,
      })
    else
      vim.cmd("edit " .. ash_fn_dir)
    end
  end
end, "Browse fish functions")

map("n", "<leader>fac", function()
  -- Open ASH fish conf.d directory
  local conf_d = vim.fn.expand("~/.config/fish/conf.d")
  if vim.fn.isdirectory(conf_d) == 1 then
    local ok, tele = pcall(require, "telescope.builtin")
    if ok then
      tele.find_files({
        prompt_title = "🐠 Fish conf.d",
        cwd          = conf_d,
      })
    end
  end
end, "Browse fish conf.d")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>fi", function()
  local fish_ver = vim.fn.trim(vim.fn.system("fish --version 2>/dev/null"))
  local fish_path = vim.fn.exepath("fish") or "not found"
  local fn_dir    = vim.fn.expand("~/.config/fish/functions")
  local fn_count  = #vim.fn.glob(fn_dir .. "/*.fish", false, true)
  local conf_count= #vim.fn.glob(
    vim.fn.expand("~/.config/fish/conf.d") .. "/*.fish", false, true
  )

  vim.notify(
    table.concat({
      "🐠 Fish Shell Info",
      "──────────────────────────────────",
      string.format("  Version:    %s", fish_ver),
      string.format("  Path:       %s", fish_path),
      string.format("  Functions:  %d", fn_count),
      string.format("  conf.d:     %d", conf_count),
      string.format("  fish_indent:%s", vim.fn.executable("fish_indent") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Fish" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtFish_" .. buf, { clear = true })

-- Format on save via fish_indent
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    if vim.fn.executable("fish_indent") ~= 1 then return end
    local file    = vim.api.nvim_buf_get_name(buf)
    local view    = vim.fn.winsaveview()
    vim.fn.system("fish_indent -w " .. vim.fn.shellescape(file))
    vim.cmd("checktime")
    vim.fn.winrestview(view)
  end,
})

-- Syntax check on write
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  callback = function()
    local file   = vim.api.nvim_buf_get_name(buf)
    local result = vim.fn.system(
      fish_exe() .. " --no-execute " .. vim.fn.shellescape(file) .. " 2>&1"
    )
    if vim.v.shell_error ~= 0 and vim.g.ash_debug then
      vim.notify("🐠 Syntax warning:\n" .. result, vim.log.levels.WARN,
        { title = "Fish" })
    end
  end,
})