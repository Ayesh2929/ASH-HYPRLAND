-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📝 MARKDOWN FTPLUGIN — ASH v5.0 OMEGA                                    ║
-- ║   Writing mode · prose wrap · TOC · preview · tables · tasks · links           ║
-- ║   render-markdown · checkboxes · math · frontmatter · spell check              ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS (prose-optimised)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 80
opt.wrap         = true
opt.linebreak    = true         -- break at word boundaries
opt.breakindent  = true         -- indent wrapped lines
opt.spell        = true
opt.spelllang    = "en_us"
opt.conceallevel = 2            -- conceal markup
opt.concealcursor= "nc"
opt.commentstring= "<!-- %s -->"

-- Prose folding (manual so user controls it)
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- Visual line navigation feels natural in prose
vim.keymap.set("n", "j", "gj", { buffer = buf, silent = true })
vim.keymap.set("n", "k", "gk", { buffer = buf, silent = true })

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "📝 Markdown: " .. desc,
  })
end

-- Generate / update Table of Contents
local function generate_toc()
  local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local toc    = { "<!-- toc -->", "" }
  local in_code = false

  for _, line in ipairs(lines) do
    if line:match("^```") then in_code = not in_code end
    if not in_code then
      local level, title = line:match("^(#+)%s+(.+)$")
      if level and title then
        local depth  = #level - 1
        local anchor = title:lower()
          :gsub("[^%w%s%-]", "")
          :gsub("%s+", "-")
          :gsub("^%-+", "")
          :gsub("%-+$", "")
        table.insert(toc, string.format(
          "%s- [%s](#%s)",
          string.rep("  ", depth),
          title,
          anchor
        ))
      end
    end
  end

  table.insert(toc, "")
  table.insert(toc, "<!-- tocstop -->")

  -- Find existing markers
  local ts, te
  for i, line in ipairs(lines) do
    if line:match("<!-- toc -->")     then ts = i end
    if line:match("<!-- tocstop -->") then te = i end
  end

  if ts and te then
    vim.api.nvim_buf_set_lines(buf, ts - 1, te, false, toc)
    vim.notify("📝 TOC updated", vim.log.levels.INFO,
      { title = "Markdown", timeout = 1200 })
  else
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(buf, row, row, false, toc)
    vim.notify("📝 TOC inserted", vim.log.levels.INFO,
      { title = "Markdown", timeout = 1200 })
  end
end

-- Word count
local function word_count()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text  = table.concat(lines, " ")
  -- Strip code blocks, front-matter, links
  text = text:gsub("```.-```", "")
             :gsub("`[^`]+`", "")
             :gsub("%[.-%]%(.-%)","")
             :gsub("^---.+---", "")
  local words = 0
  for _ in text:gmatch("%S+") do words = words + 1 end
  local read_time = math.ceil(words / 200)  -- ~200 wpm

  vim.notify(
    string.format(
      "📝 Words: %d  •  ~%d min read  •  Lines: %d",
      words, read_time, #lines
    ),
    vim.log.levels.INFO,
    { title = "Markdown Stats" }
  )
end

-- Toggle checkbox on current line
local function toggle_checkbox()
  local row  = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

  local new_line
  if line:match("^%s*%- %[x%]") then
    new_line = line:gsub("%- %[x%]", "- [ ]", 1)
  elseif line:match("^%s*%- %[ %]") then
    new_line = line:gsub("%- %[ %]", "- [x]", 1)
  elseif line:match("^%s*%-%s") then
    new_line = line:gsub("^(%s*)%- ", "%1- [ ] ", 1)
  else
    new_line = line
  end

  vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
end

-- Insert a Markdown table
local function insert_table()
  vim.ui.input({ prompt = "📝 Columns (default 3): ", default = "3" }, function(cols_str)
    local cols = tonumber(cols_str) or 3
    vim.ui.input({ prompt = "📝 Rows (default 3): ",    default = "3" }, function(rows_str)
      local rows = tonumber(rows_str) or 3
      local row  = vim.api.nvim_win_get_cursor(0)[1]

      local lines = {}
      -- Header row
      local header = "| " .. table.concat(
        vim.tbl_map(function(i) return "Column " .. i end,
          vim.fn.range(1, cols)),
        " | "
      ) .. " |"
      table.insert(lines, header)

      -- Separator
      local sep = "|" .. string.rep(" :------: |", cols)
      table.insert(lines, sep)

      -- Data rows
      for _ = 1, rows do
        local data_row = "| " .. table.concat(
          vim.tbl_map(function(_) return "         " end, vim.fn.range(1, cols)),
          " | "
        ) .. " |"
        table.insert(lines, data_row)
      end

      table.insert(lines, "")
      vim.api.nvim_buf_set_lines(buf, row, row, false, lines)
      vim.api.nvim_win_set_cursor(0, { row + 1, 2 })
    end)
  end)
