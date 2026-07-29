-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎨 CSS FTPLUGIN — ASH v5.0 OMEGA                                         ║
-- ║   SCSS · Less · PostCSS · stylelint · prettier · colour picker                ║
-- ║   property helpers · media query navigation · selector stats                  ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype  -- css | scss | less | sass

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 0
opt.wrap         = false
opt.commentstring= (ft == "scss" or ft == "less") and "// %s" or "/* %s */"

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
    desc    = "🎨 CSS: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🎨 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Extract hex colours from buffer
local function find_colours()
  local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local colours = {}
  local seen    = {}

  for lnum, line in ipairs(lines) do
    -- #RGB, #RRGGBB, #RGBA, #RRGGBBAA
    for hex in line:gmatch("#[0-9a-fA-F][0-9a-fA-F]?[0-9a-fA-F]?[0-9a-fA-F]?[0-9a-fA-F]?[0-9a-fA-F]?[0-9a-fA-F]?[0-9a-fA-F]?") do
      if not seen[hex:lower()] then
        seen[hex:lower()] = true
        table.insert(colours, { line = lnum, hex = hex })
      end
    end
    -- rgb() / rgba()
    for rgb in line:gmatch("rgba?%([^%)]+%)") do
      if not seen[rgb] then
        seen[rgb] = true
        table.insert(colours, { line = lnum, hex = rgb })
      end
    end
    -- CSS variables
    for var in line:gmatch("%-%-[%w%-]+") do
      if not seen[var] then
        seen[var] = true
        table.insert(colours, { line = lnum, hex = var })
      end
    end
  end

  return colours
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>cf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  else
    vim.lsp.buf.format({ bufnr = buf, async = false })
  end
end, "Format (prettier)")

-- ── Lint ─────────────────────────────────────────────────────────────────────
map("n", "<leader>cl", function()
  if vim.fn.executable("stylelint") ~= 1 then
    vim.notify("🎨 stylelint not found", vim.log.levels.WARN, { title = "CSS" })
    return
  end

  local file   = vim.api.nvim_buf_get_name(buf)
  local result = vim.fn.system(
    "stylelint --formatter=json " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  local qflist = {}
  local ok, data = pcall(vim.fn.json_decode, result)

  if ok and type(data) == "table" then
    for _, entry in ipairs(data) do
      for _, warning in ipairs(entry.warnings or {}) do
        table.insert(qflist, {
          filename = entry.source or file,
          lnum     = warning.line or 1,
          col      = warning.column or 1,
          type     = warning.severity == "error" and "E" or "W",
          text     = string.format("[%s] %s", warning.rule or "", warning.text or ""),
        })
      end
    end
  end

  if #qflist > 0 then
    vim.fn.setqflist(qflist)
    vim.cmd("copen")
    vim.notify(string.format("🎨 %d issue(s)", #qflist), vim.log.levels.WARN,
      { title = "stylelint" })
  else
    if vim.v.shell_error == 0 then
      vim.notify("🎨 ✅ No stylelint issues", vim.log.levels.INFO,
        { title = "stylelint", timeout = 1500 })
    else
      vim.notify("🎨 stylelint error:\n" .. result, vim.log.levels.ERROR,
        { title = "stylelint" })
    end
  end
end, "Lint (stylelint)")

-- ── Colours ───────────────────────────────────────────────────────────────────
map("n", "<leader>cc", function()
  local colours = find_colours()
  if #colours == 0 then
    vim.notify("🎨 No colours found", vim.log.levels.INFO, { title = "CSS" })
    return
  end

  local items = vim.tbl_map(function(c)
    return string.format("[L%d] %s", c.line, c.hex)
  end, colours)

  vim.ui.select(items, { prompt = "🎨 Colours in file: " }, function(_, idx)
    if idx then
      local colour = colours[idx]
      vim.api.nvim_win_set_cursor(0, { colour.line, 0 })
      vim.fn.setreg("+", colour.hex)
      vim.notify("🎨 Copied: " .. colour.hex, vim.log.levels.INFO,
        { title = "CSS", timeout = 1000 })
    end
  end)
end, "List colours")

map("n", "<leader>ccp", function()
  -- Pick colour under cursor
  if vim.fn.executable("hyprpicker") == 1 then
    local result = vim.fn.trim(vim.fn.system("hyprpicker -a 2>/dev/null"))
    if result ~= "" then
      -- Insert at cursor
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
      vim.api.nvim_buf_set_lines(buf, row - 1, row, false,
        { line .. result })
    end
  elseif vim.fn.executable("color-picker") == 1 then
    local result = vim.fn.trim(vim.fn.system("color-picker 2>/dev/null"))
    if result ~= "" then
      vim.fn.setreg("+", result)
      vim.notify("🎨 Picked: " .. result, vim.log.levels.INFO,
        { title = "CSS", timeout = 1000 })
    end
  else
    vim.notify("🎨 Install hyprpicker or color-picker", vim.log.levels.WARN,
      { title = "CSS" })
  end
end, "Pick colour (hyprpicker)")

-- ── Navigate ─────────────────────────────────────────────────────────────────
map("n", "]m", function()
  vim.fn.search("@media", "W")
end, "Next @media query")

map("n", "[m", function()
  vim.fn.search("@media", "Wb")
end, "Prev @media query")

map("n", "]r", function()
  vim.fn.search(":root\\s*{", "W")
end, "Next :root")

map("n", "]v", function()
  vim.fn.search("--[a-zA-Z]", "W")
end, "Next CSS variable")

map("n", "[v", function()
  vim.fn.search("--[a-zA-Z]", "Wb")
end, "Prev CSS variable")

-- ── Snippets ──────────────────────────────────────────────────────────────────
map("n", "<leader>csr", function()
  -- Insert :root with common variables
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    ":root {",
    "  /* ── Colour palette ─────────────────── */",
    "  --clr-base:    #1e1e2e;",
    "  --clr-text:    #cdd6f4;",
    "  --clr-accent:  #89b4fa;",
    "  --clr-surface: #1e2030;",
    "",
    "  /* ── Spacing ─────────────────────────── */",
    "  --space-1: 0.25rem;",
    "  --space-2: 0.5rem;",
    "  --space-4: 1rem;",
    "  --space-8: 2rem;",
    "",
    "  /* ── Typography ─────────────────────── */",
    "  --font-sans: system-ui, sans-serif;",
    "  --font-mono: 'JetBrains Mono', monospace;",
    "  --font-size-base: clamp(1rem, 0.5vw + 0.8rem, 1.125rem);",
    "",
    "  /* ── Border ─────────────────────────── */",
    "  --radius-sm: 0.25rem;",
    "  --radius-md: 0.5rem;",
    "  --radius-lg: 1rem;",
    "",
    "  /* ── Transition ─────────────────────── */",
    "  --transition: 150ms ease-out;",
    "}",
  })
end, "Insert :root variables")

