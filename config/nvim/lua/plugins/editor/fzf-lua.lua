-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/editor/fzf-lua.lua — High-Performance Fuzzy Finder             ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: ibhagwan/fzf-lua                                                    ║
-- ║                                                                              ║
-- ║  Used as: high-performance alternative / complement to telescope            ║
-- ║  Faster for: large repos (>100k files), live grep, git log                  ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Native fzf binary (Rust-based, sub-millisecond fuzzy)                  ║
-- ║    • bat syntax highlighting in preview                                     ║
-- ║    • Image preview via chafa / ueberzugpp                                   ║
-- ║    • git-delta diff preview                                                  ║
-- ║    • Catppuccin FZF_DEFAULT_OPTS colour injection                           ║
-- ║    • vim.ui.select replacement                                               ║
-- ║    • 40+ keymaps (prefixed with <leader>F for fzf-lua specific)            ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "ibhagwan/fzf-lua",
    cmd          = "FzfLua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  
    keys = {
      -- ── Files ─────────────────────────────────────────────────────────────
      { "<leader>Ff",  function() require("fzf-lua").files()          end,  desc = "  FZF files"             },
      { "<leader>Fr",  function() require("fzf-lua").oldfiles()       end,  desc = "  FZF recent files"      },
      { "<leader>Fb",  function() require("fzf-lua").buffers()        end,  desc = "  FZF buffers"           },
      { "<leader>Ft",  function() require("fzf-lua").tabs()           end,  desc = "  FZF tabs"              },
      -- ── Search ────────────────────────────────────────────────────────────
      { "<leader>Fg",  function() require("fzf-lua").live_grep()      end,  desc = "  FZF live grep"         },
      { "<leader>Fw",  function() require("fzf-lua").grep_cword()     end,  desc = "  FZF grep cword"        },
      { "<leader>FW",  function() require("fzf-lua").grep_cWORD()     end,  desc = "  FZF grep cWORD"        },
      { "<leader>Fv",  function() require("fzf-lua").grep_visual()    end,  mode = "v", desc = "  FZF grep selection" },
      { "<leader>FG",  function() require("fzf-lua").grep_project()   end,  desc = "  FZF grep project"      },
      -- ── Git ───────────────────────────────────────────────────────────────
      { "<leader>Fc",  function() require("fzf-lua").git_commits()    end,  desc = "  FZF git commits"       },
      { "<leader>FC",  function() require("fzf-lua").git_bcommits()   end,  desc = "  FZF git buf commits"   },
      { "<leader>FB",  function() require("fzf-lua").git_branches()   end,  desc = "  FZF git branches"      },
      { "<leader>FS",  function() require("fzf-lua").git_status()     end,  desc = "  FZF git status"        },
      { "<leader>Fs",  function() require("fzf-lua").git_stash()      end,  desc = "  FZF git stash"         },
      -- ── LSP ───────────────────────────────────────────────────────────────
      { "<leader>Fd",  function() require("fzf-lua").lsp_definitions()        end, desc = "  FZF definitions"    },
      { "<leader>FD",  function() require("fzf-lua").lsp_declarations()       end, desc = "  FZF declarations"   },
      { "<leader>Fp",  function() require("fzf-lua").lsp_references()         end, desc = "  FZF references"     },
      { "<leader>Fo",  function() require("fzf-lua").lsp_document_symbols()   end, desc = "  FZF doc symbols"    },
      { "<leader>FO",  function() require("fzf-lua").lsp_workspace_symbols()  end, desc = "  FZF ws symbols"     },
      { "<leader>Fx",  function() require("fzf-lua").diagnostics_document()   end, desc = "  FZF diagnostics"    },
      -- ── Misc ──────────────────────────────────────────────────────────────
      { "<leader>Fk",  function() require("fzf-lua").keymaps()        end,  desc = "  FZF keymaps"           },
      { "<leader>Fh",  function() require("fzf-lua").help_tags()      end,  desc = "  FZF help"              },
      { "<leader>Fm",  function() require("fzf-lua").marks()          end,  desc = "  FZF marks"             },
      { "<leader>Fj",  function() require("fzf-lua").jumps()          end,  desc = "  FZF jumps"             },
      { "<leader>F;",  function() require("fzf-lua").resume()         end,  desc = "  FZF resume"            },
      { "<leader>Fq",  function() require("fzf-lua").quickfix()       end,  desc = "  FZF quickfix"          },
    },
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Build Catppuccin FZF colour string ────────────────────────────────
      local function fzf_colours()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local function strip(hex) return hex:gsub("^#", "") end
  
        return {
          ["fg"]       = strip(p.text     or "#cdd6f4"),
          ["fg+"]      = strip(p.text     or "#cdd6f4"),
          ["bg"]       = strip(p.base     or "#1e1e2e"),
          ["bg+"]      = strip(p.surface0 or "#313244"),
          ["hl"]       = strip(p.blue     or "#89b4fa"),
          ["hl+"]      = strip(p.blue     or "#89b4fa"),
          ["info"]     = strip(p.mauve    or "#cba6f7"),
          ["border"]   = strip(p.surface1 or "#45475a"),
          ["prompt"]   = strip(p.mauve    or "#cba6f7"),
          ["pointer"]  = strip(p.mauve    or "#cba6f7"),
          ["marker"]   = strip(p.green    or "#a6e3a1"),
          ["spinner"]  = strip(p.mauve    or "#cba6f7"),
          ["header"]   = strip(p.blue     or "#89b4fa"),
          ["gutter"]   = strip(p.base     or "#1e1e2e"),
          ["separator"] = strip(p.surface0 or "#313244"),
        }
      end
  
      local colours = fzf_colours()
      local colour_args = {}
      for k, v in pairs(colours) do
        colour_args[#colour_args + 1] = k .. ":#" .. v
      end
      local fzf_colors_str = table.concat(colour_args, ",")
  
      return {
        -- ── Global ────────────────────────────────────────────────────────
        fzf_opts = {
          ["--ansi"]          = true,
          ["--info"]          = "inline",
          ["--height"]        = "100%",
          ["--layout"]        = "reverse",
          ["--border"]        = "none",
          ["--color"]         = fzf_colors_str,
          ["--cycle"]         = true,
          ["--marker"]        = icons.ui.Check,
          ["--pointer"]       = icons.ui.ChevronRight,
          ["--prompt"]        = icons.ui.Search .. " ",
          ["--no-scrollbar"]  = true,
        },
  
        fzf_colors = true,
  
        -- ── Window ────────────────────────────────────────────────────────
        winopts = {
          height         = 0.85,
          width          = 0.80,
          row            = 0.35,
          col            = 0.50,
          border          = "rounded",
          backdrop        = 60,
          fullscreen      = false,
          preview = {
            border        = "border-sharp",
            scrollbar     = "float",
            scrolloff     = "-1",
            title         = true,
            title_pos     = "center",
            delay         = 80,
            wrap          = "nowrap",
            hidden        = "nohidden",
            vertical      = "down:45%",
            horizontal    = "right:55%",
            layout        = "flex",
            flip_columns  = 120,
          },
          on_create       = function()
            -- Slight transparency for the fzf window
            vim.wo.winblend = 5
          end,
        },
  
        -- ── Key bindings ─────────────────────────────────────────────────
        keymap = {
          builtin = {
            ["<F1>"]      = "toggle-help",
            ["<F2>"]      = "toggle-fullscreen",
            ["<F3>"]      = "toggle-preview-wrap",
            ["<F4>"]      = "toggle-preview",
            ["<F5>"]      = "toggle-preview-ccw",
            ["<F6>"]      = "toggle-preview-cw",
            ["<C-d>"]     = "preview-page-down",
            ["<C-u>"]     = "preview-page-up",
            ["<C-e>"]     = "preview-down",
            ["<C-y>"]     = "preview-up",
            ["<S-Down>"]  = "preview-page-down",
            ["<S-Up>"]    = "preview-page-up",
          },
          fzf = {
            ["ctrl-z"]    = "abort",
            ["ctrl-u"]    = "unix-line-discard",
            ["ctrl-f"]    = "half-page-down",
            ["ctrl-b"]    = "half-page-up",
            ["ctrl-a"]    = "beginning-of-line",
            ["ctrl-e"]    = "end-of-line",
            ["alt-a"]     = "toggle-all",
            ["f3"]        = "toggle-preview-wrap",
            ["f4"]        = "toggle-preview",
            ["shift-down"] = "preview-page-down",
            ["shift-up"]  = "preview-page-up",
          },
        },
  
        -- ── Actions ──────────────────────────────────────────────────────
        actions = {
          files = {
            ["default"]  = require("fzf-lua.actions").file_edit_or_qf,
            ["ctrl-s"]   = require("fzf-lua.actions").file_split,
            ["ctrl-v"]   = require("fzf-lua.actions").file_vsplit,
            ["ctrl-t"]   = require("fzf-lua.actions").file_tabedit,
            ["alt-q"]    = require("fzf-lua.actions").file_sel_to_qf,
            ["alt-l"]    = require("fzf-lua.actions").file_sel_to_ll,
          },
          buffers = {
            ["default"]  = require("fzf-lua.actions").buf_edit,
            ["ctrl-s"]   = require("fzf-lua.actions").buf_split,
            ["ctrl-v"]   = require("fzf-lua.actions").buf_vsplit,
            ["ctrl-t"]   = require("fzf-lua.actions").buf_tabedit,
            ["ctrl-x"]   = require("fzf-lua.actions").buf_del,
          },
        },
  
        -- ── Previewers ────────────────────────────────────────────────────
        previewers = {
          cat   = { cmd = "cat",  args = "--number" },
          bat   = {
            cmd   = "bat",
            args  = "--style=numbers,changes,header --color=always",
            theme = "Catppuccin Mocha",
          },
          head  = { cmd = "head", args = nil },
          git_diff = {
            cmd_deleted   = "git diff --color HEAD --",
            cmd_modified  = "git diff --color HEAD",
            cmd_untracked = "git diff --color --no-index /dev/null",
            pager         = vim.fn.executable("delta") == 1
              and "delta --width $FZF_PREVIEW_COLUMNS"
              or  nil,
          },
          man   = {
            cmd = vim.fn.has("linux") == 1 and "man -P cat %s | col -bx" or "man %s",
          },
          builtin = {
            syntax         = true,
            syntax_limit_b = 1024 * 1024,
            syntax_limit_l = 0,
            limit_b        = 1024 * 1024 * 10,
            extensions     = {
              ["png"]   = { "chafa", "--format=symbols", "--symbols=half" },
              ["jpg"]   = { "chafa", "--format=symbols", "--symbols=half" },
              ["jpeg"]  = { "chafa", "--format=symbols", "--symbols=half" },
              ["gif"]   = { "chafa", "--format=symbols", "--symbols=half" },
              ["webp"]  = { "chafa", "--format=symbols", "--symbols=half" },
              ["svg"]   = { "chafa", "--format=symbols", "--symbols=half" },
              ["pdf"]   = { "pdftotext", "-l", "10", "-nopgbrk", "-q", "-", "-" },
            },
          },
        },
  
        -- ── Files ─────────────────────────────────────────────────────────
        files = {
          prompt       = icons.ui.FindFile .. "  Files › ",
          multiprocess = true,
          git_icons    = true,
          file_icons   = true,
          color_icons  = true,
          find_opts    = [[-type f -not -path '*/\.git/*' -not -path '*/node_modules/*']],
          rg_opts      = [[--color=never --files --hidden --follow -g "!.git" -g "!node_modules"]],
          fd_opts      = [[--color=never --type f --hidden --follow --exclude .git --exclude node_modules]],
        },
  
        -- ── Live grep ──────────────────────────────────────────────────────
        grep = {
          prompt         = icons.ui.Search .. "  Grep › ",
          input_prompt   = "Grep For › ",
          multiprocess   = true,
          git_icons      = true,
          file_icons     = true,
          color_icons    = true,
          rg_opts        = [[--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e]],
          -- glob filter
          rg_glob        = true,
          glob_flag      = "--iglob",
          glob_separator = "%s%-%-",
          -- Live grep extra args
          grep_opts      = "--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e",
        },
  
        -- ── Git ────────────────────────────────────────────────────────────
        git = {
          files = {
            prompt    = icons.git.branch .. "  Git Files › ",
            cmd       = "git ls-files --exclude-standard",
            multiprocess = true,
            git_icons = true,
            file_icons = true,
            color_icons = true,
          },
          status = {
            prompt   = icons.git.added .. "  Git Status › ",
            cmd      = "git status --short --no-branch",
          },
          commits = {
            prompt   = icons.git.commit .. "  Commits › ",
            cmd      = "git log --color --pretty=format:'%C(yellow)%h%Creset %Cgreen(%><(12)%cr%><|(12))%Creset %s %C(blue)<%an>%Creset'",
            preview  = "git show --pretty='%Cred%H%n%Cblue%an <%ae>%n%C(yellow)%cD%n%Cgreen%s%n' --color {1}",
            actions  = {
              ["default"] = require("fzf-lua.actions").git_checkout,
              ["ctrl-y"]  = function(selected)
                vim.fn.setreg("+", selected[1]:match("[a-f0-9]+"))
              end,
            },
          },
          branches = {
            prompt   = icons.git.branch .. "  Branches › ",
            cmd      = "git branch --all --color",
            preview  = "git log --graph --pretty=oneline --abbrev-commit --decorate {1}",
            actions  = {
              ["default"] = require("fzf-lua.actions").git_switch,
              ["ctrl-x"]  = require("fzf-lua.actions").git_branch_del,
            },
          },
        },
      }
    end,
  
    config = function(_, opts)
      require("fzf-lua").setup(opts)
  
      -- Replace vim.ui.select with fzf-lua
      require("fzf-lua").register_ui_select(function(o, _items)
        local min_h = math.min(#_items + 4, 20)
        return {
          winopts = {
            height   = min_h,
            width    = math.min(80, vim.o.columns - 4),
            row      = 0.40,
            col      = 0.50,
            preview  = { hidden = "hidden" },
          },
        }
      end)
    end,
  }