-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📋 YAML FTPLUGIN — ASH v5.0 OMEGA                                        ║
-- ║   yamllint · validate · schema detect · k8s/compose/GHA · anchors             ║
-- ║   yq queries · fold · indent helpers · format                                  ║
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
opt.textwidth    = 120
opt.colorcolumn  = "121"
opt.commentstring= "# %s"
opt.wrap         = false

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
    desc    = "📋 YAML: " .. desc,
  })
end

-- Detect YAML document type
local function detect_yaml_type()
  local file  = vim.api.nvim_buf_get_name(buf)
  local name  = vim.fn.fnamemodify(file, ":t")
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 20, false)

  -- File name patterns
  if name:match("docker%-compose") then return "docker-compose" end
  if file:match("%.github/workflows/") then return "github-actions"  end
  if name == "Chart.yaml" or name == "values.yaml" then return "helm" end

  -- Content patterns
  for _, line in ipairs(lines) do
    if line:match("^apiVersion:") then
      local api = line:match("^apiVersion:%s*(.+)$")
      if api then
        if api:match("apps/")      then return "kubernetes-apps"   end
        if api:match("networking") then return "kubernetes-net"    end
        return "kubernetes"
      end
    end
    if line:match("^services:") and (
      vim.fn.filereadable(vim.fn.getcwd() .. "/docker-compose.yml") == 1 or
      vim.fn.filereadable(vim.fn.getcwd() .. "/compose.yml") == 1
    ) then return "docker-compose" end
    if line:match("^on:%s*$") or line:match("^on:%s*push") then return "github-actions" end
    if line:match("workflow_dispatch") then return "github-actions" end
  end

  return "generic"
end

