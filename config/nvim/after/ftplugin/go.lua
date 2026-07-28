-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐹 GO FTPLUGIN — ASH v5.0 OMEGA                                          ║
-- ║   Go conventions · goimports · testing · coverage · generate · tools           ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS (Go style guide: hard tabs)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = false   -- Go uses hard tabs
opt.tabstop      = 4
opt.shiftwidth   = 4
opt.softtabstop  = 4
opt.textwidth    = 120
opt.colorcolumn  = "121"
opt.commentstring= "// %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- Tag handling for Go
opt.iskeyword:append("_")
opt.define   = [[^\s*\(func\|type\|var\|const\)]]
opt.include  = [[^\s*import\>]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🐹 Go: " .. desc,
  })
end

local function go_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🐹 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Get function name under cursor
local function get_func_name()
  local node = vim.treesitter.get_node()
  while node do
    if node:type() == "function_declaration" or node:type() == "method_declaration" then
      for child in node:iter_children() do
        if child:type() == "field_identifier" or child:type() == "identifier" then
          return vim.treesitter.get_node_text(child, buf)
        end
      end
    end
    node = node:parent()
  end
  return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Build / Run ───────────────────────────────────────────────────────────────
map("n", "<leader>gr", function()
  go_cmd("go run " .. vim.fn.shellescape(vim.api.nvim_buf_get_name(buf)), "run file")
end, "Run file")

map("n", "<leader>gR", function()
  go_cmd("go run ./...", "run all")
end, "Run ./...")

map("n", "<leader>gb", function()
  go_cmd("go build ./...", "build")
end, "Build")

map("n", "<leader>gi", function()
  go_cmd("go install ./...", "install")
end, "Install")

-- ── Test ─────────────────────────────────────────────────────────────────────
map("n", "<leader>gt", function()
  local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
  go_cmd("go test -v -count=1 " .. vim.fn.shellescape(dir), "test package")
end, "Test package")

map("n", "<leader>gT", function()
  go_cmd("go test -v -count=1 ./...", "test all")
end, "Test all")

map("n", "<leader>gtf", function()
  local fn = get_func_name()
  if fn and fn:match("^Test") then
    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
    go_cmd(
      "go test -v -count=1 -run ^" .. fn .. "$ " .. vim.fn.shellescape(dir),
      "test: " .. fn
    )
  else
    vim.notify("🐹 No Test* function at cursor", vim.log.levels.WARN, { title = "Go" })
  end
end, "Test function at cursor")

map("n", "<leader>gtr", function()
  go_cmd("go test -race -count=1 ./...", "test --race")
end, "Test with race detector")

map("n", "<leader>gtc", function()
  local tmp = "/tmp/go_coverage_" .. os.time() .. ".out"
  go_cmd(
    "go test -coverprofile=" .. tmp .. " ./... && go tool cover -html=" .. tmp,
    "coverage"
  )
end, "Coverage (browser)")

-- ── Benchmarks ────────────────────────────────────────────────────────────────
map("n", "<leader>gbn", function()
  go_cmd("go test -bench=. -benchmem ./...", "bench")
end, "Benchmark")

-- ── Lint / Vet ────────────────────────────────────────────────────────────────
map("n", "<leader>gv", function()
  go_cmd("go vet ./...", "vet")
end, "go vet")

map("n", "<leader>gl", function()
  if vim.fn.executable("golangci-lint") == 1 then
    go_cmd("golangci-lint run --fast ./...", "golangci-lint")
  else
    vim.notify("🐹 golangci-lint not found", vim.log.levels.WARN, { title = "Go" })
  end
end, "golangci-lint")

-- ── Generate ──────────────────────────────────────────────────────────────────
map("n", "<leader>gg", function()
  go_cmd("go generate ./...", "generate")
end, "go generate")

map("n", "<leader>gG", function()
  -- go:generate on current file
  local file = vim.api.nvim_buf_get_name(buf)
  go_cmd("go generate " .. vim.fn.shellescape(file), "generate file")
end, "go generate file")

-- ── Mod ───────────────────────────────────────────────────────────────────────
map("n", "<leader>gmt", function() go_cmd("go mod tidy", "mod tidy")   end, "go mod tidy")
map("n", "<leader>gmd", function() go_cmd("go mod download", "mod dl") end, "go mod download")
map("n", "<leader>gmv", function() go_cmd("go mod verify", "mod verify") end, "go mod verify")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>gf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  end
end, "Format")

-- ── Alternate (impl ↔ test) ───────────────────────────────────────────────────
map("n", "<leader>ga", function()
  local ok, go_nvim = pcall(require, "go.alternate")
  if ok then
    go_nvim.switch(false)
  else
    -- Simple manual alternate
    local file = vim.api.nvim_buf_get_name(buf)
    if file:match("_test%.go$") then
      vim.cmd("edit " .. file:gsub("_test%.go$", ".go"))
    else
      vim.cmd("edit " .. file:gsub("%.go$", "_test.go"))
    end
  end
end, "Toggle test/impl")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>gii", function()
  local ver = vim.fn.trim(vim.fn.system("go version 2>/dev/null"))
  local mod  = vim.fn.trim(vim.fn.system("go list -m 2>/dev/null"))
  vim.notify(
    table.concat({
      "🐹 Go Environment",
      "──────────────────────────────────",
      string.format("  Version: %s", ver),
      string.format("  Module:  %s", mod),
      string.format("  GOPATH:  %s", os.getenv("GOPATH") or "(unset)"),
      string.format("  CGO:     %s", vim.fn.trim(vim.fn.system("go env CGO_ENABLED 2>/dev/null"))),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Go" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtGo_" .. buf, { clear = true })

-- goimports + gofumpt on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok_go, format = pcall(require, "go.format")
    if ok_go then
      format.goimport()
      return
    end
    local ok_conform, conform = pcall(require, "conform")
    if ok_conform then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    end
  end,
})

-- Codelens refresh
vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
  group  = aug,
  buffer = buf,
  callback = function()
    pcall(vim.lsp.codelens.refresh)
  end,
})

-- compile_commands.json symlink (for gopls tools)
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  once   = true,
  callback = function()
    local cwd = vim.fn.getcwd()
    if vim.fn.filereadable(cwd .. "/go.mod") == 0 then return end
    -- Run go mod tidy suggestion check (non-blocking)
    vim.fn.jobstart({ "go", "mod", "verify" }, {
      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify(
              "🐹 go mod verify failed — run :Go mod tidy",
              vim.log.levels.WARN,
              { title = "Go", timeout = 3000 }
            )
          end)
        end
      end,
    })
  end,
})