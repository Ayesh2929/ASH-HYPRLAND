-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📁 PROJECT.NVIM — ULTRA PROJECT MANAGER v5.0 OMEGA                      ║
-- ║   Auto-detect · session · recent · Telescope · LSP root · patterns            ║
-- ║   manual config · per-project settings · ASH theme-synced                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "ProjectNvimTitle",      { bold = true, fg = "#7aa2f7" })
    hl(0, "ProjectNvimPath",       { italic = true, fg = "#9399b2" })
    hl(0, "ProjectNvimRecent",     { fg = "#9ece6a"               })
    hl(0, "ProjectNvimGitRoot",    { bold = true, fg = "#f9e2af"  })
    hl(0, "ProjectNvimLspRoot",    { bold = true, fg = "#89b4fa"  })
    hl(0, "ProjectNvimPattern",    { bold = true, fg = "#cba6f7"  })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "ProjectNvimTitle",   { bold = true, fg = p.blue   }) end
      if p.yellow then hl(0, "ProjectNvimGitRoot",  { bold = true, fg = p.yellow }) end
      if p.green  then hl(0, "ProjectNvimRecent",   { fg = p.green               }) end
      if p.mauve  then hl(0, "ProjectNvimPattern",  { bold = true, fg = p.mauve  }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 PROJECT UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Smart project open via Telescope
  local function telescope_projects()
    local ok, tele = pcall(require, "telescope")
    if ok and tele.extensions and tele.extensions.projects then
      tele.extensions.projects.projects({
        prompt_title = "📁 Projects",
      })
    else
      -- Fallback: use project_nvim directly
      local ok2, project = pcall(require, "project_nvim.project")
      if not ok2 then return end
  
      local recent = project.get_recent_projects()
      if #recent == 0 then
        vim.notify("📁 No recent projects", vim.log.levels.INFO, { title = "Project" })
        return
      end
  
      vim.ui.select(
        recent,
        {
          prompt = "📁 Recent projects: ",
          format_item = function(p)
            return vim.fn.fnamemodify(p, ":~")
          end,
        },
        function(selected)
          if selected then
            vim.cmd("cd " .. vim.fn.fnameescape(selected))
            vim.notify("📁 " .. vim.fn.fnamemodify(selected, ":t"),
              vim.log.levels.INFO, { title = "Project", timeout = 1200 })
          end
        end
      )
    end
  end
  
  -- Get current project info
  local function get_project_info()
    local ok, project = pcall(require, "project_nvim.project")
    if not ok then return nil end
  
    local root, method = project.get_project_root()
    if not root then return nil end
  
    return {
      root   = root,
      method = method or "unknown",
      name   = vim.fn.fnamemodify(root, ":t"),
      rel    = vim.fn.fnamemodify(root, ":~"),
    }
  end
  
  -- Show project status
  local function show_project_status()
    local info = get_project_info()
    if not info then
      vim.notify("📁 Not in a project", vim.log.levels.WARN, { title = "Project" })
      return
    end
  
    local git_branch = vim.fn.trim(vim.fn.system("git -C " .. vim.fn.shellescape(info.root) .. " branch --show-current 2>/dev/null"))
    local git_status = vim.fn.trim(vim.fn.system("git -C " .. vim.fn.shellescape(info.root) .. " status --porcelain 2>/dev/null | wc -l"))
  
    vim.notify(
      table.concat({
        "📁 Project: " .. info.name,
        "──────────────────────────────────",
        string.format("  Root:    %s", info.rel),
        string.format("  Method:  %s", info.method),
        string.format("  Branch:  %s", git_branch ~= "" and git_branch or "(no git)"),
        string.format("  Changes: %s file(s)", vim.fn.trim(git_status)),
      }, "\n"),
      vim.log.levels.INFO,
      { title = "Project" }
    )
  end
  
  -- Per-project settings: load .nvim.lua from project root
  local function load_project_config()
    local info = get_project_info()
    if not info then return end
  
    local nvim_config = info.root .. "/.nvim.lua"
    if vim.fn.filereadable(nvim_config) == 1 then
      local ok, err = pcall(dofile, nvim_config)
      if ok then
        if vim.g.ash_debug then
          vim.notify("📁 Loaded .nvim.lua from " .. info.name, vim.log.levels.DEBUG,
            { title = "Project" })
        end
      else
        vim.notify("📁 Error in .nvim.lua: " .. tostring(err), vim.log.levels.WARN,
          { title = "Project" })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "ahmedkhalf/project.nvim",
      event  = "VeryLazy",
  
      keys = {
        { "<leader>fp",  telescope_projects,  desc = "📁 Projects: Open picker"   },
        { "<leader>fP",  show_project_status, desc = "📁 Projects: Current info"  },
        {
          "<leader>fpc",
          function()
            local info = get_project_info()
            if info then
              vim.cmd("cd " .. vim.fn.fnameescape(info.root))
              vim.notify("📁 CWD → " .. info.name, vim.log.levels.INFO,
                { title = "Project", timeout = 1200 })
            end
          end,
          desc = "📁 Projects: CD to root",
        },
        {
          "<leader>fpn",
          function()
            local info = get_project_info()
            if not info then return end
            local nvim_cfg = info.root .. "/.nvim.lua"
            if vim.fn.filereadable(nvim_cfg) == 0 then
              local f = io.open(nvim_cfg, "w")
              if f then
                f:write(table.concat({
                  "-- 📁 Project-local Neovim config: " .. info.name,
                  "-- This file is loaded automatically when you open this project.",
                  "",
                  "-- Example: set project-specific settings",
                  "-- vim.opt_local.colorcolumn = '120'",
                  "",
                  "-- Example: define project-specific keymaps",
                  "-- vim.keymap.set('n', '<leader>r', '<cmd>!make run<cr>', { desc = 'Run' })",
                  "",
                  "-- Example: set LSP config",
                  "-- vim.g.lsp_extra_args = { '--flag' }",
                  "",
                }, "\n"))
                f:close()
              end
            end
            vim.cmd("edit " .. nvim_cfg)
          end,
          desc = "📁 Projects: Edit .nvim.lua",
        },
        {
          "<leader>fpl",
          load_project_config,
          desc = "📁 Projects: Load .nvim.lua",
        },
      },
  
      opts = {
        -- ── Detection methods ─────────────────────────────────────────────────
        detection_methods   = { "lsp", "pattern" },
  
        -- ── Pattern files (triggers project root detection) ────────────────────
        patterns            = {
          -- VCS
          ".git",    ".hg",  ".svn",  ".bzr",
          -- Build systems
          "Makefile", "Justfile", "CMakeLists.txt",
          "Cargo.toml", "go.mod", "package.json",
          "pyproject.toml", "setup.py", "setup.cfg",
          "build.gradle", "pom.xml",
          "flake.nix", "default.nix",
          "build.zig",
          -- Editor
          ".nvim.lua", ".nvimrc", ".editorconfig",
          -- CI
          ".github", ".gitlab-ci.yml", ".drone.yml",
          -- Docker
          "docker-compose.yml", "Dockerfile",
          -- Config
          ".envrc",
        },
  
        -- ── LSP detection ─────────────────────────────────────────────────────
        -- Detect project root from active LSP clients
        ignore_lsp          = {
          -- These LSP servers report roots that are too broad
          "efm",
          "null-ls",
          "copilot",
          "codeium",
        },
  
        -- ── Exclusions ────────────────────────────────────────────────────────
        exclude_dirs        = {
          vim.env.HOME .. "/.cargo",
          vim.env.HOME .. "/.go",
          vim.env.HOME .. "/.cache",
          vim.env.HOME .. "/.local",
          "/tmp",
          "/usr",
          "/etc",
          "/opt",
        },
  
        -- ── Show hidden folders in picker ─────────────────────────────────────
        show_hidden         = false,
  
        -- ── Scope (global = all projects / local = cwd) ────────────────────────
        scope_chdir         = "global",
  
        -- ── Path style ────────────────────────────────────────────────────────
        -- "history" = remember recent projects
        data_path           = vim.fn.stdpath("data") .. "/project_nvim",
  
        -- ── Silent chdir ──────────────────────────────────────────────────────
        silent_chdir        = true,
  
        -- ── Update cwd on BufEnter ────────────────────────────────────────────
        manual_mode         = false,
      },
  
      config = function(_, opts)
        require("project_nvim").setup(opts)
  
        -- Load Telescope extension
        local ok_tele, tele = pcall(require, "telescope")
        if ok_tele then
          pcall(tele.load_extension, "projects")
        end
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshProject", { clear = true })
  
        -- Auto-load .nvim.lua when changing projects
        vim.api.nvim_create_autocmd("DirChanged", {
          group    = aug,
          callback = function()
            -- Defer to let project_nvim settle the root
            vim.defer_fn(load_project_config, 100)
          end,
        })
  
        -- Load config for initial project on startup
        vim.defer_fn(function()
          load_project_config()
        end, 500)
  
        -- Expose current project for statusline
        _G.AshProjectName = function()
          local info = get_project_info()
          return info and (" 📁 " .. info.name .. " ") or ""
        end
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📁 Project highlights synced", vim.log.levels.INFO,
              { title = "ASH Project", timeout = 1200 })
          end,
        })
  
        if vim.g.ash_debug then
          local info = get_project_info()
          vim.notify(
            string.format("📁 project.nvim loaded — project: %s",
              info and info.name or "(none)"),
            vim.log.levels.DEBUG,
            { title = "ASH Project" }
          )
        end
      end,
    },
  }