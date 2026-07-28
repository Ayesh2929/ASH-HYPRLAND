-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📄 JSON FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   Format · validate · minify · jq queries · sort keys · schema                 ║
-- ║   jsonc support · pretty-print · copy path · fold                              ║
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
opt.textwidth    = 0            -- no hard wrap in JSON
opt.wrap         = false
opt.conceallevel = 0            -- never conceal in JSON

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
    desc    = "📄 JSON: " .. desc,
  })
end

local function jq(args, notify_title)
  if vim.fn.executable("jq") ~= 1 then
    vim.notify("📄 jq not found", vim.log.levels.WARN, { title = "JSON" })
    return nil
  end

  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local result  = vim.fn.system(
    "echo " .. vim.fn.shellescape(content) .. " | jq " .. args .. " 2>&1"
  )

  if vim.v.shell_error ~= 0 then
    vim.notify("📄 jq error:\n" .. result, vim.log.levels.ERROR,
      { title = notify_title or "JSON" })
    return nil
  end

  return vim.fn.trim(result)
end

-- Get JSON path at cursor using jq path
local function get_json_path()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Use LSP if available
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.name == "jsonls" and client.server_capabilities.hoverProvider then
      -- fall through to treesitter approach
      break
    end
  end

  -- Build path from treesitter node ancestry
  local node = vim.treesitter.get_node({ buf = buf, pos = { row - 1, col } })
  local path = {}

  while node do
    local ntype = node:type()
    if ntype == "pair" then
      -- Get key
      local key_node = node:child(0)
      if key_node then
        local key = vim.treesitter.get_node_text(key_node, buf)
        key = key:gsub('^"', ""):gsub('"$', "")
        table.insert(path, 1, "." .. key)
      end
    elseif ntype == "array" then
      -- Find index
      local parent = node:parent()
      if parent and parent:type() == "pair" then
        -- will be handled by pair
      end
    end
    node = node:parent()
  end

  return table.concat(path)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>jf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  else
    vim.lsp.buf.format({ bufnr = buf, async = false })
  end
end, "Format")

-- ── Minify ────────────────────────────────────────────────────────────────────
map("n", "<leader>jm", function()
  local result = jq("-c '.'", "JSON Minify")
  if result then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { result })
    vim.notify("📄 JSON minified", vim.log.levels.INFO,
      { title = "JSON", timeout = 1000 })
  end
end, "Minify")

-- ── Validate ──────────────────────────────────────────────────────────────────
map("n", "<leader>jv", function()
  local result = jq("'.'", "JSON Validate")
  if result then
    vim.notify("📄 ✅ Valid JSON", vim.log.levels.INFO,
      { title = "JSON", timeout = 1500 })
  end
end, "Validate")

-- ── Sort keys ─────────────────────────────────────────────────────────────────
map("n", "<leader>js", function()
  local result = jq(
    "'. | walk(if type == \"object\" then to_entries | sort_by(.key) | from_entries else . end)'",
    "JSON Sort"
  )
  if result then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result, "\n"))
    vim.notify("📄 JSON keys sorted", vim.log.levels.INFO,
      { title = "JSON", timeout = 1200 })
  end
end, "Sort keys")

-- ── jq query ──────────────────────────────────────────────────────────────────
map("n", "<leader>jq", function()
  vim.ui.input({ prompt = "📄 jq query: " }, function(query)
    if not query or query == "" then return end
    local result = jq(vim.fn.shellescape(query), "jq query")
    if result then
      vim.notify("📄 Result:\n" .. result, vim.log.levels.INFO, { title = "jq" })
    end
  end)
end, "Run jq query")

-- ── jq query → buffer ─────────────────────────────────────────────────────────
map("n", "<leader>jQ", function()
  vim.ui.input({ prompt = "📄 jq query (→ buffer): " }, function(query)
    if not query or query == "" then return end
    local result = jq(vim.fn.shellescape(query), "jq")
    if result then
      -- Open in new split
      vim.cmd("new")
      local new_buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(result, "\n"))
      vim.bo[new_buf].filetype  = "json"
      vim.bo[new_buf].buftype   = "nofile"
      vim.bo[new_buf].buflisted = false
    end
  end)
end, "jq query → buffer")

-- ── Copy value at cursor ──────────────────────────────────────────────────────
map("n", "<leader>jy", function()
  local path   = get_json_path()
  if path == "" then
    -- Fallback: copy word under cursor
    local word = vim.fn.expand("<cWORD>")
    word = word:gsub('^"', ""):gsub('"$', ""):gsub(",$", "")
    vim.fn.setreg("+", word)
    vim.notify("📄 Copied: " .. word, vim.log.levels.INFO,
      { title = "JSON", timeout = 1000 })
    return
  end

  local result = jq(vim.fn.shellescape(path .. " // empty"), "copy")
  if result then
    vim.fn.setreg("+", result)
    vim.notify("📄 Copied: " .. result, vim.log.levels.INFO,
      { title = "JSON", timeout = 1000 })
  end
end, "Copy value at cursor")

-- ── Copy path at cursor ────────────────────────────────────────────────────────
map("n", "<leader>jp", function()
  local path = get_json_path()
  if path ~= "" then
    vim.fn.setreg("+", path)
    vim.notify("📄 Path: " .. path, vim.log.levels.INFO,
      { title = "JSON", timeout = 1200 })
  else
    vim.notify("📄 Could not determine path", vim.log.levels.WARN,
      { title = "JSON" })
  end
end, "Copy JSON path")

-- ── Fold all / unfold all ─────────────────────────────────────────────────────
map("n", "<leader>jM",  "zM", "Fold all")
map("n", "<leader>jR",  "zR", "Unfold all")

-- ── Schema info ───────────────────────────────────────────────────────────────
map("n", "<leader>ji", function()
  local file = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 2, false)
  local size  = vim.fn.getfsize(file)

  -- Try to detect schema
  local schema = "unknown"
  for _, line in ipairs(lines) do
    local s = line:match('"\\$schema"%s*:%s*"([^"]+)"')
    if s then schema = s break end
  end

  vim.notify(
    table.concat({
      "📄 JSON Info",
      "──────────────────────────────────",
      string.format("  File:   %s", vim.fn.fnamemodify(file, ":t")),
      string.format("  Size:   %s", size > 0 and math.floor(size/1024) .. " KB" or "new"),
      string.format("  Schema: %s", schema),
      string.format("  Lines:  %d", #vim.api.nvim_buf_get_lines(buf, 0, -1, false)),
      string.format("  jq:     %s", vim.fn.executable("jq") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "JSON" }
  )
end, "File info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtJson_" .. buf, { clear = true })

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