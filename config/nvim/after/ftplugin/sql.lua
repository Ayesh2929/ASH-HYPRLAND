-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🗄️  SQL FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   dadbod · sqlfluff · sql-formatter · query execution · schema browser        ║
-- ║   EXPLAIN · transaction helpers · dialect switching · jq pipe output          ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype   -- sql | mysql | plsql

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 0
opt.wrap         = false
opt.commentstring= "-- %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- SQL keyword completion
opt.iskeyword:append("-")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🗄️  SQL: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🗄️  " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Detect SQL dialect from buffer content / filetype
local function detect_dialect()
  if ft == "mysql" then return "mysql" end
  if ft == "plsql"  then return "oracle" end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, 5, false)
  for _, line in ipairs(lines) do
    if line:match("%-%-.*dialect:%s*(%w+)") then
      return line:match("%-%-.*dialect:%s*(%w+)")
    end
  end

  -- Check for PostgreSQL-specific syntax
  local content = table.concat(
    vim.api.nvim_buf_get_lines(buf, 0, 50, false), "\n"
  )
  if content:match("RETURNING") or content:match("SERIAL") or
     content:match(":: ") or content:match("ILIKE") then
    return "postgres"
  end
  if content:match("AUTO_INCREMENT") or content:match("ENGINE=") then
    return "mysql"
  end

  return "postgres"  -- sensible default
end

-- Get current query block (delimited by blank lines or ;)
local function get_query_at_cursor()
  local row     = vim.api.nvim_win_get_cursor(0)[1]
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local start_l = row
  local end_l   = row

  -- Walk backward to find start of statement
  while start_l > 1 do
    local prev = lines[start_l - 1] or ""
    if prev:match("^%s*$") or lines[start_l]:match("^%s*;") then break end
    start_l = start_l - 1
  end

  -- Walk forward to find end of statement (;)
  while end_l <= #lines do
    if lines[end_l]:match(";%s*$") or lines[end_l]:match("^%s*$") then break end
    end_l = end_l + 1
  end

  local query_lines = vim.list_slice(lines, start_l, end_l)
  return table.concat(query_lines, "\n")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Execution (via dadbod) ────────────────────────────────────────────────────
map("n", "<leader>sqe", function()
  -- Execute query under cursor via dadbod
  local ok, db = pcall(require, "vim-dadbod")
  if ok then
    vim.cmd("DB")
  else
    vim.cmd("DB")  -- triggers dadbod if installed
  end
end, "Execute (dadbod)")

map("n", "<leader>sqq", function()
  -- Execute current file
  local file = vim.api.nvim_buf_get_name(buf)
  vim.cmd("DB " .. vim.fn.shellescape(file))
end, "Execute file (dadbod)")

map("v", "<leader>sqe", function()
  vim.cmd("'<,'>DB")
end, "Execute selection (dadbod)")

map("n", "<leader>sqd", "<cmd>DBUIToggle<cr>",    "Toggle DBUI")
map("n", "<leader>sqa", "<cmd>DBUIAddConnection<cr>", "Add connection")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>sqf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    return
  end

  -- Fallback: sql-formatter
  if vim.fn.executable("sql-formatter") == 1 then
    local dialect = detect_dialect()
    local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    local result  = vim.fn.system(
      "echo " .. vim.fn.shellescape(content)
        .. " | sql-formatter --language " .. dialect .. " 2>&1"
    )
    if vim.v.shell_error == 0 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
      vim.notify("🗄️  Formatted (" .. dialect .. ")", vim.log.levels.INFO,
        { title = "SQL", timeout = 1000 })
    else
      vim.notify("🗄️  Format error:\n" .. result, vim.log.levels.ERROR,
        { title = "SQL" })
    end
  else
    vim.notify("🗄️  Install sql-formatter: npm i -g sql-formatter",
      vim.log.levels.WARN, { title = "SQL" })
  end
end, "Format")

