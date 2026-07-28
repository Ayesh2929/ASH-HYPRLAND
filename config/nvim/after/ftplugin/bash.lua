-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐚 BASH FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   shellcheck · shfmt · run · debug · bats test runner · POSIX compat          ║
-- ║   SC-disable helpers · shebang · error-set · trap patterns                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype  -- sh | bash | zsh

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 2
opt.tabstop      = 2
opt.softtabstop  = 2
opt.textwidth    = 100
opt.colorcolumn  = "101"
opt.commentstring= "# %s"

-- Treesitter folding
opt.foldmethod   = "expr"
opt.foldexpr     = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel    = 99
opt.foldenable   = true

-- Bash path resolution
opt.define  = [[^\s*\(function\s\+\)\?\([a-zA-Z_][a-zA-Z0-9_]*\)\s*()]]
opt.include = [[^\s*\.\s\|^\s*source\s]]

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 HELPERS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer  = buf,
    silent  = true,
    noremap = true,
    desc    = "🐚 Bash: " .. desc,
  })
end

-- Detect shell from shebang or filetype
local function detect_shell()
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  if first:match("bash")   then return "bash"   end
  if first:match("zsh")    then return "zsh"    end
  if first:match("sh")     then return "sh"     end
  if ft == "bash"          then return "bash"   end
  if ft == "zsh"           then return "zsh"    end
  return "bash"
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🐚 " .. title,
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
map("n", "<leader>br", function()
  local shell = detect_shell()
  local file  = vim.api.nvim_buf_get_name(buf)
  run_cmd(shell .. " " .. vim.fn.shellescape(file), "run")
end, "Run file")

map("n", "<leader>bd", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_cmd("bash -x " .. vim.fn.shellescape(file), "debug (bash -x)")
end, "Debug (bash -x)")

-- ── ShellCheck ───────────────────────────────────────────────────────────────
map("n", "<leader>bc", function()
  if vim.fn.executable("shellcheck") ~= 1 then
    vim.notify("🐚 shellcheck not found", vim.log.levels.WARN, { title = "Bash" })
    return
  end

  local file   = vim.api.nvim_buf_get_name(buf)
  local shell  = detect_shell()
  local result = vim.fn.system(
    "shellcheck --format=gcc --shell=" .. shell
      .. " " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  if vim.v.shell_error == 0 then
    vim.notify("🐚 ✅ ShellCheck: no issues", vim.log.levels.INFO,
      { title = "ShellCheck", timeout = 1500 })
    return
  end

  -- Parse to quickfix
  local qflist = {}
  for line in result:gmatch("[^\n]+") do
    local lnum, col, sev, msg = line:match(":(%d+):(%d+): (%w+): (.+)$")
    if lnum then
      table.insert(qflist, {
        filename = file,
        lnum     = tonumber(lnum),
        col      = tonumber(col),
        type     = sev == "error" and "E" or "W",
        text     = msg,
      })
    end
  end

  if #qflist > 0 then
    vim.fn.setqflist(qflist)
    vim.cmd("copen")
    vim.notify(
      string.format("🐚 ShellCheck: %d issue(s)", #qflist),
      vim.log.levels.WARN,
      { title = "ShellCheck" }
    )
  end
end, "ShellCheck")

map("n", "<leader>bC", function()
  if vim.fn.executable("shellcheck") ~= 1 then return end
  -- Suggest SC disable for current line's warning
  local row    = vim.api.nvim_win_get_cursor(0)[1]
  local line   = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local file   = vim.api.nvim_buf_get_name(buf)

  local result = vim.fn.system(
    "shellcheck --format=json " .. vim.fn.shellescape(file) .. " 2>/dev/null"
      .. " | jq -r '.[] | select(.line == " .. row .. ") | \"# shellcheck disable=SC\" + (.code | tostring)'"
  )

  if result ~= "" and vim.v.shell_error == 0 then
    local disable = vim.fn.trim(result):match("(# shellcheck disable=SC%d+)")
    if disable then
      -- Insert disable comment above current line
      local indent = line:match("^(%s*)")
      vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false,
        { indent .. disable })
      vim.notify("🐚 Inserted: " .. disable, vim.log.levels.INFO,
        { title = "ShellCheck", timeout = 1500 })
    end
  else
    vim.ui.input(
      { prompt = "🐚 SC code (e.g. 2086): " },
      function(code)
        if code and code:match("^%d+$") then
          local indent = line:match("^(%s*)")
          vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false,
            { indent .. "# shellcheck disable=SC" .. code })
        end
      end
    )
  end
end, "Add shellcheck disable")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>bf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
    return
  end
  -- Fallback: shfmt
  if vim.fn.executable("shfmt") ~= 1 then
    vim.notify("🐚 shfmt not found", vim.log.levels.WARN, { title = "Bash" })
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  local view = vim.fn.winsaveview()
  vim.fn.system("shfmt -w -i 2 -ci -bn " .. vim.fn.shellescape(file))
  vim.cmd("checktime")
  vim.fn.winrestview(view)
  vim.notify("🐚 shfmt: formatted", vim.log.levels.INFO,
    { title = "Bash", timeout = 1000 })