end

-- Insert frontmatter
local function insert_frontmatter()
  local row   = vim.api.nvim_win_get_cursor(0)[1]
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""

  if first:match("^---") then
    vim.notify("📝 Frontmatter already exists", vim.log.levels.INFO,
      { title = "Markdown" })
    return
  end

  local fm = {
    "---",
    'title:       "' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t:r") .. '"',
    'description: ""',
    "date:        " .. os.date("%Y-%m-%d"),
    "tags:        []",
    "draft:       false",
    "---",
    "",
  }

  vim.api.nvim_buf_set_lines(buf, 0, 0, false, fm)
  vim.api.nvim_win_set_cursor(0, { 2, 9 })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Preview ───────────────────────────────────────────────────────────────────
map("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>",      "Preview (browser)")
map("n", "<leader>mP", "<cmd>MarkdownPreview<cr>",            "Preview open")
map("n", "<leader>mX", "<cmd>MarkdownPreviewStop<cr>",        "Preview stop")
map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>",      "Render toggle")

-- ── Structure ─────────────────────────────────────────────────────────────────
map("n", "<leader>mt", generate_toc,                          "Generate TOC")
map("n", "<leader>mF", insert_frontmatter,                    "Insert frontmatter")
map("n", "<leader>mT", insert_table,                          "Insert table")

-- ── Checkbox ─────────────────────────────────────────────────────────────────
map("n", "<leader>mx", toggle_checkbox,                       "Toggle checkbox")
map("n", "<C-Space>",  toggle_checkbox,                       "Toggle checkbox")

-- ── Stats / Info ──────────────────────────────────────────────────────────────
map("n", "<leader>ms", word_count,                            "Word count")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>mf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  end
end, "Format")

-- ── Heading helpers ───────────────────────────────────────────────────────────
for i = 1, 6 do
  map("n", "<leader>m" .. i, function()
    local row  = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
    -- Strip existing heading markers
    local text = line:match("^#+%s+(.+)$") or line:match("^(.+)$") or ""
    local new_line = string.rep("#", i) .. " " .. text
    vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
  end, "Heading H" .. i)
end

-- ── Insert inline elements ────────────────────────────────────────────────────
map("n", "<leader>ml", function()
  vim.ui.input({ prompt = "📝 Link URL: " }, function(url)
    if not url or url == "" then return end
    local text = vim.fn.expand("<cword>")
    local link  = "[" .. text .. "](" .. url .. ")"
    -- Replace word under cursor with link
    vim.cmd("normal! ciw" .. link)
  end)
end, "Insert link")

map("v", "<leader>ml", function()
  vim.ui.input({ prompt = "📝 Link URL: " }, function(url)
    if not url or url == "" then return end
    -- Wrap selection in link
    local s    = vim.api.nvim_buf_get_mark(buf, "<")
    local e    = vim.api.nvim_buf_get_mark(buf, ">")
    local text = vim.api.nvim_buf_get_lines(buf, s[1]-1, e[1], false)
    local sel  = table.concat(text, " "):sub(s[2]+1, e[2]+1)
    vim.cmd("normal! c[" .. sel .. "](" .. url .. ")")
  end)
end, "Wrap selection as link")

-- ── Bold / Italic / Code ──────────────────────────────────────────────────────
map("v", "<leader>mb", [[:s/\%V.*\%V./**&**/e<CR>]],         "Bold selection")
map("v", "<leader>mi", [[:s/\%V.*\%V./_&_/e<CR>]],           "Italic selection")
map("v", "<leader>mc", [[:s/\%V.*\%V./`&`/e<CR>]],           "Inline code")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtMarkdown_" .. buf, { clear = true })

-- Format on save
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

-- Update word count in statusline variable
vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
  group  = aug,
  buffer = buf,
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local text  = table.concat(lines, " ")
    local words = 0
    for _ in text:gmatch("%S+") do words = words + 1 end
    vim.b[buf].markdown_word_count = words
  end,
})