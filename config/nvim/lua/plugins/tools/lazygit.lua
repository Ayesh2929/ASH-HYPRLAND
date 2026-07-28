-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       󰊢 LAZYGIT — ULTRA GIT TUI v5.0 OMEGA                                    ║
-- ║   Full git workflow · floating terminal · custom config · branch browser       ║
-- ║   commit navigator · diff viewer · stash · ASH theme-synced                   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    hl(0, "LazyGitFloat",         { link = "NormalFloat"    })
    hl(0, "LazyGitBorder",        { link = "FloatBorder"    })
    hl(0, "LazyGitTitle",         { bold = true, fg = "#7aa2f7" })
    hl(0, "LazyGitUnstaged",      { bold = true, fg = "#f9e2af" })
    hl(0, "LazyGitStaged",        { bold = true, fg = "#9ece6a" })
    hl(0, "LazyGitUntracked",     { fg = "#9399b2"              })
    hl(0, "LazyGitModified",      { fg = "#f9e2af"              })
    hl(0, "LazyGitDeleted",       { fg = "#f38ba8"              })
    hl(0, "LazyGitConflict",      { bold = true, fg = "#f38ba8" })
  
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then hl(0, "LazyGitTitle",    { bold = true, fg = p.blue   }) end
      if p.yellow then hl(0, "LazyGitUnstaged", { bold = true, fg = p.yellow }) end
      if p.green  then hl(0, "LazyGitStaged",   { bold = true, fg = p.green  }) end
      if p.red    then
        hl(0, "LazyGitDeleted",  { fg = p.red })
        hl(0, "LazyGitConflict", { bold = true, fg = p.red })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 LAZYGIT UTILITIES
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Find git root from current buffer
  local function get_git_root()
    local file = vim.api.nvim_buf_get_name(0)
    local dir  = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
    local root  = vim.fn.trim(
      vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")
    )
    return vim.v.shell_error == 0 and root or vim.fn.getcwd()
  end
  
  -- Generate ASH-themed lazygit config
  local function write_lazygit_config()
    local config_dir  = vim.fn.stdpath("data") .. "/lazygit"
    local config_file = config_dir .. "/config.yml"
  
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
    end
  
    -- Read ASH palette
    local ok, ash = pcall(require, "ash.theme")
    local palette  = ok and ash.palette or {}
  
    local blue    = palette.blue    or "#7aa2f7"
    local green   = palette.green   or "#9ece6a"
    local red     = palette.red     or "#f38ba8"
    local yellow  = palette.yellow  or "#f9e2af"
    local mauve   = palette.mauve   or "#cba6f7"
    local surface = palette.surface0 or "#1e2030"
    local base    = palette.base    or "#1a1b26"
    local text    = palette.text    or "#cdd6f4"
    local overlay = palette.overlay0 or "#6e738d"
  
    local config = string.format([[
  # ASH OMEGA v5.0 — lazygit theme (auto-generated)
  gui:
    windowSize: "normal"
    returnImmediately: false
    mouseEvents: true
    skipDiscardChangeWarning: false
    skipStashWarning: false
    showFileTree: true
    showListFooter: true
    showRandomTip: false
    showBranchCommitHash: true
    showBottomLine: true
    showCommandLog: true
    commandLogSize: 8
    splitDiff: "auto"
    skipRewordInEditorWarning: false
    border: "rounded"
    animateExplosion: false
    portraitMode: "auto"
    filterMode: "substring"
    scrollHeight: 3
    scrollPastBottom: true
    sidePanelWidth: 0.3333
    expandFocusedSidePanel: false
    mainPanelSplitMode: "flexible"
    enlargedSideViewLocation: "left"
    nerdFontsVersion: "3"
    showAheadBehindCountInBranches: true
    showDivergenceFromBaseBranch: "arrowAndNumber"
    commitHashLength: 8
    showFileIcons: true
    showAuthorIcon: true
    theme:
      activeBorderColor:
        - "%s"
        - bold
      inactiveBorderColor:
        - "%s"
      searchingActiveBorderColor:
        - "%s"
        - bold
      optionsTextColor:
        - "%s"
      selectedLineBgColor:
        - "%s"
      cherryPickedCommitFgColor:
        - "%s"
      cherryPickedCommitBgColor:
        - "%s"
      markedBaseCommitFgColor:
        - "%s"
      markedBaseCommitBgColor:
        - "%s"
      unstagedChangesColor:
        - "%s"
      defaultFgColor:
        - "%s"
  git:
    paging:
      colorArg: always
      useConfig: false
      pager: "delta --dark --paging=never --features=line-numbers --syntax-theme=Catppuccin-mocha"
    commit:
      signOff: false
      autoWrapCommitMessage: true
      autoWrapWidth: 72
    merging:
      manualCommit: false
      args: ""
    log:
      order: "topo-order"
      showGraph: "always"
      showWholeGraph: false
    skipHookPrefix: WIP
    autoFetch: true
    autoRefresh: true
    fetchAll: true
    branchLogCmd: "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --"
    allBranchesLogCmd: "git log --graph --all --color=always --abbrev-commit --decorate --date=relative --pretty=medium"
    overrideGpg: false
    disableForcePushing: false
    parseEmoji: true
    diffContextSize: 5
    truncateCopiedCommitSubjectsTo: 50
    mainBranch:
      - master
      - main
      - dev
      - develop
  keybinding:
    universal:
      quit: "q"
      quit-alt1: "<c-c>"
      return: "<esc>"
      quitWithoutChangingDirectory: "Q"
      togglePanel: "<tab>"
      prevItem: "<up>"
      nextItem: "<down>"
      prevItem-alt: "k"
      nextItem-alt: "j"
      prevPage: ","
      nextPage: "."
      gotoTop: "<"
      gotoBottom: ">"
      scrollLeft: "H"
      scrollRight: "L"
      prevBlock: "<left>"
      nextBlock: "<right>"
      prevBlock-alt: "h"
      nextBlock-alt: "l"
      jumpToBlock: ["1", "2", "3", "4", "5"]
      nextMatch: "n"
      prevMatch: "N"
      optionMenu: "x"
      optionMenu-alt1: "?"
      select: "<space>"
      goInto: "<enter>"
      confirm: "<enter>"
      confirmInEditor: "<a-enter>"
      remove: "d"
      new: "n"
      edit: "e"
      openFile: "o"
      scrollUpMain: "<pgup>"
      scrollDownMain: "<pgdn>"
      scrollUpMain-alt1: "K"
      scrollDownMain-alt1: "J"
      executeShellCommand: ":"
      createRebaseOptionsMenu: "m"
      pushFiles: "P"
      pullFiles: "p"
      refresh: "R"
      createPatchOptionsMenu: "<c-p>"
      nextTab: "]"
      prevTab: "["
      nextScreenMode: "+"
      prevScreenMode: "_"
      undo: "z"
      redo: "<c-z>"
      filteringMenu: "<c-s>"
      diffingMenu: "W"
      diffingMenu-alt: "<c-e>"
      copyToClipboard: "<c-o>"
      openRecentRepos: "<c-r>"
      submitEditorText: "<enter>"
      extrasMenu: "@"
      toggleWhitespaceInDiffView: "<c-w>"
      increaseContextInDiffView: "}"
      decreaseContextInDiffView: "{"
  notARepository: "skip"
  promptToReturnFromSubprocess: true
  os:
    editPreset: "nvim"
    editCommand: ""
    editCommandTemplate: ""
    openCommand: ""
    openLinkCommand: ""
    copyToClipboardCmd: "xclip -selection clipboard"
    readFromClipboardCmd: "xclip -selection clipboard -o"
  update:
    method: "prompt"
    days: 14
  confirmOnQuit: false
  quitOnTopLevelReturn: false
  disableStartupPopups: true
  customCommands:
    - key: "<c-f>"
      command: "git fetch --all --prune"
      context: "global"
      description: "Fetch all remotes"
      loadingText: "Fetching…"
    - key: "C"
      command: "git checkout {{.SelectedRemoteBranch.Name | cutPrefix \"origin/\"}}"
      context: "remotesBranches"
      description: "Checkout remote branch locally"
    - key: "<c-b>"
      command: "git checkout -b {{.Form.BranchName}}"
      context: "global"
      description: "Create branch from prompt"
      prompts:
        - type: "input"
          key: "BranchName"
          title: "Branch name"
          initialValue: ""
    - key: "W"
      command: "git diff {{.SelectedLocalCommit.Sha}} -- . | delta --paging=always"
      context: "commits"
      description: "Full diff with delta"
      subprocess: true
  ]], blue, overlay, green, blue, surface, green, surface, yellow, surface,
      yellow, text)
  
    local f = io.open(config_file, "w")
    if f then
      f:write(config)
      f:close()
    end
  
    return config_file
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "kdheepak/lazygit.nvim",
      cmd          = {
        "LazyGit",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
        "LazyGitConfig",
      },
      dependencies = { "nvim-lua/plenary.nvim" },
  
      keys = {
        {
          "<leader>gg",
          function()
            local root = get_git_root()
            vim.cmd("LazyGit dir=" .. root)
          end,
          desc   = "󰊢 LazyGit: Open (git root)",
          silent = true,
        },
        {
          "<leader>gG",
          "<cmd>LazyGitCurrentFile<cr>",
          desc   = "󰊢 LazyGit: Current file",
          silent = true,
        },
        {
          "<leader>gL",
          function()
            local root = get_git_root()
            vim.cmd("LazyGitFilter dir=" .. root)
          end,
          desc   = "󰊢 LazyGit: Log (filter)",
          silent = true,
        },
        {
          "<leader>gl",
          "<cmd>LazyGitFilterCurrentFile<cr>",
          desc   = "󰊢 LazyGit: Log (current file)",
          silent = true,
        },
        {
          "<leader>gK",
          function()
            -- Regenerate config with current ASH theme
            local cfg = write_lazygit_config()
            vim.notify(
              "󰊢 LazyGit config regenerated:\n" .. cfg,
              vim.log.levels.INFO,
              { title = "LazyGit", timeout = 1500 }
            )
          end,
          desc   = "󰊢 LazyGit: Regenerate config",
          silent = true,
        },
      },
  
      init = function()
        -- Set lazygit config path to our managed one
        local config_file = write_lazygit_config()
        vim.g.lazygit_config_file_path = config_file
  
        -- Float window size
        vim.g.lazygit_floating_window_winblend  = 0
        vim.g.lazygit_floating_window_scaling_factor = 0.92
        vim.g.lazygit_floating_window_border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
        vim.g.lazygit_floating_window_use_plenary = 1
        vim.g.lazygit_use_neovim_remote          = 1
        vim.g.lazygit_use_custom_config_file_path= 1
      end,
  
      config = function()
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshLazyGit", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            -- Regenerate lazygit config with new palette
            write_lazygit_config()
            vim.notify("󰊢 LazyGit config synced with ASH theme", vim.log.levels.INFO,
              { title = "ASH LazyGit", timeout = 1200 })
          end,
        })
  
        -- Disable unwanted plugins inside lazygit terminal buffer
        vim.api.nvim_create_autocmd("TermOpen", {
          group   = aug,
          pattern = "*lazygit*",
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
            vim.opt_local.number         = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn     = "no"
          end,
        })
      end,
    },
  }