-- Run yq query
local function yq(args, notify_title)
  if vim.fn.executable("yq") ~= 1 then
    vim.notify("📋 yq not found", vim.log.levels.WARN, { title = "YAML" })
    return nil
  end

  local file   = vim.api.nvim_buf_get_name(buf)
  local result = vim.fn.system(
    "yq " .. args .. " " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  if vim.v.shell_error ~= 0 then
    vim.notify("📋 yq error:\n" .. result, vim.log.levels.ERROR,
      { title = notify_title or "YAML" })
    return nil
  end

  return vim.fn.trim(result)
end

-- Run command in terminal
local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "📋 " .. title,
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

-- ── Validate ──────────────────────────────────────────────────────────────────
map("n", "<leader>yv", function()
  local file = vim.api.nvim_buf_get_name(buf)

  if vim.fn.executable("yamllint") == 1 then
    local result = vim.fn.system(
      "yamllint -d '{extends: relaxed, rules: {line-length: {max: 120}}}' "
        .. vim.fn.shellescape(file) .. " 2>&1"
    )

    if vim.v.shell_error == 0 then
      vim.notify("📋 ✅ Valid YAML", vim.log.levels.INFO,
        { title = "yamllint", timeout = 1500 })
    else
      -- Parse to quickfix
      local qflist = {}
      for line in result:gmatch("[^\n]+") do
        local lnum, col, sev, msg = line:match(":(%d+):(%d+): (%w+) (.+)$")
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
        vim.notify(string.format("📋 %d issue(s)", #qflist), vim.log.levels.WARN,
          { title = "yamllint" })
      end
    end

  elseif vim.fn.executable("yq") == 1 then
    -- Fallback: parse with yq
    yq("'.'", "validate")
    vim.notify("📋 ✅ Parses OK", vim.log.levels.INFO,
      { title = "YAML", timeout = 1500 })
  else
    vim.notify("📋 Install yamllint or yq for validation",
      vim.log.levels.WARN, { title = "YAML" })
  end
end, "Validate")

-- ── Format ────────────────────────────────────────────────────────────────────
map("n", "<leader>yf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ bufnr = buf, async = false, timeout_ms = 5000 })
  else
    vim.lsp.buf.format({ bufnr = buf, async = false })
  end
end, "Format")

-- ── yq query ─────────────────────────────────────────────────────────────────
map("n", "<leader>yq", function()
  vim.ui.input({ prompt = "📋 yq expression: " }, function(expr)
    if not expr or expr == "" then return end
    local result = yq(vim.fn.shellescape(expr), "yq")
    if result then
      vim.notify("📋 Result:\n" .. result, vim.log.levels.INFO,
        { title = "yq" })
    end
  end)
end, "yq query")

map("n", "<leader>yQ", function()
  vim.ui.input({ prompt = "📋 yq expression (→ buffer): " }, function(expr)
    if not expr or expr == "" then return end
    local result = yq(vim.fn.shellescape(expr), "yq")
    if result then
      vim.cmd("new")
      local new_buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, vim.split(result, "\n"))
      vim.bo[new_buf].filetype  = "yaml"
      vim.bo[new_buf].buftype   = "nofile"
      vim.bo[new_buf].buflisted = false
    end
  end)
end, "yq query → buffer")

-- ── Kubernetes ────────────────────────────────────────────────────────────────
map("n", "<leader>yk", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("kubectl") ~= 1 then
    vim.notify("📋 kubectl not found", vim.log.levels.WARN, { title = "YAML" })
    return
  end
  run_cmd(
    "kubectl apply -f " .. vim.fn.shellescape(file) .. " --dry-run=client",
    "kubectl dry-run"
  )
end, "kubectl dry-run")

map("n", "<leader>yK", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("kubectl") ~= 1 then
    vim.notify("📋 kubectl not found", vim.log.levels.WARN, { title = "YAML" })
    return
  end
  run_cmd(
    "kubectl apply -f " .. vim.fn.shellescape(file),
    "kubectl apply"
  )
end, "kubectl apply")

map("n", "<leader>ykv", function()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.fn.executable("kubeval") == 1 then
    run_cmd("kubeval " .. vim.fn.shellescape(file), "kubeval")
  elseif vim.fn.executable("kubeconform") == 1 then
    run_cmd("kubeconform " .. vim.fn.shellescape(file), "kubeconform")
  else
    vim.notify("📋 Install kubeval or kubeconform", vim.log.levels.WARN,
      { title = "YAML" })
  end
end, "Validate Kubernetes schema")

-- ── Docker Compose ────────────────────────────────────────────────────────────
map("n", "<leader>ydu", function()
  run_cmd("docker compose up --build", "compose up")
end, "docker compose up")

map("n", "<leader>ydd", function()
  run_cmd("docker compose down", "compose down")
end, "docker compose down")

map("n", "<leader>ydv", function()
  local file = vim.api.nvim_buf_get_name(buf)
  run_cmd("docker compose -f " .. vim.fn.shellescape(file) .. " config", "compose validate")
end, "docker compose validate")

-- ── GitHub Actions ────────────────────────────────────────────────────────────
map("n", "<leader>yal", function()
  if vim.fn.executable("actionlint") == 1 then
    local file   = vim.api.nvim_buf_get_name(buf)
    local result = vim.fn.system("actionlint " .. vim.fn.shellescape(file) .. " 2>&1")
    if vim.v.shell_error == 0 then
      vim.notify("📋 ✅ Workflow valid", vim.log.levels.INFO,
        { title = "actionlint", timeout = 1500 })
    else
      vim.notify("📋 Issues:\n" .. result, vim.log.levels.WARN,
        { title = "actionlint" })
    end
  else
    vim.notify("📋 actionlint not found", vim.log.levels.WARN, { title = "YAML" })
  end
end, "actionlint (GitHub Actions)")

-- ── Type detection ────────────────────────────────────────────────────────────
map("n", "<leader>yt", function()
  local yaml_type = detect_yaml_type()
  local icons = {
    kubernetes         = "☸️  Kubernetes",
    ["kubernetes-apps"]= "☸️  Kubernetes Apps",
    ["kubernetes-net"] = "☸️  Kubernetes Network",
    ["docker-compose"] = "🐳 Docker Compose",
    ["github-actions"] = " GitHub Actions",
    helm               = "⛵ Helm",
    generic            = "📋 Generic YAML",
  }
  vim.notify(
    string.format("📋 Type: %s", icons[yaml_type] or yaml_type),
    vim.log.levels.INFO,
    { title = "YAML", timeout = 1500 }
  )
end, "Detect type")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>yi", function()
  local yaml_type = detect_yaml_type()
  local file      = vim.api.nvim_buf_get_name(buf)
  local lines     = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  vim.notify(
    table.concat({
      "📋 YAML Info",
      "──────────────────────────────────",
      string.format("  File:      %s", vim.fn.fnamemodify(file, ":t")),
      string.format("  Type:      %s", yaml_type),
      string.format("  Lines:     %d", #lines),
      string.format("  yamllint:  %s", vim.fn.executable("yamllint") == 1 and "✅" or "⭕"),
      string.format("  yq:        %s", vim.fn.executable("yq")        == 1 and "✅" or "⭕"),
      string.format("  kubectl:   %s", vim.fn.executable("kubectl")   == 1 and "✅" or "⭕"),
      string.format("  actionlint:%s", vim.fn.executable("actionlint") == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "YAML" }
  )
end, "Info")

-- ── Copy key path at cursor ───────────────────────────────────────────────────
map("n", "<leader>yp", function()
  -- Build YAML key path from indentation
  local row    = vim.api.nvim_win_get_cursor(0)[1]
  local lines  = vim.api.nvim_buf_get_lines(buf, 0, row, false)
  local path   = {}
  local indent = math.huge

  for i = #lines, 1, -1 do
    local line = lines[i]
    local cur_indent = #line:match("^(%s*)") or 0
    local key  = line:match("^%s*([%w_%-%.]+)%s*:")

    if key and cur_indent < indent then
      table.insert(path, 1, key)
      indent = cur_indent
      if indent == 0 then break end
    end
  end

  local path_str = table.concat(path, ".")
  if path_str ~= "" then
    vim.fn.setreg("+", path_str)
    vim.notify("📋 Copied: " .. path_str, vim.log.levels.INFO,
      { title = "YAML", timeout = 1200 })
  else
    vim.notify("📋 Could not determine path", vim.log.levels.WARN,
      { title = "YAML" })
  end
end, "Copy key path")

-- ── Fold ─────────────────────────────────────────────────────────────────────
map("n", "<leader>yM", "zM", "Fold all")
map("n", "<leader>yR", "zR", "Unfold all")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtYaml_" .. buf, { clear = true })

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

-- Auto-detect schema type on open
vim.api.nvim_create_autocmd("BufWinEnter", {
  group  = aug,
  buffer = buf,
  once   = true,
  callback = function()
    local yaml_type = detect_yaml_type()
    if yaml_type ~= "generic" and vim.g.ash_debug then
      vim.notify(
        "📋 Detected: " .. yaml_type,
        vim.log.levels.DEBUG,
        { title = "YAML", timeout = 1000 }
      )
    end

    -- Set docker-compose filetype for compose files
    local file = vim.api.nvim_buf_get_name(buf)
    local name = vim.fn.fnamemodify(file, ":t")
    if name:match("docker%-compose") or name == "compose.yml" or name == "compose.yaml" then
      vim.bo[buf].filetype = "yaml.docker-compose"
    end
  end,
})