-- ── Lint ─────────────────────────────────────────────────────────────────────
map("n", "<leader>sql", function()
  if vim.fn.executable("sqlfluff") ~= 1 then
    vim.notify("🗄️  sqlfluff not found", vim.log.levels.WARN, { title = "SQL" })
    return
  end

  local dialect = detect_dialect()
  local file    = vim.api.nvim_buf_get_name(buf)
  local result  = vim.fn.system(
    "sqlfluff lint --dialect=" .. dialect
      .. " --format=json " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  local ok, data = pcall(vim.fn.json_decode, result)
  if not ok or not data then
    vim.notify("🗄️  sqlfluff error:\n" .. result, vim.log.levels.ERROR,
      { title = "sqlfluff" })
    return
  end

  local qflist = {}
  for _, file_result in ipairs(data) do
    for _, violation in ipairs(file_result.violations or {}) do
      table.insert(qflist, {
        filename = file_result.filepath or file,
        lnum     = violation.start_line_no or 1,
        col      = violation.start_line_pos or 1,
        type     = "W",
        text     = string.format("[%s] %s", violation.code or "", violation.description or ""),
      })
    end
  end

  if #qflist > 0 then
    vim.fn.setqflist(qflist)
    vim.cmd("copen")
    vim.notify(string.format("🗄️  %d issue(s)", #qflist), vim.log.levels.WARN,
      { title = "sqlfluff" })
  else
    vim.notify("🗄️  ✅ No issues", vim.log.levels.INFO,
      { title = "sqlfluff", timeout = 1500 })
  end
end, "Lint (sqlfluff)")

-- ── EXPLAIN ───────────────────────────────────────────────────────────────────
map("n", "<leader>sqx", function()
  local row     = vim.api.nvim_win_get_cursor(0)[1]
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, row, false)
  local query   = get_query_at_cursor()

  if query:match("^%s*$") then
    vim.notify("🗄️  No query at cursor", vim.log.levels.WARN, { title = "SQL" })
    return
  end

  -- Prepend EXPLAIN ANALYZE
  local explain_query = "EXPLAIN ANALYZE\n" .. query
  -- Open in a new split buffer
  vim.cmd("new")
  local new_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false,
    vim.split(explain_query, "\n"))
  vim.bo[new_buf].filetype  = "sql"
  vim.bo[new_buf].buftype   = "nofile"
  vim.bo[new_buf].buflisted = false
  vim.api.nvim_buf_set_name(new_buf, "EXPLAIN_ANALYZE")
end, "Wrap in EXPLAIN ANALYZE")

-- ── Transaction helpers ───────────────────────────────────────────────────────
map("n", "<leader>sqtb", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false,
    { "BEGIN;", "" })
end, "Insert BEGIN")

map("n", "<leader>sqtc", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false,
    { "", "COMMIT;" })
end, "Insert COMMIT")

map("n", "<leader>sqtr", function()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false,
    { "", "ROLLBACK;" })
end, "Insert ROLLBACK")

-- ── CTE helper ────────────────────────────────────────────────────────────────
map("n", "<leader>sqc", function()
  vim.ui.input({ prompt = "🗄️  CTE name: " }, function(name)
    if not name or name == "" then return end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(buf, row, row, false, {
      "WITH " .. name .. " AS (",
      "  SELECT",
      "    *",
      "  FROM",
      "    ",
      ")",
      "SELECT",
      "  *",
      "FROM",
      "  " .. name .. ";",
    })
  end)
end, "Insert CTE skeleton")

-- ── Dialect info ─────────────────────────────────────────────────────────────
map("n", "<leader>sqi", function()
  local dialect = detect_dialect()
  vim.notify(
    table.concat({
      "🗄️  SQL Info",
      "──────────────────────────────────",
      string.format("  Filetype:     %s", ft),
      string.format("  Dialect:      %s", dialect),
      string.format("  dadbod:       %s",
        vim.fn.exists(":DB") == 2 and "✅" or "⭕"),
      string.format("  sql-formatter:%s",
        vim.fn.executable("sql-formatter") == 1 and "✅" or "⭕"),
      string.format("  sqlfluff:     %s",
        vim.fn.executable("sqlfluff") == 1 and "✅" or "⭕"),
      string.format("  psql:         %s",
        vim.fn.executable("psql") == 1 and "✅" or "⭕"),
      string.format("  mysql:        %s",
        vim.fn.executable("mysql") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "SQL" }
  )
end, "Info")

-- ── Navigate statements ───────────────────────────────────────────────────────
map("n", "]s", function()
  vim.fn.search("^\\s*\\(SELECT\\|INSERT\\|UPDATE\\|DELETE\\|CREATE\\|DROP\\|ALTER\\|WITH\\)",
    "W")
end, "Next SQL statement")

map("n", "[s", function()
  vim.fn.search("^\\s*\\(SELECT\\|INSERT\\|UPDATE\\|DELETE\\|CREATE\\|DROP\\|ALTER\\|WITH\\)",
    "Wb")
end, "Prev SQL statement")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtSql_" .. buf, { clear = true })

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

-- Wire dadbod completion
vim.api.nvim_create_autocmd("FileType", {
  group   = aug,
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
      cmp.setup.buffer({
        sources = cmp.config.sources({
          { name = "vim-dadbod-completion", priority = 1200 },
          { name = "buffer",                priority = 500  },
        }),
      })
    end
  end,
  once = true,
})