map("n", "<leader>csf", function()
  -- Insert flexbox container
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    ".container {",
    "  display:         flex;",
    "  flex-direction:  row;",
    "  flex-wrap:       wrap;",
    "  justify-content: flex-start;",
    "  align-items:     center;",
    "  gap:             var(--space-4, 1rem);",
    "}",
  })
end, "Insert flex container")

map("n", "<leader>csg", function()
  -- Insert grid container
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    ".grid {",
    "  display:               grid;",
    "  grid-template-columns: repeat(auto-fit, minmax(min(100%, 20rem), 1fr));",
    "  gap:                   var(--space-4, 1rem);",
    "}",
  })
end, "Insert grid container")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>ci", function()
  local file    = vim.api.nvim_buf_get_name(buf)
  local lines   = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local colours = find_colours()

  -- Count selectors and rules
  local selectors, rules, media = 0, 0, 0
  for _, line in ipairs(lines) do
    if line:match("{%s*$") then selectors = selectors + 1 end
    if line:match(":%s*[^{]+;") then rules = rules + 1 end
    if line:match("@media") then media = media + 1 end
  end

  vim.notify(
    table.concat({
      "🎨 CSS Info",
      "──────────────────────────────────",
      string.format("  Filetype:    %s", ft),
      string.format("  Lines:       %d", #lines),
      string.format("  Selectors:   ~%d", selectors),
      string.format("  Declarations:~%d", rules),
      string.format("  @media:      %d", media),
      string.format("  Colours:     %d unique", #colours),
      string.format("  stylelint:   %s", vim.fn.executable("stylelint") == 1 and "✅" or "⭕"),
      string.format("  prettier:    %s", vim.fn.executable("prettier") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "CSS" }
  )
end, "File info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtCss_" .. buf, { clear = true })

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