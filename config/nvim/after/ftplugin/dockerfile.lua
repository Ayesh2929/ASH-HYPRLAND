-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐳 DOCKERFILE FTPLUGIN — ASH v5.0 OMEGA                                  ║
-- ║   hadolint · docker build · compose · dive · security scan                    ║
-- ║   multi-stage · layer analysis · base image picker · best-practice hints      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

local buf = vim.api.nvim_get_current_buf()
local opt = vim.opt_local
local ft  = vim.bo[buf].filetype  -- dockerfile | yaml.docker-compose

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚙️  EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

opt.expandtab    = true
opt.shiftwidth   = 4
opt.tabstop      = 4
opt.softtabstop  = 4
opt.textwidth    = 0
opt.wrap         = false
opt.commentstring= "# %s"

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
    desc    = "🐳 Docker: " .. desc,
  })
end

local function run_cmd(cmd, title)
  local ok, term = pcall(require, "toggleterm.terminal")
  if ok then
    term.Terminal:new({
      cmd          = cmd,
      direction    = "float",
      display_name = "🐳 " .. title,
      float_opts   = { border = "rounded" },
      close_on_exit = false,
    }):toggle()
  else
    vim.cmd("split term://" .. cmd)
  end
end

-- Get image tag from Dockerfile or prompt
local function get_image_tag()
  -- Try to detect from file name or directory
  local cwd  = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")
  return name:lower():gsub("[^%w%-_]", "-") .. ":latest"
end

-- Extract stage names from multi-stage Dockerfile
local function get_stages()
  local lines  = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local stages = {}
  for _, line in ipairs(lines) do
    local stage = line:match("^FROM%s+[^%s]+%s+[Aa][Ss]%s+([%w_%-]+)")
    if stage then
      table.insert(stages, stage)
    end
  end
  return stages
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🗺️  KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- ── Lint ─────────────────────────────────────────────────────────────────────
map("n", "<leader>dkl", function()
  if vim.fn.executable("hadolint") ~= 1 then
    vim.notify("🐳 hadolint not found — install via Mason", vim.log.levels.WARN,
      { title = "Docker" })
    return
  end

  local file   = vim.api.nvim_buf_get_name(buf)
  local result = vim.fn.system(
    "hadolint --format=json " .. vim.fn.shellescape(file) .. " 2>&1"
  )

  if vim.v.shell_error == 0 then
    vim.notify("🐳 ✅ Dockerfile OK", vim.log.levels.INFO,
      { title = "hadolint", timeout = 1500 })
    return
  end

  local ok, data = pcall(vim.fn.json_decode, result)
  if not ok then
    vim.notify("🐳 hadolint error:\n" .. result, vim.log.levels.ERROR,
      { title = "hadolint" })
    return
  end

  local qflist = {}
  for _, item in ipairs(data or {}) do
    table.insert(qflist, {
      filename = item.file or file,
      lnum     = item.line or 1,
      col      = item.column or 1,
      type     = item.level == "error" and "E" or "W",
      text     = string.format("[%s] %s", item.code or "", item.message or ""),
    })
  end

  if #qflist > 0 then
    vim.fn.setqflist(qflist)
    vim.cmd("copen")
    vim.notify(string.format("🐳 %d issue(s)", #qflist), vim.log.levels.WARN,
      { title = "hadolint" })
  else
    vim.notify("🐳 ✅ No issues", vim.log.levels.INFO,
      { title = "hadolint", timeout = 1500 })
  end
end, "Lint (hadolint)")

-- ── Build ─────────────────────────────────────────────────────────────────────
map("n", "<leader>dkb", function()
  local default_tag = get_image_tag()
  vim.ui.input(
    { prompt = "🐳 Image tag: ", default = default_tag },
    function(tag)
      if not tag or tag == "" then return end
      local file = vim.api.nvim_buf_get_name(buf)
      run_cmd(
        "docker build -t " .. vim.fn.shellescape(tag)
          .. " -f " .. vim.fn.shellescape(file)
          .. " " .. vim.fn.shellescape(vim.fn.getcwd()),
        "build: " .. tag
      )
    end
  )
end, "docker build")

map("n", "<leader>dkB", function()
  -- Build specific stage
  local stages = get_stages()
  if #stages == 0 then
    vim.notify("🐳 No multi-stage targets found", vim.log.levels.INFO,
      { title = "Docker" })
    return
  end

  vim.ui.select(stages, { prompt = "🐳 Build target: " }, function(stage)
    if not stage then return end
    local default_tag = get_image_tag():gsub(":.*", ":" .. stage)
    vim.ui.input({ prompt = "🐳 Tag: ", default = default_tag }, function(tag)
      if not tag then return end
      local file = vim.api.nvim_buf_get_name(buf)
      run_cmd(
        "docker build --target=" .. stage
          .. " -t " .. vim.fn.shellescape(tag)
          .. " -f " .. vim.fn.shellescape(file)
          .. " " .. vim.fn.shellescape(vim.fn.getcwd()),
        "build target: " .. stage
      )
    end)
  end)
end, "docker build (target stage)")

-- ── Compose ───────────────────────────────────────────────────────────────────
map("n", "<leader>dku", function()
  run_cmd("docker compose up --build", "compose up")
end, "docker compose up")

map("n", "<leader>dkd", function()
  run_cmd("docker compose down", "compose down")
end, "docker compose down")

map("n", "<leader>dkU", function()
  run_cmd("docker compose up --build -d", "compose up -d")
end, "docker compose up (detached)")

map("n", "<leader>dkr", function()
  run_cmd("docker compose restart", "compose restart")
end, "docker compose restart")

map("n", "<leader>dkp", function()
  run_cmd("docker compose pull", "compose pull")
end, "docker compose pull")

map("n", "<leader>dkl", function()
  -- Show logs for a service
  local services = vim.fn.systemlist(
    "docker compose config --services 2>/dev/null"
  )
  if #services == 0 then
    run_cmd("docker compose logs -f", "compose logs")
    return
  end

  table.insert(services, 1, "(all services)")
  vim.ui.select(services, { prompt = "🐳 Service logs: " }, function(svc, idx)
    if not svc then return end
    if idx == 1 then
      run_cmd("docker compose logs -f", "compose logs")
    else
      run_cmd("docker compose logs -f " .. svc, "logs: " .. svc)
    end
  end)
end, "docker compose logs")

-- ── Exec into container ───────────────────────────────────────────────────────
map("n", "<leader>dkx", function()
  local containers = vim.fn.systemlist(
    "docker ps --format '{{.Names}}' 2>/dev/null"
  )
  if #containers == 0 then
    vim.notify("🐳 No running containers", vim.log.levels.INFO, { title = "Docker" })
    return
  end

  vim.ui.select(containers, { prompt = "🐳 Exec into: " }, function(ctr)
    if ctr then
      run_cmd("docker exec -it " .. ctr .. " /bin/sh", "exec: " .. ctr)
    end
  end)
end, "docker exec")

-- ── Security scan ─────────────────────────────────────────────────────────────
map("n", "<leader>dks", function()
  local tag = get_image_tag()
  if vim.fn.executable("trivy") == 1 then
    run_cmd("trivy image " .. vim.fn.shellescape(tag), "trivy scan")
  elseif vim.fn.executable("docker") == 1 then
    run_cmd("docker scout cves " .. vim.fn.shellescape(tag), "docker scout")
  else
    vim.notify("🐳 Install trivy or docker scout for security scanning",
      vim.log.levels.WARN, { title = "Docker" })
  end
end, "Security scan")

-- ── Dive (layer analysis) ─────────────────────────────────────────────────────
map("n", "<leader>dkD", function()
  if vim.fn.executable("dive") ~= 1 then
    vim.notify("🐳 dive not found (brew install dive)", vim.log.levels.WARN,
      { title = "Docker" })
    return
  end
  local tag = get_image_tag()
  run_cmd("dive " .. vim.fn.shellescape(tag), "dive: " .. tag)
end, "Dive layer analysis")

-- ── Insert snippets ───────────────────────────────────────────────────────────
map("n", "<leader>dkhc", function()
  -- Insert HEALTHCHECK instruction
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    "",
    "HEALTHCHECK \\",
    "    --interval=30s \\",
    "    --timeout=5s \\",
    "    --start-period=10s \\",
    "    --retries=3 \\",
    "  CMD [\"curl\", \"-f\", \"http://localhost:8080/health\"]",
    "",
  })
