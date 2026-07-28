-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🌿 NEOGIT — ULTRA GIT PORCELAIN v5.0 OMEGA                               ║
-- ║   Magit-inspired TUI · async operations · diffview integration                  ║
-- ║   commit graph · interactive rebase · stash · remote management                 ║
-- ║   telescope integration · custom signs · ASH theme-synced                      ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — ASH theme-synced
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── General ───────────────────────────────────────────────────────────────
    hl(0, "NeogitNormal",            { link = "Normal"           })
    hl(0, "NeogitCursorLine",        { link = "CursorLine"       })
    hl(0, "NeogitWinSeparator",      { link = "WinSeparator"     })
    hl(0, "NeogitFold",              { link = "Folded"           })
  
    -- ── Section headings ──────────────────────────────────────────────────────
    hl(0, "NeogitSectionHeader",     { bold = true, link = "Title"   })
    hl(0, "NeogitSubSectionHeader",  { bold = true, link = "Keyword" })
    hl(0, "NeogitObjectTy",          { link = "Type"             })
    hl(0, "NeogitStashes",           { bold = true               })
    hl(0, "NeogitStash",             { link = "NeogitSectionHeader" })
  
    -- ── Diff colours ──────────────────────────────────────────────────────────
    hl(0, "NeogitDiffAdd",           { link = "DiffAdd"          })
    hl(0, "NeogitDiffChange",        { link = "DiffChange"       })
    hl(0, "NeogitDiffDelete",        { link = "DiffDelete"       })
    hl(0, "NeogitDiffContext",       { link = "Normal"           })
    hl(0, "NeogitDiffAddHighlight",  { link = "DiffAdd"          })
    hl(0, "NeogitDiffDeleteHighlight",{ link = "DiffDelete"      })
    hl(0, "NeogitDiffContextHighlight",{ link = "CursorLine"     })
    hl(0, "NeogitHunkHeader",        { bold = true, link = "IncSearch"  })
    hl(0, "NeogitHunkHeaderHighlight",{ bold = true, link = "Search"    })
  
    -- ── Inline word diff ──────────────────────────────────────────────────────
    hl(0, "NeogitDiffAddCursor",     { link = "GitSignsAdd"      })
    hl(0, "NeogitDiffDeleteCursor",  { link = "GitSignsDelete"   })
  
    -- ── Commit graph ──────────────────────────────────────────────────────────
    hl(0, "NeogitGraphGray",         { fg = "#9399b2"            })
    hl(0, "NeogitGraphBlack",        { fg = "#1e1e2e"            })
    hl(0, "NeogitGraphWhiteBold",    { bold = true, fg = "#cdd6f4" })
    hl(0, "NeogitGraphRed",          { fg = "#f38ba8"            })
    hl(0, "NeogitGraphWhite",        { fg = "#cdd6f4"            })
    hl(0, "NeogitGraphYellow",       { fg = "#f9e2af"            })
    hl(0, "NeogitGraphGreen",        { fg = "#a6e3a1"            })
    hl(0, "NeogitGraphCyan",         { fg = "#94e2d5"            })
    hl(0, "NeogitGraphBlue",         { fg = "#89b4fa"            })
    hl(0, "NeogitGraphMagenta",      { fg = "#cba6f7"            })
    hl(0, "NeogitGraphOrange",       { fg = "#fab387"            })
  
    -- ── Git status badges ─────────────────────────────────────────────────────
    hl(0, "NeogitUnmergedInto",      { fg = "#fab387", bold = true })
    hl(0, "NeogitUnpulledFrom",      { fg = "#7aa2f7", bold = true })
    hl(0, "NeogitBranch",            { fg = "#89b4fa", bold = true })
    hl(0, "NeogitBranchHead",        { fg = "#a6e3a1", bold = true, underline = true })
    hl(0, "NeogitRemote",            { fg = "#cba6f7", bold = true })
    hl(0, "NeogitTag",               { fg = "#f9e2af", bold = true })
    hl(0, "NeogitHash",              { fg = "#9399b2"              })
    hl(0, "NeogitHashHighlight",     { fg = "#89b4fa"              })
    hl(0, "NeogitCommitViewHeader",  { fg = "#94e2d5", bold = true })
    hl(0, "NeogitSignatureGood",     { fg = "#a6e3a1"              })
    hl(0, "NeogitSignatureBad",      { fg = "#f38ba8"              })
    hl(0, "NeogitSignatureMissing",  { fg = "#f9e2af"              })
    hl(0, "NeogitSignatureNone",     { fg = "#9399b2"              })
    hl(0, "NeogitSignatureExpired",  { fg = "#fab387"              })
    hl(0, "NeogitSignatureRevoked",  { fg = "#f38ba8", bold = true })
    hl(0, "NeogitSignatureError",    { fg = "#f38ba8"              })
  
    -- ── File status ───────────────────────────────────────────────────────────
    hl(0, "NeogitChangeAdded",           { fg = "#a6e3a1", italic = true })
    hl(0, "NeogitChangeBothModified",    { fg = "#f9e2af", italic = true })
    hl(0, "NeogitChangeCopied",          { fg = "#94e2d5", italic = true })
    hl(0, "NeogitChangeDeleted",         { fg = "#f38ba8", italic = true })
    hl(0, "NeogitChangeModified",        { fg = "#7aa2f7", italic = true })
    hl(0, "NeogitChangeNewFile",         { fg = "#a6e3a1", italic = true })
    hl(0, "NeogitChangeRenamed",         { fg = "#7dcfff", italic = true })
    hl(0, "NeogitChangeUpdated",         { fg = "#89b4fa", italic = true })
    hl(0, "NeogitChangeUnmerged",        { fg = "#fab387", italic = true })
    hl(0, "NeogitChangeUnstaged",        { fg = "#9399b2", italic = true })
    hl(0, "NeogitChangeUntracked",       { fg = "#9399b2", italic = true })
    hl(0, "NeogitChangeInvalid",         { fg = "#f38ba8", italic = true })
  
    -- ── Popup / confirmation ─────────────────────────────────────────────────
    hl(0, "NeogitPopupSectionTitle",     { bold = true, link = "Title"   })
    hl(0, "NeogitPopupKeyEnabled",       { fg = "#89b4fa"                })
    hl(0, "NeogitPopupKeyDisabled",      { fg = "#9399b2"                })
    hl(0, "NeogitPopupOptionKey",        { fg = "#cba6f7"                })
    hl(0, "NeogitPopupOptionEnabled",    { fg = "#a6e3a1"                })
    hl(0, "NeogitPopupOptionDisabled",   { fg = "#9399b2"                })
    hl(0, "NeogitPopupSwitchEnabled",    { fg = "#a6e3a1"                })
    hl(0, "NeogitPopupSwitchDisabled",   { fg = "#9399b2"                })
    hl(0, "NeogitPopupSwitchKey",        { fg = "#cba6f7"                })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.green  then hl(0, "NeogitBranchHead",   { fg = p.green,  bold = true, underline = true }) end
      if p.blue   then hl(0, "NeogitBranch",        { fg = p.blue,   bold = true }) end
      if p.mauve  then hl(0, "NeogitRemote",        { fg = p.mauve,  bold = true }) end
      if p.yellow then hl(0, "NeogitTag",           { fg = p.yellow, bold = true }) end
      if p.orange then hl(0, "NeogitUnmergedInto",  { fg = p.orange, bold = true }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "NeogitOrg/neogit",
      version      = false,
      dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",
        { "nvim-telescope/telescope.nvim", optional = true },
        { "ibhagwan/fzf-lua",             optional = true },
      },
      cmd   = "Neogit",
      keys  = {
        -- ── Open Neogit ─────────────────────────────────────────────────────
        {
          "<leader>gg",
          function() require("neogit").open() end,
          desc = "🌿 Neogit",
        },
        {
          "<leader>gG",
          function() require("neogit").open({ cwd = vim.fn.expand("%:p:h") }) end,
          desc = "🌿 Neogit (file dir)",
        },
  
        -- ── Quick actions ────────────────────────────────────────────────────
        {
          "<leader>gc",
          function() require("neogit").open({ "commit" }) end,
          desc = "🌿 Neogit Commit",
        },
        {
          "<leader>gp",
          function() require("neogit").open({ "push" }) end,
          desc = "🌿 Neogit Push",
        },
        {
          "<leader>gf",
          function() require("neogit").open({ "fetch" }) end,
          desc = "🌿 Neogit Fetch",
        },
        {
          "<leader>gl",
          function() require("neogit").open({ "pull" }) end,
          desc = "🌿 Neogit Pull",
        },
        {
          "<leader>gr",
          function() require("neogit").open({ "rebase" }) end,
          desc = "🌿 Neogit Rebase",
        },
        {
          "<leader>gz",
          function() require("neogit").open({ "stash" }) end,
          desc = "🌿 Neogit Stash",
        },
        {
          "<leader>gR",
          function() require("neogit").open({ "remote" }) end,
          desc = "🌿 Neogit Remotes",
        },
        {
          "<leader>gL",
          function() require("neogit").open({ "log" }) end,
          desc = "🌿 Neogit Log",
        },
        {
          "<leader>gB",
          function() require("neogit").open({ "branch" }) end,
          desc = "🌿 Neogit Branches",
        },
        {
          "<leader>gw",
          function() require("neogit").open({ "worktree" }) end,
          desc = "🌿 Neogit Worktrees",
        },
      },
  
      opts = {
        -- ── Verbosity ─────────────────────────────────────────────────────────
        verbose        = false,
  
        -- ── Commit strategy ───────────────────────────────────────────────────
        -- "nvim" | "split" | "split_above" | "tab" | "auto"
        commit_editor  = {
          kind         = "split",
          show_staged_diff = true,
          staged_diff_split_kind = "split",
          spell_check  = true,
        },
  
        -- ── Commit select view ─────────────────────────────────────────────────
        commit_select_view = { kind = "tab" },
  
        -- ── Commit popup ──────────────────────────────────────────────────────
        commit_view = {
          kind        = "vsplit",
          verify_commit = vim.fn.executable("gpg") == 1,
        },
  
        -- ── Log view ──────────────────────────────────────────────────────────
        log_view        = { kind = "tab" },
  
        -- ── Rebase editor ─────────────────────────────────────────────────────
        rebase_editor   = { kind = "auto" },
  
        -- ── Reflog view ───────────────────────────────────────────────────────
        reflog_view     = { kind = "tab" },
  
        -- ── Merge editor ──────────────────────────────────────────────────────
        merge_editor    = { kind = "auto" },
  
        -- ── Tag editor ────────────────────────────────────────────────────────
        tag_editor      = { kind = "auto" },
  
        -- ── Preview buffer ────────────────────────────────────────────────────
        preview_buffer  = { kind = "split" },
  
        -- ── Popup kind ─────────────────────────────────────────────────────────
        popup           = { kind = "split" },
  
        -- ── Signs ─────────────────────────────────────────────────────────────
        signs = {
          -- Hunk header expand/collapse
          hunk        = { "", "" },
          -- Section expand/collapse
          item        = { "▸", "▾" },
          section     = { "▸", "▾" },
        },
  
        -- ── Integrations ──────────────────────────────────────────────────────
        integrations = {
          telescope        = vim.fn.executable("telescope") == 1 or true,
          diffview         = true,
          fzf_lua          = vim.fn.executable("fzf") == 1,
        },
  
        -- ── Sections ──────────────────────────────────────────────────────────
        sections = {
          sequencer       = { folded = false, hidden = false },
          untracked       = { folded = false, hidden = false },
          unstaged        = { folded = false, hidden = false },
          staged          = { folded = false, hidden = false },
          stashes         = { folded = true,  hidden = false },
          unpulled_upstream   = { folded = true,  hidden = false },
          unmerged_upstream   = { folded = false, hidden = false },
          unpulled_pushRemote = { folded = true,  hidden = true  },
          unmerged_pushRemote = { folded = false, hidden = true  },
          recent          = { folded = true,  hidden = false },
          rebase          = { folded = true,  hidden = false },
        },
  
        -- ── Ignored notifications ──────────────────────────────────────────────
        ignored_settings = {
          "NeogitPushPopup--force-with-lease=true",
          "NeogitPushPopup--force=true",
          "NeogitPullPopup--rebase=true",
          "NeogitCommitPopup--allow-empty=true",
          "NeogitRevertPopup--no-edit=true",
        },
  
        -- ── Graph style ────────────────────────────────────────────────────────
        -- "ascii" | "unicode" | "kitty"
        graph_style         = "unicode",
  
        -- ── Git command overrides ──────────────────────────────────────────────
        git_services = {
          ["github.com"]    = "https://github.com/${owner}/${repository}/compare/${branch_name}?expand=1",
          ["bitbucket.org"] = "https://bitbucket.org/${owner}/${repository}/pull-requests/new?source=${branch_name}&t=1",
          ["gitlab.com"]    = "https://gitlab.com/${owner}/${repository}/merge_requests/new?merge_request[source_branch]=${branch_name}",
          ["azure.com"]     = "https://dev.azure.com/${owner}/_git/${repository}/pullrequestcreate?sourceRef=${branch_name}&targetRef=${target}",
        },
  
        -- ── Hooks ─────────────────────────────────────────────────────────────
        -- Run after successful commit
        notification_icon = "🌿",
  
        -- ── Status ─────────────────────────────────────────────────────────────
        status = {
          show_summary_name = true,
          recent_commit_count = 10,
          HEAD_padding     = 10,
          HEAD_folded      = false,
          mode_padding     = 3,
          mode_text        = {
            M  = "modified ",
            N  = "new file ",
            A  = "added    ",
            D  = "deleted  ",
            C  = "copied   ",
            U  = "updated  ",
            R  = "renamed  ",
            DD = "unmerged ",
            AU = "unmerged ",
            UD = "unmerged ",
            UA = "unmerged ",
            DU = "unmerged ",
            AA = "unmerged ",
            UU = "unmerged ",
            ["?"] = "",
          },
        },
  
        -- ── UI ────────────────────────────────────────────────────────────────
        -- Use sane-defaults for the floating windows
        floating_border      = "rounded",
        disable_hint         = false,
        disable_context_highlighting = false,
        disable_signs        = false,
        disable_insert_on_commit = "auto",
  
        -- ── Remeber folds ────────────────────────────────────────────────────
        remember_settings    = true,
        use_per_project_settings = true,
  
        -- ── Telescope / fzf-lua completer ─────────────────────────────────────
        -- "telescope" | "fzf_lua" | "mini_pick"
        auto_show_console    = true,
        auto_close_console   = true,
        console_timeout      = 2000,
  
        -- ── Filepaths ─────────────────────────────────────────────────────────
        sort_branches = "-version:refname",
      },
  
      config = function(_, opts)
        require("neogit").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshNeogit", { clear = true })
  
        -- Re-apply highlights on colorscheme change
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        -- ASH hot-reload: resync colours after palette swap
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🌿 Neogit highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Neogit", timeout = 1200 }
            )
          end,
        })
  
        -- Neogit commit message: enable spell check and set textwidth
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = { "NeogitCommitMessage", "gitcommit" },
          callback = function(ev)
            vim.opt_local.spell      = true
            vim.opt_local.spelllang  = "en_us"
            vim.opt_local.textwidth  = 72
            vim.opt_local.colorcolumn= "73"
            vim.opt_local.wrap       = true
  
            -- Highlight subject line (first 72 chars)
            vim.api.nvim_buf_add_highlight(
              ev.buf, -1, "Title", 0, 0, math.min(72, #(vim.api.nvim_buf_get_lines(ev.buf, 0, 1, false)[1] or ""))
            )
          end,
        })
  
        -- Neogit status: disable mini.indentscope and mini.animate
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "Neogit*",
          callback = function(ev)
            vim.b[ev.buf].miniindentscope_disable = true
            vim.b[ev.buf].minianimate_disable     = true
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("🌿 Neogit loaded", vim.log.levels.DEBUG, { title = "ASH Neogit" })
        end
      end,
    },
  }