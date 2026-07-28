-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦀 RUST FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   Cargo · clippy · test · bench · expand macros · docs · edition               ║
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
opt.commentstring= "// %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- iskeyword: Rust uses underscores heavily
opt.iskeyword:append("_")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🦀 Rust: " .. desc,
  })
end

local function cargo(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = "cargo " .. cmd,
      direction    = "float",
      display_name = "🦀 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://cargo " .. cmd)
  end
end

-- Detect Rust edition from Cargo.toml
local function get_edition()
  local cargo_toml = vim.fn.getcwd() .. "/Cargo.toml"
  local f = io.open(cargo_toml, "r")
  if not f then return "2021" end
  local content = f:read("*a")
  f:close()
  return content:match("^edition%s*=%s*\"(%d+)\"") or "2021"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Cargo basics ─────────────────────────────────────────────────────────────
map("n", "<leader>rb", function() cargo("build", "build") end,            "cargo build")
map("n", "<leader>rB", function() cargo("build --release", "release") end,"cargo build --release")
map("n", "<leader>rr", function() cargo("run", "run") end,                "cargo run")
map("n", "<leader>rR", function()
  cargo("run --release", "run --release")
end, "cargo run --release")

map("n", "<leader>rc", function() cargo("check", "check") end,            "cargo check")
map("n", "<leader>rC", function() cargo("clippy -- -W clippy::pedantic", "clippy") end, "clippy")
map("n", "<leader>rf", function() cargo("fmt", "fmt") end,                "cargo fmt")
map("n", "<leader>rF", function() cargo("fmt -- --check", "fmt check") end, "fmt check")
map("n", "<leader>rx", function() cargo("clean", "clean") end,            "cargo clean")

-- ── Tests ────────────────────────────────────────────────────────────────────
map("n", "<leader>rt", function() cargo("test", "test") end,              "cargo test")
map("n", "<leader>rT", function()
  cargo("test -- --nocapture", "test verbose")
end, "cargo test --nocapture")

map("n", "<leader>rtf", function()
  -- Test function under cursor
  local node = vim.treesitter.get_node()
  local fn_name = nil
  while node do
    if node:type() == "function_item" then
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
    cargo("test " .. fn_name .. " -- --nocapture", "test: " .. fn_name)
  else
    vim.notify("🦀 No test function at cursor", vim.log.levels.WARN, { title = "Rust" })
  end
end, "Test function at cursor")

-- ── Benchmarks ────────────────────────────────────────────────────────────────
map("n", "<leader>rbn", function() cargo("bench", "bench") end, "cargo bench")

-- ── Documentation ────────────────────────────────────────────────────────────
map("n", "<leader>rd", function() cargo("doc --open", "doc --open") end, "cargo doc --open")
map("n", "<leader>rD", function() cargo("doc", "doc") end,               "cargo doc")

-- ── rustaceanvim actions ──────────────────────────────────────────────────────
map("n", "<leader>rra", function() vim.cmd.RustLsp("codeAction")  end,   "Code actions")
map("n", "<leader>rrr", function() vim.cmd.RustLsp("runnables")   end,   "Runnables")
map("n", "<leader>rrd", function() vim.cmd.RustLsp("debuggables") end,   "Debuggables")
map("n", "<leader>rrt", function() vim.cmd.RustLsp("testables")   end,   "Testables")
map("n", "<leader>rrm", function() vim.cmd.RustLsp("expandMacro") end,   "Expand macro")
map("n", "<leader>rro", function() vim.cmd.RustLsp("openDocs")    end,   "Open docs.rs")
map("n", "<leader>rrh", function() vim.cmd.RustLsp("viewHir")     end,   "View HIR")
map("n", "<leader>rre", function() vim.cmd.RustLsp("explainError") end,  "Explain error")
map("n", "<leader>rrf", function() vim.cmd.RustLsp("flyCheck")    end,   "Fly check")
map("n", "<leader>rrs", function() vim.cmd.RustLsp("ssr")         end,   "Structural search replace")
map("n", "K",           function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover actions")

-- ── Crates ───────────────────────────────────────────────────────────────────
map("n", "<leader>rcp", function()
  local ok, crates = pcall(require, "crates")
  if ok then crates.show_popup() end
end, "Crates: popup")

map("n", "<leader>rcu", function()
  local ok, crates = pcall(require, "crates")
  if ok then crates.upgrade_all_crates() end
end, "Crates: upgrade all")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>rri", function()
  local ed  = get_edition()
  local ver = vim.fn.trim(vim.fn.system("rustc --version 2>/dev/null"))
  local cargo_ver = vim.fn.trim(vim.fn.system("cargo --version 2>/dev/null"))
  vim.notify(
    table.concat({
      "🦀 Rust Environment",
      "──────────────────────────────────",
      string.format("  rustc:   %s", ver),
      string.format("  cargo:   %s", cargo_ver),
      string.format("  edition: %s", ed),
      string.format("  cwd:     %s", vim.fn.fnamemodify(vim.fn.getcwd(), ":~")),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Rust" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtRust_" .. buf, { clear = true })

-- Format on save via rustfmt (through LSP / conform)
vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok_conform, conform = pcall(require, "conform")
    if ok_conform then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
      return
    end
    -- Fallback: LSP format
    vim.lsp.buf.format({
      bufnr  = buf,
      async  = false,
      filter = function(c) return c.name == "rust-analyzer" end,
    })
  end,
})

-- Auto-refresh codelens
vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
  group  = aug,
  buffer = buf,
  callback = function()
    pcall(vim.lsp.codelens.refresh)
  end,
})