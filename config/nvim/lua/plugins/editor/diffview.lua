-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📊 DIFFVIEW.NVIM — ULTRA GIT DIFF VIEWER v5.0 OMEGA                     ║
-- ║   Multi-file diff · merge conflicts · file history · blame log                 ║
-- ║   delta pager · custom keymaps · ASH theme-synced · Telescope integration     ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Panel chrome ──────────────────────────────────────────────────────────
    hl(0, "DiffviewNormal",           { link = "Normal"       })
    hl(0, "DiffviewCursorLine",       { link = "CursorLine"   })
    hl(0, "DiffviewVertSplit",        { link = "VertSplit"    })
    hl(0, "DiffviewSignColumn",       { link = "SignColumn"   })
    hl(0, "DiffviewStatusLine",       { link = "StatusLine"   })
    hl(0, "DiffviewStatusLineNC",     { link = "StatusLineNC" })
    hl(0, "DiffviewEndOfBuffer",      { link = "EndOfBuffer"  })
  
    -- ── File panel ─────────────────────────────────────────────────────────────
    hl(0, "DiffviewFilePanelTitle",   { bold = true, link = "Title"     })
    hl(0, "DiffviewFilePanelCounter", { link = "TabLineSel"             })
    hl(0, "DiffviewFilePanelRootPath",{ bold = true, link = "Directory" })
    hl(0, "DiffviewFilePanelPath",    { link = "Comment"                })
    hl(0, "DiffviewFilePanelInsertions",{ fg = "#9ece6a"               })
    hl(0, "DiffviewFilePanelDeletions",{ fg = "#f38ba8"                })
    hl(0, "DiffviewFilePanelConflicts",{ bold = true, fg = "#e0af68"   })
  
    -- ── Git status badges ─────────────────────────────────────────────────────
    hl(0, "DiffviewStatusAdded",      { fg = "#9ece6a" })
    hl(0, "DiffviewStatusUntracked",  { fg = "#7aa2f7" })
    hl(0, "DiffviewStatusModified",   { fg = "#e0af68" })
    hl(0, "DiffviewStatusRenamed",    { fg = "#7dcfff" })
    hl(0, "DiffviewStatusCopied",     { fg = "#73daca" })
    hl(0, "DiffviewStatusTypeChange", { fg = "#bb9af7" })
    hl(0, "DiffviewStatusUnmerged",   { fg = "#f38ba8" })
    hl(0, "DiffviewStatusUnknown",    { fg = "#9399b2" })
    hl(0, "DiffviewStatusDeleted",    { fg = "#f38ba8" })
    hl(0, "DiffviewStatusBroken",     { fg = "#f38ba8" })
    hl(0, "DiffviewStatusIgnored",    { fg = "#9399b2" })
  
    -- ── Conflict markers ──────────────────────────────────────────────────────
    hl(0, "DiffviewConflictAncestor",     { link = "DiffText"    })
    hl(0, "DiffviewConflictAncestorLabel",{ bold = true, fg = "#e0af68" })
    hl(0, "DiffviewConflictCurrent",      { link = "DiffAdd"     })
    hl(0, "DiffviewConflictCurrentLabel", { bold = true, fg = "#9ece6a" })
    hl(0, "DiffviewConflictIncoming",     { link = "DiffChange"  })
    hl(0, "DiffviewConflictIncomingLabel",{ bold = true, fg = "#7aa2f7" })
  
    -- ── Folds / refs ──────────────────────────────────────────────────────────
    hl(0, "DiffviewFolderSign",       { link = "Directory"      })
    hl(0, "DiffviewFolderName",       { link = "Directory"      })
    hl(0, "DiffviewReference",        { link = "Special"        })
    hl(0, "DiffviewPrimary",          { link = "Keyword"        })
    hl(0, "DiffviewSecondary",        { link = "String"         })
    hl(0, "DiffviewDim1",             { link = "Comment"        })
    hl(0, "DiffviewHash",             { link = "Number"         })
    hl(0, "DiffviewNonText",          { link = "NonText"        })
    hl(0, "DiffviewWinSeparator",     { link = "WinSeparator"   })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 SMART TOGGLE HELPERS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Open / close DiffviewOpen intelligently
  local function toggle_diffview()
    local lib = require("diffview.lib")
    if lib.get_current_view() then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewOpen")
    end
  end
  
  -- Toggle file history for current buffer
  local function toggle_file_history()
    local lib = require("diffview.lib")
    if lib.get_current_view() then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewFileHistory %")
    end
  end
  
  -- Toggle git log (all files)
  local function toggle_log()
    local lib = require("diffview.lib")
    if lib.get_current_view() then
      vim.cmd("DiffviewClose")
    else
      vim.cmd("DiffviewFileHistory")
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "sindrets/diffview.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
      cmd          = {
        "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
        "DiffviewFocusFiles", "DiffviewRefresh",
        "DiffviewFileHistory",
      },
      keys = {
        { "<leader>gd",  toggle_diffview,     desc = "📊 Diffview Open/Close"          },
        { "<leader>gh",  toggle_file_history, desc = "📊 File History (buffer)"        },
        { "<leader>gH",  toggle_log,          desc = "📊 Git Log (all files)"          },
        { "<leader>gm",  "<cmd>DiffviewOpen HEAD...origin HEAD --imply-local<cr>",
          desc = "📊 Diff vs origin HEAD"    },
        { "<leader>gM",  "<cmd>DiffviewOpen HEAD~1...HEAD<cr>",
          desc = "📊 Diff last commit"       },
        -- Branch diff: prompt for branch name
        { "<leader>gb",
          function()
            local branch = vim.fn.input("Branch to diff against: ")
            if branch ~= "" then
              vim.cmd("DiffviewOpen " .. branch .. "...HEAD")
            end
          end,
          desc = "📊 Diff vs branch"         },
        -- Staged changes only
        { "<leader>gS",  "<cmd>DiffviewOpen --staged<cr>",
          desc = "📊 Staged Changes"         },
        -- Close diffview
        { "<leader>gc",  "<cmd>DiffviewClose<cr>",
          desc = "📊 Close Diffview"         },
      },
  
      opts = {
        -- ── Diff options ──────────────────────────────────────────────────────
        diff_binaries    = false,
        enhanced_diff_hl = true,
        git_cmd          = { "git" },
        hg_cmd           = { "hg" },
        use_icons        = true,
        show_help_hints  = true,
        watch_index      = true,
  
        -- ── Icons ─────────────────────────────────────────────────────────────
        icons = {
          folder_closed = "󰉋",
          folder_open   = "󰝰",
        },
        signs = {
          fold_closed   = "",
          fold_open     = "",
          done          = "✓",
        },
  
        -- ── View ──────────────────────────────────────────────────────────────
        view = {
          -- Default: side-by-side diff
          default = {
            layout            = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info       = false,
          },
          -- Merge conflicts: 3-way diff
          merge_tool = {
            layout            = "diff3_horizontal",
            disable_diagnostics = true,
            winbar_info       = true,
          },
          -- File history: side-by-side
          file_history = {
            layout            = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info       = false,
          },
        },
  
        -- ── File panel ────────────────────────────────────────────────────────
        file_panel = {
          listing_style   = "tree",
          tree_options    = {
            flatten_dirs  = true,
            folder_statuses = "only_folded",
          },
          win_config      = {
            position      = "left",
            width         = 35,
            win_opts      = {},
          },
        },
  
        -- ── File history panel ─────────────────────────────────────────────────
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                diff_merges = "combined",
              },
              multi_file  = {
                diff_merges = "first-parent",
              },
            },
          },
          win_config  = {
            position  = "bottom",
            height    = 16,
            win_opts  = {},
          },
        },
  
        -- ── Commit log panel ──────────────────────────────────────────────────
        commit_log_panel = {
          win_config = { win_opts = {} },
        },
  
        -- ── Default args ──────────────────────────────────────────────────────
        default_args = {
          DiffviewOpen        = {},
          DiffviewFileHistory = {},
        },
  
        -- ── Hooks ─────────────────────────────────────────────────────────────
        hooks = {
          -- Disable some settings inside diffview
          diff_buf_read = function(bufnr)
            vim.opt_local.wrap     = false
            vim.opt_local.list     = false
            vim.opt_local.colorcolumn = ""
            -- Disable mini.indentscope inside diff buffers
            vim.b[bufnr].miniindentscope_disable = true
          end,
  
          view_opened = function(_view)
            vim.notify(
              "📊 Diffview opened",
              vim.log.levels.INFO,
              { title = "Diffview", timeout = 1500 }
            )
          end,
  
          view_closed = function(_view)
            vim.notify(
              "📊 Diffview closed",
              vim.log.levels.INFO,
              { title = "Diffview", timeout = 1000 }
            )
          end,
        },
  
        -- ── Keymaps ───────────────────────────────────────────────────────────
        keymaps = {
          disable_defaults = false,
  
          view = {
            { "n", "<tab>",       require("diffview.actions").select_next_entry,       { desc = "Next file"              } },
            { "n", "<s-tab>",     require("diffview.actions").select_prev_entry,       { desc = "Prev file"              } },
            { "n", "gf",          require("diffview.actions").goto_file_edit,          { desc = "Open in prev split"     } },
            { "n", "<C-w><C-f>",  require("diffview.actions").goto_file_split,         { desc = "Open in new split"      } },
            { "n", "<C-w>gf",     require("diffview.actions").goto_file_tab,           { desc = "Open in new tab"        } },
            { "n", "<leader>e",   require("diffview.actions").focus_files,             { desc = "Focus file panel"       } },
            { "n", "<leader>b",   require("diffview.actions").toggle_files,            { desc = "Toggle file panel"      } },
            { "n", "g<C-x>",      require("diffview.actions").cycle_layout,            { desc = "Cycle layout"           } },
            { "n", "[x",          require("diffview.actions").prev_conflict,           { desc = "Prev conflict"          } },
            { "n", "]x",          require("diffview.actions").next_conflict,           { desc = "Next conflict"          } },
            { "n", "<leader>co",  require("diffview.actions").conflict_choose("ours"), { desc = "Choose ours"            } },
            { "n", "<leader>ct",  require("diffview.actions").conflict_choose("theirs"),{ desc = "Choose theirs"         } },
            { "n", "<leader>cb",  require("diffview.actions").conflict_choose("base"), { desc = "Choose base"            } },
            { "n", "<leader>ca",  require("diffview.actions").conflict_choose("all"),  { desc = "Choose all"             } },
            { "n", "dx",          require("diffview.actions").conflict_choose("none"), { desc = "Delete conflict region" } },
            { "n", "<leader>cO",  require("diffview.actions").conflict_choose_all("ours"),   { desc = "Choose ours (all)"   } },
            { "n", "<leader>cT",  require("diffview.actions").conflict_choose_all("theirs"), { desc = "Choose theirs (all)" } },
            { "n", "<leader>cB",  require("diffview.actions").conflict_choose_all("base"),   { desc = "Choose base (all)"   } },
            { "n", "<leader>cA",  require("diffview.actions").conflict_choose_all("all"),    { desc = "Choose all (all)"    } },
            { "n", "dX",          require("diffview.actions").conflict_choose_all("none"),   { desc = "Delete all conflicts" } },
          },
  
          diff1 = {
            { "n", "?", require("diffview.actions").help({ "view", "diff1" }), { desc = "Help" } },
          },
  
          diff2 = {
            { "n", "?", require("diffview.actions").help({ "view", "diff2" }), { desc = "Help" } },
          },
  
          diff3 = {
            { "n", "?",           require("diffview.actions").help({ "view", "diff3" }),          { desc = "Help"                   } },
            { "n", "<leader>co",  require("diffview.actions").diffget("ours"),                    { desc = "Diffget ours"           } },
            { "n", "<leader>ct",  require("diffview.actions").diffget("theirs"),                  { desc = "Diffget theirs"         } },
          },
  
          diff4 = {
            { "n", "?",           require("diffview.actions").help({ "view", "diff4" }),          { desc = "Help"                   } },
            { "n", "<leader>co",  require("diffview.actions").diffget("ours"),                    { desc = "Diffget ours"           } },
            { "n", "<leader>cb",  require("diffview.actions").diffget("base"),                    { desc = "Diffget base"           } },
            { "n", "<leader>ct",  require("diffview.actions").diffget("theirs"),                  { desc = "Diffget theirs"         } },
          },
  
          file_panel = {
            { "n", "j",           require("diffview.actions").next_entry,              { desc = "Next entry"             } },
            { "n", "<down>",      require("diffview.actions").next_entry,              { desc = "Next entry"             } },
            { "n", "k",           require("diffview.actions").prev_entry,              { desc = "Prev entry"             } },
            { "n", "<up>",        require("diffview.actions").prev_entry,              { desc = "Prev entry"             } },
            { "n", "<cr>",        require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "o",           require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "l",           require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "<2-LeftMouse>", require("diffview.actions").select_entry,          { desc = "Open diff"              } },
            { "n", "-",           require("diffview.actions").toggle_stage_entry,      { desc = "Stage / unstage entry"  } },
            { "n", "S",           require("diffview.actions").stage_all,               { desc = "Stage all"              } },
            { "n", "U",           require("diffview.actions").unstage_all,             { desc = "Unstage all"            } },
            { "n", "X",           require("diffview.actions").restore_entry,           { desc = "Restore entry"          } },
            { "n", "L",           require("diffview.actions").open_commit_log,         { desc = "Open commit log"        } },
            { "n", "zo",          require("diffview.actions").open_fold,               { desc = "Open fold"              } },
            { "n", "zc",          require("diffview.actions").close_fold,              { desc = "Close fold"             } },
            { "n", "za",          require("diffview.actions").toggle_fold,             { desc = "Toggle fold"            } },
            { "n", "zR",          require("diffview.actions").open_all_folds,          { desc = "Open all folds"         } },
            { "n", "zM",          require("diffview.actions").close_all_folds,         { desc = "Close all folds"        } },
            { "n", "<c-b>",       require("diffview.actions").scroll_view(-0.25),      { desc = "Scroll view up"         } },
            { "n", "<c-f>",       require("diffview.actions").scroll_view(0.25),       { desc = "Scroll view down"       } },
            { "n", "<tab>",       require("diffview.actions").select_next_entry,       { desc = "Next file"              } },
            { "n", "<s-tab>",     require("diffview.actions").select_prev_entry,       { desc = "Prev file"              } },
            { "n", "gf",          require("diffview.actions").goto_file_edit,          { desc = "Open in prev split"     } },
            { "n", "i",           require("diffview.actions").listing_style,           { desc = "Toggle listing style"   } },
            { "n", "f",           require("diffview.actions").toggle_flatten_dirs,     { desc = "Toggle flatten dirs"    } },
            { "n", "R",           require("diffview.actions").refresh_files,           { desc = "Refresh files"          } },
            { "n", "<leader>e",   require("diffview.actions").focus_files,             { desc = "Focus file panel"       } },
            { "n", "<leader>b",   require("diffview.actions").toggle_files,            { desc = "Toggle file panel"      } },
            { "n", "g<C-x>",      require("diffview.actions").cycle_layout,            { desc = "Cycle layout"           } },
            { "n", "[x",          require("diffview.actions").prev_conflict,           { desc = "Prev conflict"          } },
            { "n", "]x",          require("diffview.actions").next_conflict,           { desc = "Next conflict"          } },
            { "n", "?",           require("diffview.actions").help("file_panel"),      { desc = "Help"                   } },
            { "n", "<c-r>",       require("diffview.actions").refresh_files,           { desc = "Refresh"                } },
          },
  
          file_history_panel = {
            { "n", "g!",          require("diffview.actions").options,                 { desc = "Options"                } },
            { "n", "<C-A-d>",     require("diffview.actions").open_in_diffview,        { desc = "Open in diffview"       } },
            { "n", "y",           require("diffview.actions").copy_hash,               { desc = "Copy hash"              } },
            { "n", "L",           require("diffview.actions").open_commit_log,         { desc = "Open commit log"        } },
            { "n", "zR",          require("diffview.actions").open_all_folds,          { desc = "Open all folds"         } },
            { "n", "zM",          require("diffview.actions").close_all_folds,         { desc = "Close all folds"        } },
            { "n", "j",           require("diffview.actions").next_entry,              { desc = "Next entry"             } },
            { "n", "<down>",      require("diffview.actions").next_entry,              { desc = "Next entry"             } },
            { "n", "k",           require("diffview.actions").prev_entry,              { desc = "Prev entry"             } },
            { "n", "<up>",        require("diffview.actions").prev_entry,              { desc = "Prev entry"             } },
            { "n", "<cr>",        require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "o",           require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "l",           require("diffview.actions").select_entry,            { desc = "Open diff"              } },
            { "n", "<tab>",       require("diffview.actions").select_next_entry,       { desc = "Next file"              } },
            { "n", "<s-tab>",     require("diffview.actions").select_prev_entry,       { desc = "Prev file"              } },
            { "n", "gf",          require("diffview.actions").goto_file_edit,          { desc = "Open in prev split"     } },
            { "n", "<c-b>",       require("diffview.actions").scroll_view(-0.25),      { desc = "Scroll view up"         } },
            { "n", "<c-f>",       require("diffview.actions").scroll_view(0.25),       { desc = "Scroll view down"       } },
            { "n", "<leader>e",   require("diffview.actions").focus_files,             { desc = "Focus file panel"       } },
            { "n", "<leader>b",   require("diffview.actions").toggle_files,            { desc = "Toggle file panel"      } },
            { "n", "g<C-x>",      require("diffview.actions").cycle_layout,            { desc = "Cycle layout"           } },
            { "n", "?",           require("diffview.actions").help("file_history_panel"),{ desc = "Help"                 } },
          },
  
          option_panel = {
            { "n", "<tab>",  require("diffview.actions").select_entry,   { desc = "Change option" } },
            { "n", "q",      require("diffview.actions").close,          { desc = "Close"         } },
            { "n", "?",      require("diffview.actions").help("option_panel"),{ desc = "Help"     } },
          },
  
          help_panel = {
            { "n", "q",      require("diffview.actions").close, { desc = "Close" } },
            { "n", "<esc>",  require("diffview.actions").close, { desc = "Close" } },
          },
        },
      },
  
      config = function(_, opts)
        require("diffview").setup(opts)
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshDiffview", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📊 Diffview highlights synced", vim.log.levels.INFO,
              { title = "ASH Diffview", timeout = 1200 })
          end,
        })
      end,
    },
  }