-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌐 HTML FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   Browser preview · emmet · HTMLHint · prettier · tag navigation              ║
-- ║   a11y helpers · template helpers · live-server · DOM snippet insertion       ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype  -- html | heex | htmldjango | handlebars

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 0
opt.wrap         = false
opt.commentstring= "<!-- %s -->"
opt.matchpairs:append("<:>")

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
    desc    = "🌐 HTML: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🌐 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

local function open_in_browser(file)
  local open_cmd = vim.fn.has("mac") == 1 and "open"
    or (vim.fn.executable("xdg-open") == 1 and "xdg-open" or "start")
  vim.fn.jobstart({ open_cmd, file }, { detach = true })
  vim.notify("🌐 Opened in browser", vim.log.levels.INFO,
    { title = "HTML", timeout = 1000 })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Preview ───────────────────────────────────────────────────────────────────
map("n", "<leader>ho", function()
  open_in_browser(vim.api.nvim_buf_get_name(buf))
end, "Open in browser")

map("n", "<leader>hl", function()
  -- Start live-server if available
  if vim.fn.executable("live-server") == 1 then
    run_cmd("live-server " .. vim.fn.shellescape(vim.fn.getcwd()), "live-server")
  elseif vim.fn.executable("python3") == 1 then
    run_cmd(
      "python3 -m http.server 8080 --directory " .. vim.fn.shellescape(vim.fn.getcwd()),
      "Python HTTP server :8080"
    )
  else
    vim.notify("🌐 Install live-server (npm i -g live-server)", vim.log.levels.WARN,
      { title = "HTML" })
  end
end, "Live server")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>hf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  else
    vim.lsp.buf.format({ bufnr = buf, async = false })
  end
end, "Format (prettier)")

-- ── Lint ─────────────────────────────────────────────────────────────────────
map("n", "<leader>hc", function()
  if vim.fn.executable("htmlhint") ~= 1 then
    vim.notify("🌐 htmlhint not found", vim.log.levels.WARN, { title = "HTML" })
    return
  end

  local file   = vim.api.nvim_buf_get_name(buf)
  local result = vim.fn.system("htmlhint " .. vim.fn.shellescape(file) .. " 2>&1")

  if vim.v.shell_error == 0 then
    vim.notify("🌐 ✅ HTMLHint: no issues", vim.log.levels.INFO,
      { title = "HTMLHint", timeout = 1500 })
  else
    local qflist = {}
    for line in result:gmatch("[^\n]+") do
      local lnum, col, msg = line:match("L(%d+)%|C(%d+)%s+:(.+)")
      if lnum then
        table.insert(qflist, {
          filename = file,
          lnum     = tonumber(lnum),
          col      = tonumber(col),
          type     = "W",
          text     = vim.fn.trim(msg),
        })
      end
    end
    if #qflist > 0 then
      vim.fn.setqflist(qflist)
      vim.cmd("copen")
      vim.notify(string.format("🌐 %d issue(s)", #qflist), vim.log.levels.WARN,
        { title = "HTMLHint" })
    else
      vim.notify("🌐 HTMLHint:\n" .. result, vim.log.levels.WARN,
        { title = "HTMLHint" })
    end
  end
end, "HTMLHint lint")

-- ── Tag navigation ────────────────────────────────────────────────────────────
map("n", "]t", function()
  vim.fn.search("<[a-zA-Z]", "W")
end, "Next tag")

map("n", "[t", function()
  vim.fn.search("<[a-zA-Z]", "Wb")
end, "Prev tag")

map("n", "]T", function()
  vim.fn.search("</[a-zA-Z]", "W")
end, "Next closing tag")

-- ── A11y helpers ──────────────────────────────────────────────────────────────
map("n", "<leader>haa", function()
  -- Add aria-label to element under cursor
  local row  = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""

  vim.ui.input({ prompt = "🌐 aria-label value: " }, function(label)
    if not label or label == "" then return end
    -- Insert aria-label before closing >
    local new_line = line:gsub(
      "([^/]>)",
      ' aria-label="' .. label .. '"\\1',
      1
    )
    vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
  end)
end, "Add aria-label")

map("n", "<leader>har", function()
  -- Add role attribute
  vim.ui.select(
    { "button", "link", "heading", "navigation", "main", "article",
      "section", "aside", "dialog", "alert", "status", "region", "list",
      "listitem", "tab", "tabpanel", "tablist", "tooltip", "img",
      "checkbox", "radio", "textbox", "combobox", "listbox", "menuitem" },
    { prompt = "🌐 ARIA role: " },
    function(role)
      if not role then return end
      local row  = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
      local new_line = line:gsub("([^/]>)", ' role="' .. role .. '"\\1', 1)
      vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
    end
  )
end, "Add role attribute")

-- ── Snippet helpers ───────────────────────────────────────────────────────────
map("n", "<leader>hs5", function()
  -- Insert HTML5 document skeleton
  local file = vim.api.nvim_buf_get_name(buf)
  local name = vim.fn.fnamemodify(file, ":t:r")

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local is_empty = #lines == 0 or (#lines == 1 and lines[1] == "")

  if not is_empty then
    vim.notify("🌐 Buffer not empty — insert at cursor", vim.log.levels.INFO,
      { title = "HTML" })
  end

  local skeleton = {
    "<!DOCTYPE html>",
    '<html lang="en" data-theme="dark">',
    "  <head>",
    '    <meta charset="UTF-8" />',
    '    <meta name="viewport" content="width=device-width, initial-scale=1.0" />',
    '    <meta name="description" content="" />',
    '    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />',
    "    <title>" .. name .. "</title>",
    '    <link rel="stylesheet" href="style.css" />',
    "  </head>",
    "  <body>",
    '    <header role="banner">',
    '      <nav aria-label="Main navigation">',
    "      </nav>",
    "    </header>",
    "",
    '    <main id="main" tabindex="-1">',
    "      <h1>" .. name .. "</h1>",
    "    </main>",
    "",
    '    <footer role="contentinfo">',
    "    </footer>",
    "",
    '    <script src="main.js" type="module"></script>',
    "  </body>",
    "</html>",
  }

  local insert_at = is_empty and 0 or vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, skeleton)
end, "Insert HTML5 skeleton")