end, "Format (shfmt)")

-- ── Tests (bats) ──────────────────────────────────────────────────────────────
map("n", "<leader>bt", function()
  if vim.fn.executable("bats") ~= 1 then
    vim.notify("🐚 bats not found (brew install bats-core)", vim.log.levels.WARN,
      { title = "Bash" })
    return
  end
  local file = vim.api.nvim_buf_get_name(buf)
  if file:match("%.bats$") then
    run_cmd("bats " .. vim.fn.shellescape(file), "bats test")
  else
    -- Find related .bats file
    local test_file = file:gsub("%.sh$", ".bats")
    if vim.fn.filereadable(test_file) == 1 then
      run_cmd("bats " .. vim.fn.shellescape(test_file), "bats")
    else
      run_cmd("bats test/", "bats test/")
    end
  end
end, "Run bats tests")

-- ── Insert patterns ───────────────────────────────────────────────────────────
map("n", "<leader>bse", function()
  -- Insert strict mode header
  local row  = vim.api.nvim_win_get_cursor(0)[1]
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  local insert_at = first:match("^#!") and 1 or 0

  vim.api.nvim_buf_set_lines(buf, insert_at, insert_at, false, {
    "",
    "set -euo pipefail",
    "IFS=$'\\n\\t'",
    "",
  })
  vim.notify("🐚 Inserted strict mode", vim.log.levels.INFO,
    { title = "Bash", timeout = 1000 })
end, "Insert strict mode")

map("n", "<leader>bst", function()
  -- Insert trap cleanup pattern
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    "",
    "cleanup() {",
    "  local exit_code=$?",
    "  # cleanup code here",
    "  exit $exit_code",
    "}",
    "trap cleanup EXIT INT TERM HUP",
    "",
  })
end, "Insert trap cleanup")

map("n", "<leader>bsh", function()
  -- Insert shebang if not present
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  if first:match("^#!") then
    vim.notify("🐚 Shebang already exists", vim.log.levels.INFO,
      { title = "Bash" })
    return
  end

  local shell = detect_shell()
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
    "#!/usr/bin/env " .. shell,
  })
  vim.notify("🐚 Inserted shebang: " .. shell, vim.log.levels.INFO,
    { title = "Bash", timeout = 1000 })
end, "Insert shebang")

map("n", "<leader>bsl", function()
  -- Insert logging functions
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    "# ── Logging ────────────────────────────────────",
    "readonly RED='\\033[0;31m' GREEN='\\033[0;32m'",
    "readonly YELLOW='\\033[0;33m' RESET='\\033[0m'",
    "",
    "log::info()  { printf \"${GREEN}[INFO]${RESET}  %s\\n\" \"$*\"; }",
    "log::warn()  { printf \"${YELLOW}[WARN]${RESET}  %s\\n\" \"$*\" >&2; }",
    "log::error() { printf \"${RED}[ERR ]${RESET}  %s\\n\" \"$*\" >&2; }",
    "log::die()   { log::error \"$@\"; exit 1; }",
    "",
  })
end, "Insert logging functions")

-- ── Navigate functions ────────────────────────────────────────────────────────
map("n", "]f", function()
  vim.fn.search("^\\s*\\(function\\s\\+\\)\\?[a-zA-Z_][a-zA-Z0-9_]*\\s*()", "W")
end, "Next function")

map("n", "[f", function()
  vim.fn.search("^\\s*\\(function\\s\\+\\)\\?[a-zA-Z_][a-zA-Z0-9_]*\\s*()", "Wb")
end, "Prev function")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>bi", function()
  local shell    = detect_shell()
  local shell_v  = vim.fn.trim(vim.fn.system(shell .. " --version 2>/dev/null | head -1"))
  local shfmt_v  = vim.fn.trim(vim.fn.system("shfmt --version 2>/dev/null"))
  local sc_v     = vim.fn.trim(vim.fn.system("shellcheck --version 2>/dev/null | head -2 | tail -1"))

  vim.notify(
    table.concat({
      "🐚 Bash/Shell Info",
      "──────────────────────────────────",
      string.format("  Filetype:    %s", ft),
      string.format("  Shell:       %s", shell),
      string.format("  Version:     %s", shell_v),
      string.format("  shfmt:       %s", shfmt_v ~= "" and shfmt_v or "⭕"),
      string.format("  shellcheck:  %s", sc_v ~= "" and sc_v or "⭕"),
      string.format("  bats:        %s", vim.fn.executable("bats") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Bash" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtBash_" .. buf, { clear = true })

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

-- Make executable if shebang present
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  callback = function()
    local file  = vim.api.nvim_buf_get_name(buf)
    local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    if first:match("^#!") then
      local perm = vim.fn.getfperm(file)
      if perm:sub(3, 3) ~= "x" then
        vim.fn.system("chmod +x " .. vim.fn.shellescape(file))
      end
    end
  end,
})