-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📘 TYPESCRIPT FTPLUGIN — ASH v5.0 OMEGA                                  ║
-- ║   TS/TSX · organize imports · type-check · jest/vitest · prettier · tsc        ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype   -- typescript | typescriptreact | etc.

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "// %s"

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
    desc    = "📘 TS: " .. desc,
  })
end

local function detect_pm()
  local cwd = vim.fn.getcwd()
  if vim.fn.filereadable(cwd .. "/pnpm-lock.yaml") == 1 then return "pnpm" end
  if vim.fn.filereadable(cwd .. "/yarn.lock")      == 1 then return "yarn" end
  if vim.fn.filereadable(cwd .. "/bun.lockb")      == 1 then return "bun"  end
  return "npm"
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "📘 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Find test runner in project
local function find_runner(name)
  local cwd = vim.fn.getcwd()
  local bin = cwd .. "/node_modules/.bin/" .. name
  if vim.fn.executable(bin) == 1 then return bin end
  return name
end

-- Detect test framework
local function detect_test_framework()
  local cwd = vim.fn.getcwd()
  local pkg = cwd .. "/package.json"
  local f   = io.open(pkg, "r")
  if not f then return "jest" end
  local content = f:read("*a")
  f:close()

  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then return "jest" end

  local deps = vim.tbl_extend("force",
    data.dependencies or {}, data.devDependencies or {}
  )

  if deps["vitest"] then return "vitest" end
  if deps["jest"]   then return "jest"   end
  return "jest"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── typescript-tools.nvim ────────────────────────────────────────────────────
map("n", "<leader>to", "<cmd>TSToolsOrganizeImports<cr>",         "Organize imports")
map("n", "<leader>ts", "<cmd>TSToolsSortImports<cr>",             "Sort imports")
map("n", "<leader>tu", "<cmd>TSToolsRemoveUnusedImports<cr>",     "Remove unused imports")
map("n", "<leader>tU", "<cmd>TSToolsRemoveUnused<cr>",            "Remove unused")
map("n", "<leader>ta", "<cmd>TSToolsAddMissingImports<cr>",       "Add missing imports")
map("n", "<leader>tf", "<cmd>TSToolsFixAll<cr>",                  "Fix all")
map("n", "<leader>tg", "<cmd>TSToolsGoToSourceDefinition<cr>",    "Go to source def")
map("n", "<leader>tr", "<cmd>TSToolsRenameFile<cr>",              "Rename file")
map("n", "<leader>tR", "<cmd>TSToolsFileReferences<cr>",          "File references")

-- ── Type checking ─────────────────────────────────────────────────────────────
map("n", "<leader>ttc", function()
  local pm  = detect_pm()
  local cmd
  if vim.fn.filereadable(vim.fn.getcwd() .. "/tsconfig.json") == 1 then
    cmd = "npx tsc --noEmit"
  else
    cmd = pm .. " run typecheck"
  end
  run_cmd(cmd, "type-check")
end, "Type check (tsc)")

-- ── Test ──────────────────────────────────────────────────────────────────────
map("n", "<leader>ttt", function()
  local fw   = detect_test_framework()
  local file = vim.api.nvim_buf_get_name(buf)
  local pm   = detect_pm()
  local cmd

  if fw == "vitest" then
    cmd = find_runner("vitest") .. " run " .. vim.fn.shellescape(file)
  else
    cmd = find_runner("jest") .. " --runInBand --testPathPattern "
      .. vim.fn.shellescape(vim.fn.fnamemodify(file, ":t"))
  end

  run_cmd(cmd, fw .. ": file")
end, "Test current file")

map("n", "<leader>ttT", function()
  local fw = detect_test_framework()
  local pm = detect_pm()
  run_cmd(pm .. " test", fw .. ": all")
end, "Test all")

map("n", "<leader>ttw", function()
  local fw = detect_test_framework()
  local file = vim.api.nvim_buf_get_name(buf)
  local cmd

  if fw == "vitest" then
    cmd = find_runner("vitest") .. " watch " .. vim.fn.shellescape(file)
  else
    cmd = find_runner("jest") .. " --watch --testPathPattern "
      .. vim.fn.shellescape(vim.fn.fnamemodify(file, ":t"))
  end

  run_cmd(cmd, fw .. ": watch")
end, "Test watch")

-- ── Script runners ────────────────────────────────────────────────────────────
map("n", "<leader>tnx", function()
  local file = vim.api.nvim_buf_get_name(buf)
  -- Choose ts-runner
  local runners = {
    { name = "tsx",      cmd = "tsx" },
    { name = "ts-node",  cmd = "node --loader ts-node/esm --no-experimental-warnings" },
    { name = "deno run", cmd = "deno run --allow-all" },
  }
  for _, r in ipairs(runners) do
    if vim.fn.executable(r.cmd:match("^%S+")) == 1 then
      run_cmd(r.cmd .. " " .. vim.fn.shellescape(file), r.name)
      return
    end
  end
  vim.notify("📘 No TS runner found (tsx / ts-node / deno)", vim.log.levels.WARN,
    { title = "TypeScript" })
end, "Run file (tsx/ts-node/deno)")

-- ── Package scripts ───────────────────────────────────────────────────────────
map("n", "<leader>tns", function()
  local pm       = detect_pm()
  local pkg_file = vim.fn.getcwd() .. "/package.json"
  local f        = io.open(pkg_file, "r")
  if not f then
    vim.notify("📘 No package.json found", vim.log.levels.WARN, { title = "TS" })
    return
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then return end
  local scripts = data.scripts or {}
  local names   = vim.tbl_keys(scripts)
  table.sort(names)

  vim.ui.select(names, { prompt = "📘 " .. pm .. " script: " }, function(script)
    if script then run_cmd(pm .. " run " .. script, script) end
  end)
end, "Run npm script")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>tF", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  end
end, "Format")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>tni", function()
  local pm       = detect_pm()
  local pm_ver   = vim.fn.trim(vim.fn.system(pm .. " --version 2>/dev/null"))
  local node_ver = vim.fn.trim(vim.fn.system("node --version 2>/dev/null"))
  local ts_ver   = (function()
    local f = io.open(vim.fn.getcwd() .. "/node_modules/typescript/package.json", "r")
    if not f then return "unknown" end
    local c = f:read("*a"); f:close()
    local ok, d = pcall(vim.fn.json_decode, c)
    return ok and d.version or "unknown"
  end)()
  local fw = detect_test_framework()

  vim.notify(
    table.concat({
      "📘 TypeScript Environment",
      "──────────────────────────────────",
      string.format("  Node:       %s", node_ver),
      string.format("  TypeScript: %s", ts_ver),
      string.format("  PM:         %s %s", pm, pm_ver),
      string.format("  Filetype:   %s", ft),
      string.format("  Test fw:    %s", fw),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "TypeScript" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtTypeScript_" .. buf, { clear = true })

-- Format on save (prettier via conform)
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

-- Auto-organise imports on save (via typescript-tools)
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    -- Only organise if typescript-tools is the active LSP
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if client.name == "typescript-tools" then
        pcall(vim.cmd, "TSToolsOrganizeImports")
        break
      end
    end
  end,
})