end, "Insert HEALTHCHECK")

map("n", "<leader>dkol", function()
  -- Insert OCI labels
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(buf, row, row, false, {
    "",
    "LABEL \\",
    '    org.opencontainers.image.title="" \\',
    '    org.opencontainers.image.description="" \\',
    '    org.opencontainers.image.version="${VERSION}" \\',
    '    org.opencontainers.image.created="${BUILD_DATE}" \\',
    '    org.opencontainers.image.revision="${GIT_SHA}" \\',
    '    org.opencontainers.image.source="" \\',
    '    org.opencontainers.image.licenses="MIT"',
    "",
  })
end, "Insert OCI labels")

-- ── Info ─────────────────────────────────────────────────────────────────────
map("n", "<leader>dki", function()
  local docker_v  = vim.fn.trim(vim.fn.system("docker --version 2>/dev/null"))
  local compose_v = vim.fn.trim(vim.fn.system("docker compose version 2>/dev/null"))
  local stages    = get_stages()

  vim.notify(
    table.concat({
      "🐳 Docker Info",
      "──────────────────────────────────",
      string.format("  Filetype:  %s", ft),
      string.format("  Docker:    %s", docker_v),
      string.format("  Compose:   %s", compose_v),
      string.format("  Stages:    %s",
        #stages > 0 and table.concat(stages, ", ") or "(single-stage)"),
      string.format("  hadolint:  %s", vim.fn.executable("hadolint") == 1 and "✅" or "⭕"),
      string.format("  dive:      %s", vim.fn.executable("dive")      == 1 and "✅" or "⭕"),
      string.format("  trivy:     %s", vim.fn.executable("trivy")     == 1 and "✅" or "⭕"),
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Docker" }
  )
end, "Environment info")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🏥 AUTOCMDS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local aug = vim.api.nvim_create_augroup("AshFtDockerfile_" .. buf, { clear = true })

-- Lint on save
vim.api.nvim_create_autocmd("BufWritePost", {
  group  = aug,
  buffer = buf,
  callback = function()
    if vim.fn.executable("hadolint") ~= 1 then return end
    local file   = vim.api.nvim_buf_get_name(buf)
    local result = vim.fn.system(
      "hadolint --format=json " .. vim.fn.shellescape(file) .. " 2>&1"
    )
    if vim.v.shell_error ~= 0 and result ~= "" then
      local ok, data = pcall(vim.fn.json_decode, result)
      if ok and #(data or {}) > 0 and vim.g.ash_debug then
        vim.notify(
          string.format("🐳 %d hadolint issue(s) — run <leader>dkl to view", #data),
          vim.log.levels.DEBUG,
          { title = "Docker" }
        )
      end
    end
  end,
})