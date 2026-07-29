-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ☕ JAVA FTPLUGIN — ASH v5.0 OMEGA                                         ║
-- ║   jdtls · maven/gradle · test runner · lombok · spring boot                    ║
-- ║   organize imports · code actions · extract/refactor · debug                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS (Google Java Style)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 4
opt.tabstop      = 4
opt.softtabstop  = 4
opt.textwidth    = 120
opt.colorcolumn  = "121"
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
    desc    = "☕ Java: " .. desc,
  })
end

-- Detect build tool
local function detect_build_tool()
  local cwd = vim.fn.getcwd()
  if vim.fn.filereadable(cwd .. "/gradlew")    == 1 then return "./gradlew" end
  if vim.fn.filereadable(cwd .. "/mvnw")       == 1 then return "./mvnw"    end
  if vim.fn.executable("gradle")               == 1 then return "gradle"    end
  if vim.fn.executable("mvn")                  == 1 then return "mvn"       end
  return nil
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "☕ " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

local function build_cmd(sub)
  local bt = detect_build_tool()
  if not bt then
    vim.notify("☕ No build tool (gradle/maven)", vim.log.levels.WARN, { title = "Java" })
    return nil
  end

  if bt:find("gradle") then
    return bt .. " " .. sub
  elseif bt:find("mvn") then
    -- Map gradle subcommands to maven equivalents
    local maven_map = {
      build  = "compile",
      test   = "test",
      run    = "exec:java",
      clean  = "clean",
      jar    = "package",
    }
    return bt .. " " .. (maven_map[sub] or sub)
  end
  return bt .. " " .. sub
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── jdtls actions ────────────────────────────────────────────────────────────
map("n", "<leader>jo", function()
  require("jdtls").organize_imports()
end, "Organize imports")

map("n", "<leader>jv", function()
  require("jdtls").extract_variable()
end, "Extract variable")

map("v", "<leader>jv", function()
  require("jdtls").extract_variable(true)
end, "Extract variable (visual)")

map("n", "<leader>jc", function()
  require("jdtls").extract_constant()
end, "Extract constant")

map("v", "<leader>jm", function()
  require("jdtls").extract_method(true)
end, "Extract method")

map("n", "<leader>jM", function()
  require("jdtls").super_implementation()
end, "Super implementation")

map("n", "<leader>ju", function()
  require("jdtls").update_project_config()
end, "Update project config")

-- ── Tests ─────────────────────────────────────────────────────────────────────
map("n", "<leader>jt", function()
  require("jdtls").test_class()
end, "Test class")

map("n", "<leader>jT", function()
  require("jdtls").test_nearest_method()
end, "Test nearest method")

-- ── Build ─────────────────────────────────────────────────────────────────────
map("n", "<leader>jb", function()
  local cmd = build_cmd("build")
  if cmd then run_cmd(cmd, "build") end
end, "Build")

map("n", "<leader>jB", function()
  local cmd = build_cmd("clean build")
  if cmd then run_cmd(cmd, "clean build") end
end, "Clean build")

map("n", "<leader>jr", function()
  local cmd = build_cmd("run")
  if cmd then run_cmd(cmd, "run") end
end, "Run")

map("n", "<leader>jC", function()
  local cmd = build_cmd("clean")
  if cmd then run_cmd(cmd, "clean") end
end, "Clean")

map("n", "<leader>jta", function()
  local cmd = build_cmd("test")
  if cmd then run_cmd(cmd, "test all") end
end, "Test all")

-- ── Spring Boot ───────────────────────────────────────────────────────────────
map("n", "<leader>jss", function()
  local bt = detect_build_tool()
  if not bt then return end
  local cmd = bt:find("gradle") and bt .. " bootRun"
           or bt .. " spring-boot:run"
  run_cmd(cmd, "Spring Boot: run")
end, "Spring Boot: run")

map("n", "<leader>jsp", function()
  local bt = detect_build_tool()
  if not bt then return end
  local cmd = bt:find("gradle") and bt .. " bootJar"
           or bt .. " package -DskipTests"
  run_cmd(cmd, "Spring Boot: package")
end, "Spring Boot: package")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>jf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  else
    vim.lsp.buf.format({ bufnr = buf, async = false })
  end
end, "Format")

-- ── Add missing imports (AI-style via LSP) ───────────────────────────────────
map("n", "<leader>ji", function()
  require("jdtls").add_imports()
end, "Add missing imports")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>jI", function()
  local bt    = detect_build_tool() or "none"
  local java  = vim.fn.trim(vim.fn.system("java -version 2>&1 | head -1"))
  local jdtls_ok = vim.fn.isdirectory(
    vim.fn.stdpath("data") .. "/mason/packages/jdtls"
  ) == 1

  vim.notify(
    table.concat({
      "☕ Java Environment",
      "──────────────────────────────────",
      string.format("  Java:      %s", java),
      string.format("  Build:     %s", bt),
      string.format("  jdtls:     %s", jdtls_ok and "✅" or "⭕"),
      string.format("  lombok:    %s",
        vim.fn.filereadable(vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar") == 1
          and "✅" or "⭕"),
      string.format("  JAVA_HOME: %s", os.getenv("JAVA_HOME") or "(not set)"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Java" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtJava_" .. buf, { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group  = aug,
  buffer = buf,
  callback = function()
    local ok, conform = pcall(require, "conform")
    if ok then
      conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    else
      vim.lsp.buf.format({ bufnr = buf, async = false })
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
  group  = aug,
  buffer = buf,
  callback = function()
    pcall(vim.lsp.codelens.refresh)
  end,
})