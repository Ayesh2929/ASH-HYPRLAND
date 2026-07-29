-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐍 PYTHON FTPLUGIN — ASH v5.0 OMEGA                                      ║
-- ║   PEP 8 settings · venv · REPL · pytest · docstrings · type checking           ║
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
opt.colorcolumn  = "101,89"   -- PEP 8 soft (89) and hard (101)
opt.commentstring= "# %s"
opt.smartindent  = true
opt.cinwords     = ""         -- disable C-indent for Python
opt.define       = [[^\s*\%(def\|class\)]]
opt.include      = [[^\s*\%(from\|import\)\s]]
opt.includeexpr  = "substitute(v:fname,'\\.','/','g')"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🐍 Python: " .. desc,
  })
end

local function python_exe()
  for _, v in ipairs({
    os.getenv("VIRTUAL_ENV"),
    os.getenv("CONDA_PREFIX"),
    vim.fn.getcwd() .. "/.venv",
    vim.fn.getcwd() .. "/venv",
  }) do
    if v and v ~= "" then
      local p = v .. "/bin/python"
      if vim.fn.executable(p) == 1 then return p end
    end
  end
  return vim.fn.exepath("python3") or "python3"
end

local function run_in_terminal(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🐍 " .. title,
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
map("n", "<leader>pr", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_in_terminal(python_exe() .. " " .. vim.fn.shellescape(file), "Run")
end, "Run file")

map("n", "<leader>pi", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_in_terminal(python_exe() .. " -i " .. vim.fn.shellescape(file), "Run (interactive)")
end, "Run interactive")

-- ── Test ──────────────────────────────────────────────────────────────────────
map("n", "<leader>pt", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_in_terminal(
    python_exe() .. " -m pytest " .. vim.fn.shellescape(file) .. " -v --no-header -rN",
    "pytest file"
  )
end, "pytest current file")

map("n", "<leader>pT", function()
  run_in_terminal(
    python_exe() .. " -m pytest -v --no-header -rN",
    "pytest all"
  )
end, "pytest all")

map("n", "<leader>pf", function()
  -- pytest: run test function under cursor
  local fn_name = nil
  local node = vim.treesitter.get_node()
  while node do
    if node:type() == "function_definition" then
      for child in node:iter_children() do
        if child:type() == "identifier" then
          fn_name = vim.treesitter.get_node_text(child, buf)
          break
        end
      end
      break
    end
    node = node:parent()
  end

  if fn_name then
    local file = vim.api.nvim_buf_get_name(buf)
    run_in_terminal(
      python_exe() .. " -m pytest " .. vim.fn.shellescape(file)
        .. "::" .. fn_name .. " -v --no-header",
      "pytest: " .. fn_name
    )
  else
    vim.notify("🐍 No test function at cursor", vim.log.levels.WARN, { title = "Python" })
  end
end, "pytest function at cursor")

-- ── REPL ─────────────────────────────────────────────────────────────────────
map("n", "<leader>pp", function()
  local py = python_exe()
  local repl = vim.fn.executable("ipython") == 1
    and vim.fn.fnamemodify(py, ":h") .. "/ipython" or py
  run_in_terminal(repl, "REPL")
end, "Open REPL")

map("v", "<leader>ps", function()
  -- Send visual selection to REPL terminal
  local s     = vim.api.nvim_buf_get_mark(buf, "<")
  local e     = vim.api.nvim_buf_get_mark(buf, ">")
  local lines = vim.api.nvim_buf_get_lines(buf, s[1] - 1, e[1], false)
  local code  = table.concat(lines, "\n")

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(win)
    if vim.bo[b].buftype == "terminal" then
      local ok, chan = pcall(vim.api.nvim_buf_get_var, b, "terminal_job_id")
      if ok and chan then
        vim.api.nvim_chan_send(chan, code .. "\n")
        vim.notify("🐍 Sent to REPL", vim.log.levels.INFO,
          { title = "Python", timeout = 800 })
        return
      end
    end
  end
  vim.notify("🐍 No active REPL found", vim.log.levels.WARN, { title = "Python" })
end, "Send selection to REPL")

-- ── Type checking ─────────────────────────────────────────────────────────────
map("n", "<leader>pm", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_in_terminal(
    python_exe() .. " -m mypy " .. vim.fn.shellescape(file)
      .. " --ignore-missing-imports --show-error-codes",
    "mypy"
  )
end, "mypy type check")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>pF", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  end
end, "Format")

-- ── Docstring ─────────────────────────────────────────────────────────────────
map("n", "<leader>pd", function()
  -- Insert Google-style docstring below cursor
  local row     = vim.api.nvim_win_get_cursor(0)[1]
  local line    = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local indent  = line:match("^(%s*)") or ""
  local in4     = indent .. "    "

  local ds = {
    indent .. '"""' .. 'Summary line.',
    "",
    in4 .. "Args:",
    in4 .. "    param: description",
    "",
    in4 .. "Returns:",
    in4 .. "    description",
    "",
    in4 .. "Raises:",
    in4 .. "    ValueError: When invalid.",
    indent .. '"""',
  }

  vim.api.nvim_buf_set_lines(buf, row, row, false, ds)
  vim.api.nvim_win_set_cursor(0, { row + 1, #indent })
end, "Insert docstring")

-- ── Venv info ─────────────────────────────────────────────────────────────────
map("n", "<leader>pv", function()
  local py  = python_exe()
  local ver = vim.fn.trim(vim.fn.system(py .. " --version 2>&1"))
  local venv= os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX") or "(none)"
  vim.notify(
    table.concat({
      "🐍 Python Environment",
      "──────────────────────────────────",
      string.format("  Python:  %s", py),
      string.format("  Version: %s", ver),
      string.format("  Venv:    %s", venv),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Python" }
  )
end, "Venv info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtPython_" .. buf, { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    end
  end,
})

-- Auto-detect and set PYTHONPATH
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  group  = aug,
  buffer = buf,
  once   = true,
  callback = function()
    local cwd = vim.fn.getcwd()
    local src = cwd .. "/src"
    if vim.fn.isdirectory(src) == 1 then
      vim.env.PYTHONPATH = src .. ":" .. (vim.env.PYTHONPATH or "")
    end
  end,
})