map("n", "<leader>hsm", function()
  -- Insert meta tags block
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    '<!-- Open Graph -->',
    '<meta property="og:title"       content="" />',
    '<meta property="og:description" content="" />',
    '<meta property="og:image"       content="" />',
    '<meta property="og:url"         content="" />',
    '<meta property="og:type"        content="website" />',
    '',
    '<!-- Twitter Card -->',
    '<meta name="twitter:card"        content="summary_large_image" />',
    '<meta name="twitter:title"       content="" />',
    '<meta name="twitter:description" content="" />',
    '<meta name="twitter:image"       content="" />',
  })
end, "Insert meta tags")

map("n", "<leader>hss", function()
  -- Insert semantic article
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    '<article class="" aria-label="">',
    "  <header>",
    "    <h2></h2>",
    '    <time datetime=""></time>',
    "  </header>",
    "  <section>",
    "  </section>",
    "  <footer>",
    "    <address></address>",
    "  </footer>",
    "</article>",
  })
end, "Insert semantic article")

-- ── JSON-LD schema ────────────────────────────────────────────────────────────
map("n", "<leader>hsd", function()
  vim.ui.select(
    { "WebPage", "Article", "Product", "Organization", "Person", "BreadcrumbList", "FAQPage" },
    { prompt = "🌐 Schema.org type: " },
    function(schema_type)
      if not schema_type then return end
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(buf, row, row, false, {
        '<script type="application/ld+json">',
        "{",
        '  "@context": "https://schema.org",',
        '  "@type": "' .. schema_type .. '",',
        '  "name": ""',
        "}",
        "</script>",
      })
    end
  )
end, "Insert JSON-LD schema")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>hi", function()
  local file  = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Count elements
  local tags, attrs, links, imgs = 0, 0, 0, 0
  local has_doctype, has_lang, has_meta_desc, has_h1 = false, false, false, false

  for _, line in ipairs(lines) do
    if line:match("<!DOCTYPE", 1, true) then has_doctype = true end
    if line:match('lang=') then has_lang = true end
    if line:match('name="description"') then has_meta_desc = true end
    if line:match("<h1") then has_h1 = true end
    for _ in line:gmatch("<[a-zA-Z]") do tags = tags + 1 end
    for _ in line:gmatch('=["\'][^"\']*["\']') do attrs = attrs + 1 end
    for _ in line:gmatch('<a%s') do links = links + 1 end
    for _ in line:gmatch('<img%s') do imgs = imgs + 1 end
  end

  vim.notify(
    table.concat({
      "🌐 HTML Info",
      "──────────────────────────────────",
      string.format("  Filetype:   %s", ft),
      string.format("  Lines:      %d", #lines),
      string.format("  Tags:       ~%d", tags),
      string.format("  Links:      %d", links),
      string.format("  Images:     %d", imgs),
      "",
      "  A11y checks:",
      string.format("    DOCTYPE:  %s", has_doctype and "✅" or "⚠️ missing"),
      string.format("    lang:     %s", has_lang and "✅" or "⚠️ missing"),
      string.format("    meta desc:%s", has_meta_desc and "✅" or "⚠️ missing"),
      string.format("    <h1>:     %s", has_h1 and "✅" or "⚠️ missing"),
      "",
      string.format("  htmlhint:   %s", vim.fn.executable("htmlhint") == 1 and "✅" or "⭕"),
      string.format("  prettier:   %s", vim.fn.executable("prettier") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "HTML" }
  )
end, "File info + a11y")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtHtml_" .. buf, { clear = true })

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