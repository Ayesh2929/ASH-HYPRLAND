-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🐳 DOCKER — ULTRA LANGUAGE SUPPORT v5.0 OMEGA                            ║
-- ║   dockerfile-ls · docker-compose-ls · hadolint · dive · buildkit              ║
-- ║   layer analysis · compose services · ASH theme-synced                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Dockerfile instructions ────────────────────────────────────────────────
    hl(0, "@keyword.dockerfile",           { bold = true,   fg = "#7aa2f7" })
    hl(0, "@string.dockerfile",            { fg = "#a6e3a1"                })
    hl(0, "@variable.dockerfile",          { fg = "#cba6f7"                })
    hl(0, "@number.dockerfile",            { fg = "#fab387"                })
    hl(0, "@comment.dockerfile",           { italic = true, fg = "#9399b2" })
    hl(0, "@type.dockerfile",              { bold = true,   fg = "#f9e2af" })
    hl(0, "@function.dockerfile",          { fg = "#89b4fa"                })
    hl(0, "@constant.dockerfile",          { bold = true,   fg = "#fab387" })
    hl(0, "@operator.dockerfile",          { fg = "#89b4fa"                })
  
    -- ── LSP tokens ────────────────────────────────────────────────────────────
    hl(0, "DockerfileFrom",                { bold = true,   fg = "#7aa2f7" })
    hl(0, "DockerfileInstruction",         { bold = true,   fg = "#7aa2f7" })
    hl(0, "DockerfileArg",                 { bold = true,   fg = "#cba6f7" })
    hl(0, "DockerfileEnv",                 { bold = true,   fg = "#9ece6a" })
    hl(0, "DockerfileLabel",               { italic = true, fg = "#94e2d5" })
    hl(0, "DockerfileExpose",              { bold = true,   fg = "#f9e2af" })
    hl(0, "DockerfileVolume",              { fg = "#fab387"                })
    hl(0, "DockerfileUser",                { bold = true,   fg = "#f38ba8" })
    hl(0, "DockerfileHealthcheck",         { bold = true,   fg = "#9ece6a" })
    hl(0, "DockerfileStage",               { bold = true, italic = true, fg = "#f9e2af" })
  
    -- ── Docker Compose ────────────────────────────────────────────────────────
    hl(0, "DockerComposeService",          { bold = true,   fg = "#7aa2f7" })
    hl(0, "DockerComposeImage",            { italic = true, fg = "#a6e3a1" })
    hl(0, "DockerComposeBuild",            { fg = "#f9e2af"                })
    hl(0, "DockerComposePorts",            { bold = true,   fg = "#fab387" })
    hl(0, "DockerComposeVolumes",          { fg = "#94e2d5"                })
    hl(0, "DockerComposeNetworks",         { fg = "#cba6f7"                })
    hl(0, "DockerComposeHealthcheck",      { fg = "#9ece6a"                })
    hl(0, "DockerComposeDependsOn",        { italic = true, fg = "#9399b2" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@keyword.dockerfile",    { bold = true, fg = p.blue })
        hl(0, "DockerfileInstruction",  { bold = true, fg = p.blue })
        hl(0, "DockerfileFrom",         { bold = true, fg = p.blue })
        hl(0, "DockerComposeService",   { bold = true, fg = p.blue })
      end
      if p.mauve  then
        hl(0, "@variable.dockerfile",   { fg = p.mauve })
        hl(0, "DockerfileArg",          { bold = true, fg = p.mauve })
      end
      if p.green  then
        hl(0, "@string.dockerfile",     { fg = p.green })
        hl(0, "DockerfileEnv",          { bold = true, fg = p.green })
        hl(0, "DockerfileHealthcheck",  { bold = true, fg = p.green })
      end
      if p.yellow then
        hl(0, "DockerfileStage",        { bold = true, italic = true, fg = p.yellow })
        hl(0, "DockerfileExpose",       { bold = true, fg = p.yellow })
      end
      if p.red    then hl(0, "DockerfileUser", { bold = true, fg = p.red }) end
      local dim = p.overlay0 or "#9399b2"
      hl(0, "@comment.dockerfile",      { italic = true, fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 DOCKER UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function run_docker(cmd, title)
    local ok_term, term = pcall(require, "toggleterm.terminal")
    if ok_term then
      term.Terminal:new({
        cmd          = cmd,
        direction    = "float",
        display_name = "🐳 " .. (title or cmd:match("^%S+")),
        float_opts   = { border = "rounded" },
        close_on_exit = false,
      }):toggle()
    else
      vim.cmd("split term://" .. cmd)
    end
  end
  
  local function get_compose_services()
    local result = vim.fn.systemlist(
      "docker compose config --services 2>/dev/null || docker-compose config --services 2>/dev/null"
    )
    return vim.v.shell_error == 0 and result or {}
  end
  
  local function get_running_containers()
    local result = vim.fn.systemlist(
      "docker ps --format '{{.Names}}' 2>/dev/null"
    )
    return vim.v.shell_error == 0 and result or {}
  end
  
  -- Lint Dockerfile with hadolint
  local function lint_dockerfile()
    if vim.fn.executable("hadolint") ~= 1 then
      vim.notify("🐳 hadolint not found — install via Mason", vim.log.levels.WARN,
        { title = "Docker" })
      return
    end
  
    local file   = vim.api.nvim_buf_get_name(0)
    local result = vim.fn.systemlist(
      "hadolint --format=json " .. vim.fn.shellescape(file) .. " 2>&1"
    )
  
    if vim.v.shell_error == 0 then
      vim.notify("🐳 ✅ Dockerfile OK", vim.log.levels.INFO,
        { title = "hadolint", timeout = 1500 })
      return
    end
  
    local qflist = {}
    for _, line in ipairs(result) do
      local ok_j, item = pcall(vim.fn.json_decode, line)
      if ok_j and item then
        table.insert(qflist, {
          filename = item.file or file,
          lnum     = item.line or 1,
          col      = item.column or 1,
          type     = item.level == "error" and "E" or "W",
          text     = string.format("[%s] %s", item.code or "", item.message or ""),
        })
      end
    end
  
    if #qflist > 0 then
      vim.fn.setqflist(qflist)
      vim.cmd("copen")
      vim.notify(string.format("🐳 %d issue(s) found", #qflist), vim.log.levels.WARN,
        { title = "hadolint" })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, { "dockerfile" })
      end,
    },
  
    {
      "neovim/nvim-lspconfig",
      ft   = { "dockerfile" },
      opts = {
        servers = {
          dockerls = {
            on_attach = function(client, bufnr)
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            settings = {
              docker = {
                languageserver = {
                  formatter          = { ignoreMultilineInstructions = true },
                  diagnostics        = {
                    deprecated       = "warning",
                    directiveCasing  = "warning",
                    emptyContinuationLine = "warning",
                    instructionCasing= "warning",
                    invalidEscapeDirective = "error",
                    invalidPort      = "error",
                    invalidWorkdir   = "error",
                    missingAs        = "error",
                    noSourceImage    = "warning",
                    stagesNotFound   = "error",
                    unexpectedArgument = "error",
                    unknownInstruction = "error",
                  },
                },
              },
            },
          },
          docker_compose_language_service = {
            on_attach = function(client, bufnr)
              local global = _G.AshLspOnAttach
              if global then global(client, bufnr) end
            end,
            filetypes = { "yaml.docker-compose" },
            root_dir  = require("lspconfig.util").root_pattern(
              "docker-compose.yml", "docker-compose.yaml",
              "compose.yml", "compose.yaml"
            ),
          },
        },
      },
    },
  
    {
      "nvim-lua/plenary.nvim",
      ft = { "dockerfile" },
  
      keys = {
        -- ── Dockerfile ────────────────────────────────────────────────────────
        {
          "<leader>dkl",
          lint_dockerfile,
          ft   = "dockerfile",
          desc = "🐳 Docker: Lint (hadolint)",
        },
        {
          "<leader>dkb",
          function()
            local file = vim.api.nvim_buf_get_name(0)
            local tag  = vim.fn.input("Image tag: ", "myapp:latest")
            if tag == "" then return end
            run_docker("docker build -t " .. tag .. " -f " .. vim.fn.shellescape(file)
              .. " " .. vim.fn.getcwd(), "docker build")
          end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Build image",
        },
        -- ── Docker Compose ────────────────────────────────────────────────────
        {
          "<leader>dku",
          function() run_docker("docker compose up --build", "compose up") end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Compose up",
        },
        {
          "<leader>dkd",
          function() run_docker("docker compose down", "compose down") end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Compose down",
        },
        {
          "<leader>dks",
          function()
            local services = get_compose_services()
            if #services == 0 then
              vim.notify("🐳 No compose services found", vim.log.levels.WARN,
                { title = "Docker" })
              return
            end
            vim.ui.select(services, { prompt = "🐳 Service logs: " }, function(svc)
              if svc then run_docker("docker compose logs -f " .. svc, "logs: " .. svc) end
            end)
          end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Compose service logs",
        },
        {
          "<leader>dkx",
          function()
            local containers = get_running_containers()
            if #containers == 0 then
              vim.notify("🐳 No running containers", vim.log.levels.INFO,
                { title = "Docker" })
              return
            end
            vim.ui.select(containers, { prompt = "🐳 Exec into: " }, function(ctr)
              if ctr then run_docker("docker exec -it " .. ctr .. " /bin/sh", "exec: " .. ctr) end
            end)
          end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Exec into container",
        },
        {
          "<leader>dki",
          function()
            local docker_v  = vim.fn.trim(vim.fn.system("docker --version 2>/dev/null"))
            local compose_v = vim.fn.trim(vim.fn.system("docker compose version 2>/dev/null"))
            local ctrs      = get_running_containers()
            vim.notify(
              table.concat({
                "🐳 Docker Environment",
                "──────────────────────────────────",
                string.format("  Docker:         %s", docker_v),
                string.format("  Compose:        %s", compose_v),
                string.format("  Running:        %d container(s)", #ctrs),
                string.format("  hadolint:       %s", vim.fn.executable("hadolint") == 1 and "✅" or "⭕"),
                string.format("  docker scout:   %s", vim.fn.executable("docker-scout") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Docker Info" }
            )
          end,
          ft   = "dockerfile",
          desc = "🐳 Docker: Environment info",
        },
      },
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDocker", { clear = true })
  
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "dockerfile",
          callback = function()
            vim.opt_local.expandtab   = true
            vim.opt_local.shiftwidth  = 4
            vim.opt_local.tabstop     = 4
            vim.opt_local.softtabstop = 4
            vim.opt_local.spell       = false
          end,
        })
  
        -- docker-compose filetype detection
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
          group   = aug,
          pattern = {
            "docker-compose.yml", "docker-compose.yaml",
            "compose.yml", "compose.yaml",
            "docker-compose.*.yml", "docker-compose.*.yaml",
          },
          callback = function()
            vim.bo.filetype = "yaml.docker-compose"
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🐳 Docker highlights synced", vim.log.levels.INFO,
              { title = "ASH Docker", timeout = 1200 })
          end,
        })
      end,
    },
  }