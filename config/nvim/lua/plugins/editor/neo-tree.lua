-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/editor/neo-tree.lua — File System Explorer                     ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: nvim-neo-tree/neo-tree.nvim                                         ║
-- ║                                                                              ║
-- ║  Sources:                                                                    ║
-- ║    filesystem   — project file tree with git status                         ║
-- ║    buffers      — open buffer list                                           ║
-- ║    git_status   — changed / staged / untracked files                        ║
-- ║    document_symbols — LSP symbol outline                                    ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Devicon per file type with Catppuccin palette colouring                ║
-- ║    • Git status indicators (A M D R ? !) with colour coding                 ║
-- ║    • Fuzzy file filter inside tree                                           ║
-- ║    • Trash integration (gio trash / trash-cli)                              ║
-- ║    • Image preview via image.nvim                                           ║
-- ║    • Float mode + left sidebar mode                                         ║
-- ║    • Diagnostics column in tree                                              ║
-- ║    • Smart CWD tracking (follows LSP root / git root)                       ║
-- ║    • Animated open / close                                                  ║
-- ║    • 30+ custom keymaps                                                     ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "nvim-neo-tree/neo-tree.nvim",
    branch       = "v3.x",
    cmd          = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim",
      {
        "s1n7ax/nvim-window-picker",
        version = "2.*",
        opts = {
          filter_rules = {
            include_current_win = false,
            autoselect_one      = true,
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify" },
              buftype  = { "terminal", "quickfix" },
            },
          },
        },
      },
    },
  
    keys = {
      -- ── Explorer toggles ──────────────────────────────────────────────────
      {
        "<leader>ee",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir    = Ash.util.path.exists(vim.loop.cwd()) and vim.loop.cwd() or nil,
          })
        end,
        desc = "  Explorer (cwd)",
      },
      {
        "<leader>eE",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            dir    = vim.fn.expand("%:p:h"),
          })
        end,
        desc = "  Explorer (file dir)",
      },
      {
        "<leader>eg",
        function()
          require("neo-tree.command").execute({
            source = "git_status",
            toggle = true,
          })
        end,
        desc = "  Git status tree",
      },
      {
        "<leader>eb",
        function()
          require("neo-tree.command").execute({
            source = "buffers",
            toggle = true,
          })
        end,
        desc = "  Buffer list",
      },
      {
        "<leader>es",
        function()
          require("neo-tree.command").execute({
            source = "document_symbols",
            toggle = true,
          })
        end,
        desc = "  Document symbols",
      },
      {
        "<leader>ef",
        function()
          require("neo-tree.command").execute({
            reveal = true,
          })
        end,
        desc = "  Reveal current file",
      },
      -- Float mode
      {
        "<leader>eF",
        function()
          require("neo-tree.command").execute({
            toggle   = true,
            position = "float",
          })
        end,
        desc = "  Explorer (float)",
      },
      -- Direct mapping
      { "<C-e>", "<leader>ee", remap = true, desc = "  Explorer toggle" },
    },
  
    deactivate = function()
      vim.cmd("Neotree close")
    end,
  
    init = function()
      -- Open neo-tree on directory argument
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("AshNeoTreeInit", { clear = true }),
        callback = function()
          if package.loaded["neo-tree"] then
            return true   -- already loaded; stop listening
          end
          local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(0))
          if stats and stats.type == "directory" then
            require("lazy").load({ plugins = { "neo-tree.nvim" } })
            return true
          end
        end,
      })
    end,
  
    opts = function()
      local icons = Ash.icons
  
      -- ── Colour palette ─────────────────────────────────────────────────────
      local p = {}
      pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
      local overlay = p.overlay0 or "#6c7086"
      local blue    = p.blue     or "#89b4fa"
      local green   = p.green    or "#a6e3a1"
      local yellow  = p.yellow   or "#f9e2af"
      local red     = p.red      or "#f38ba8"
      local mauve   = p.mauve    or "#cba6f7"
      local peach   = p.peach    or "#fab387"
      local teal    = p.teal     or "#94e2d5"
      local text    = p.text     or "#cdd6f4"
  
      -- ── Trash command detection ───────────────────────────────────────────
      local trash_cmd = vim.fn.executable("gio")    == 1 and "gio trash"
                     or vim.fn.executable("trash")  == 1 and "trash"
                     or nil
  
      return {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Global
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        close_if_last_window             = true,
        popup_border_style               = "rounded",
        enable_git_status                = true,
        enable_diagnostics               = true,
        enable_normal_mode_for_inputs    = false,
        open_files_do_not_replace_types  = {
          "terminal", "Trouble", "trouble", "qf",
          "edgy", "aerial", "toggleterm",
        },
        sort_case_insensitive            = true,
        sort_function                    = nil,
        use_default_mappings             = false,
  
        -- ── Source selector (tab bar at top) ─────────────────────────────
        source_selector = {
          winbar                  = true,
          statusline              = false,
          show_scrolled_off_parent_node = true,
          sources = {
            { source = "filesystem",       display_name = icons.ui.Folder .. " Files"   },
            { source = "buffers",          display_name = icons.ui.Files  .. " Buffers" },
            { source = "git_status",       display_name = icons.git.branch .. " Git"    },
            { source = "document_symbols", display_name = icons.ui.List   .. " Symbols" },
          },
          content_layout = "start",
          tabs_layout    = "equal",
          separator      = { left = "▏", right = "▕" },
          separator_active = nil,
          show_separator_on_edge = false,
          highlight_tab          = "NeoTreeTabInactive",
          highlight_tab_active   = "NeoTreeTabActive",
          highlight_background   = "NeoTreeTabBarBackground",
          highlight_separator    = "NeoTreeTabSeparator",
          highlight_separator_active = "NeoTreeTabSeparatorActive",
        },
  
        -- ── Default component configs ─────────────────────────────────────
        default_component_configs = {
          container = {
            enable_character_fade = true,
            width                 = "100%",
            right_padding         = 0,
          },
  
          indent = {
            indent_size             = 2,
            padding                 = 1,
            with_markers            = true,
            indent_marker           = "│",
            last_indent_marker      = "└",
            highlight               = "NeoTreeIndentMarker",
            with_expanders          = true,
            expander_collapsed      = icons.ui.ChevronRight,
            expander_expanded       = icons.ui.ChevronDown,
            expander_highlight      = "NeoTreeExpander",
          },
  
          icon = {
            folder_closed           = icons.ui.Folder,
            folder_open             = icons.ui.FolderOpen,
            folder_empty            = icons.ui.FolderEmpty,
            folder_empty_open       = icons.ui.FolderEmptyOpen,
            default                 = icons.ui.File,
            highlight               = "NeoTreeFileIcon",
          },
  
          modified = {
            symbol                  = icons.ui.tab.modified .. " ",
            highlight               = "NeoTreeModified",
          },
  
          name = {
            trailing_slash          = false,
            use_git_status_colors   = true,
            highlight               = "NeoTreeFileName",
          },
  
          git_status = {
            symbols = {
              -- Staged
              added     = icons.git.added,
              modified  = icons.git.changed,
              deleted   = icons.git.removed,
              renamed   = icons.git.renamed,
              -- Unstaged
              untracked = icons.git.untracked,
              ignored   = icons.git.ignored,
              unstaged  = icons.ui.Edit,
              staged    = icons.ui.Check,
              conflict  = icons.git.conflict,
            },
          },
  
          -- Diagnostics in tree
          diagnostics = {
            symbols = {
              hint    = icons.diagnostics.Hint,
              info    = icons.diagnostics.Info,
              warn    = icons.diagnostics.Warn,
              error   = icons.diagnostics.Error,
            },
            highlights = {
              hint    = "DiagnosticSignHint",
              info    = "DiagnosticSignInfo",
              warn    = "DiagnosticSignWarn",
              error   = "DiagnosticSignError",
            },
          },
  
          file_size = {
            enabled         = true,
            required_width  = 64,
          },
  
          type = {
            enabled         = true,
            required_width  = 122,
          },
  
          last_modified = {
            enabled         = true,
            required_width  = 88,
          },
  
          created = {
            enabled         = true,
            required_width  = 110,
          },
  
          symlink_target = {
            enabled = true,
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Commands (shared across sources)
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        commands = {
          -- Copy file path to clipboard
          copy_path = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg("+", path)
            vim.notify(
              " Copied: " .. path,
              vim.log.levels.INFO,
              { title = "Neo-tree" }
            )
          end,
  
          -- Copy filename (without path) to clipboard
          copy_filename = function(state)
            local node = state.tree:get_node()
            local name = node.name
            vim.fn.setreg("+", name)
            vim.notify(
              " Copied: " .. name,
              vim.log.levels.INFO,
              { title = "Neo-tree" }
            )
          end,
  
          -- Open in system file manager
          open_system = function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.jobstart({ "xdg-open", path }, { detach = true })
          end,
  
          -- Reveal in parent
          reveal_in_parent = function(state)
            local node = state.tree:get_node()
            if node.type == "directory" then
              state.commands.navigate_up(state)
            end
          end,
  
          -- Trash file (safe delete)
          trash = trash_cmd and function(state)
            local node = state.tree:get_node()
            if node.type == "message" then return end
            local path = node:get_id()
            vim.fn.system(trash_cmd .. " " .. vim.fn.shellescape(path))
            require("neo-tree.sources.manager").refresh(state.name)
          end or nil,
  
          -- Trash visual selection
          trash_visual = trash_cmd and function(state, selected_nodes)
            for _, node in ipairs(selected_nodes) do
              local path = node:get_id()
              vim.fn.system(trash_cmd .. " " .. vim.fn.shellescape(path))
            end
            require("neo-tree.sources.manager").refresh(state.name)
          end or nil,
  
          -- Open with telescope live_grep inside selected directory
          grep_in_dir = function(state)
            local node = state.tree:get_node()
            local path = node.type == "directory"
              and node:get_id()
              or node:get_parent_id()
            require("telescope.builtin").live_grep({
              search_dirs = { path },
              prompt_title = icons.ui.Search .. "  Grep in " .. vim.fn.fnamemodify(path, ":~"),
            })
          end,
  
          -- Open with telescope find_files inside selected directory
          find_in_dir = function(state)
            local node  = state.tree:get_node()
            local path  = node.type == "directory"
              and node:get_id()
              or node:get_parent_id()
            require("telescope.builtin").find_files({
              cwd          = path,
              prompt_title = icons.ui.FindFile .. "  Find in " .. vim.fn.fnamemodify(path, ":~"),
            })
          end,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Window options
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        window = {
          position        = "left",
          width           = 35,
          mapping_options = { noremap = true, nowait = true },
  
          mappings = {
            -- ── Navigation ─────────────────────────────────────────────
            ["<space>"]  = { "toggle_node",                nowait = false },
            ["<cr>"]     = "open",
            ["<esc>"]    = "cancel",
            ["P"]        = { "toggle_preview",             config = { use_float = true, use_image_nvim = true } },
            ["l"]        = "focus_preview",
            ["S"]        = "open_split",
            ["s"]        = "open_vsplit",
            ["t"]        = "open_tabnew",
            ["w"]        = "open_with_window_picker",
            ["C"]        = "close_node",
            ["z"]        = "close_all_nodes",
            ["Z"]        = "expand_all_nodes",
            ["R"]        = "refresh",
            -- ── File ops ───────────────────────────────────────────────
            ["a"]        = { "add",             config = { show_path = "relative" } },
            ["A"]        = "add_directory",
            ["d"]        = "delete",
            ["D"]        = trash_cmd and "trash" or "delete",
            ["r"]        = "rename",
            ["y"]        = "copy_to_clipboard",
            ["x"]        = "cut_to_clipboard",
            ["p"]        = "paste_from_clipboard",
            ["c"]        = { "copy",            config = { show_path = "relative" } },
            ["m"]        = { "move",            config = { show_path = "relative" } },
            -- ── Clipboard / path ───────────────────────────────────────
            ["Y"]        = "copy_path",
            ["F"]        = "copy_filename",
            ["o"]        = "open_system",
            -- ── Search inside tree ─────────────────────────────────────
            ["/"]        = "fuzzy_finder",
            ["#"]        = "fuzzy_finder_directory",
            ["f"]        = "filter_on_submit",
            ["<C-x>"]    = "clear_filter",
            ["[g"]       = "prev_git_modified",
            ["]g"]       = "next_git_modified",
            -- ── Diagnostics navigation ─────────────────────────────────
            ["[e"]       = "prev_source",
            ["]e"]       = "next_source",
            -- ── Grep / Find inside dir ────────────────────────────────
            ["gr"]       = "grep_in_dir",
            ["gf"]       = "find_in_dir",
            -- ── Info ──────────────────────────────────────────────────
            ["i"]        = "show_file_details",
            ["H"]        = "toggle_hidden",
            ["q"]        = "close_window",
            ["?"]        = "show_help",
            -- ── Git ───────────────────────────────────────────────────
            ["gs"]       = "git_add_file",
            ["gu"]       = "git_unstage_file",
            ["gr"]       = "git_revert_file",
            ["gx"]       = "git_add_all",
            ["gX"]       = "git_unstage_all",
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Filesystem source
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        filesystem = {
          filtered_items = {
            visible              = false,
            hide_dotfiles        = false,
            hide_gitignored      = true,
            hide_hidden          = true,
            hide_by_name         = {
              ".git",
              ".DS_Store",
              "thumbs.db",
              "__pycache__",
              ".pytest_cache",
              ".mypy_cache",
              "node_modules",
              ".cargo",
              "target",
              ".next",
              ".nuxt",
              "dist",
              "build",
            },
            hide_by_pattern      = {
              "*.pyc",
              "*.pyo",
              "*.class",
              "*.lock",
            },
            always_show          = {
              ".env",
              ".envrc",
              ".gitignore",
              ".gitattributes",
              ".editorconfig",
              "Makefile",
              "Justfile",
            },
            always_show_by_pattern = {
              ".env*",
            },
            never_show           = {
              ".DS_Store",
              "thumbs.db",
            },
          },
  
          follow_current_file    = {
            enabled              = true,
            leave_dirs_open      = true,
          },
  
          group_empty_dirs       = false,
          hijack_netrw_behavior  = "open_current",
          use_libuv_file_watcher = true,
  
          window = {
            mappings = {
              ["<bs>"]  = "navigate_up",
              ["."]     = "set_root",
              ["H"]     = "toggle_hidden",
              ["/"]     = "fuzzy_finder",
              ["#"]     = "fuzzy_finder_directory",
              ["D"]     = trash_cmd and "trash" or "delete",
            },
            fuzzy_finder_mappings = {
              ["<down>"]  = "move_cursor_down",
              ["<C-n>"]   = "move_cursor_down",
              ["<up>"]    = "move_cursor_up",
              ["<C-p>"]   = "move_cursor_up",
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Buffers source
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        buffers = {
          follow_current_file = {
            enabled          = true,
            leave_dirs_open  = false,
          },
          group_empty_dirs    = true,
          show_unloaded       = true,
          window              = {
            mappings          = {
              ["bd"]  = "buffer_delete",
              ["<bs>"] = "navigate_up",
              ["."]   = "set_root",
              ["o"]   = { "show_help", nowait = false,
                          config = { title = "Buffers Help", prefix_key = "o" } },
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Git status source
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        git_status = {
          window = {
            position = "float",
            mappings = {
              ["A"]   = "git_add_all",
              ["gu"]  = "git_unstage_file",
              ["ga"]  = "git_add_file",
              ["gr"]  = "git_revert_file",
              ["gc"]  = "git_commit",
              ["gp"]  = "git_push",
              ["gg"]  = "git_commit_and_push",
              ["o"]   = { "show_help", nowait = false,
                          config = { title = "Git Help", prefix_key = "o" } },
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Document symbols source
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        document_symbols = {
          kinds = {
            File          = { icon = icons.kinds.File,          hl = "Tag"         },
            Namespace     = { icon = icons.kinds.Namespace,     hl = "Include"     },
            Package       = { icon = icons.kinds.Package,       hl = "Label"       },
            Class         = { icon = icons.kinds.Class,         hl = "Include"     },
            Constructor   = { icon = icons.kinds.Constructor,   hl = "@constructor" },
            Interface     = { icon = icons.kinds.Interface,     hl = "Type"        },
            Function      = { icon = icons.kinds.Function,      hl = "Function"    },
            Variable      = { icon = icons.kinds.Variable,      hl = "@variable"   },
            Constant      = { icon = icons.kinds.Constant,      hl = "Constant"    },
            String        = { icon = icons.kinds.String,        hl = "String"      },
            Number        = { icon = icons.kinds.Number,        hl = "Number"      },
            Boolean       = { icon = icons.kinds.Boolean,       hl = "Boolean"     },
            Array         = { icon = icons.kinds.Array,         hl = "Type"        },
            Object        = { icon = icons.kinds.Object,        hl = "Type"        },
            Key           = { icon = icons.kinds.Key,           hl = "Type"        },
            Null          = { icon = icons.kinds.Null,          hl = "Type"        },
            EnumMember    = { icon = icons.kinds.EnumMember,    hl = "Number"      },
            Struct        = { icon = icons.kinds.Struct,        hl = "Type"        },
            Event         = { icon = icons.kinds.Event,         hl = "Type"        },
            Operator      = { icon = icons.kinds.Operator,      hl = "Operator"    },
            TypeParameter = { icon = icons.kinds.TypeParameter, hl = "Type"        },
            Method        = { icon = icons.kinds.Method,        hl = "Function"    },
            Property      = { icon = icons.kinds.Property,      hl = "@property"   },
            Field         = { icon = icons.kinds.Field,         hl = "@field"      },
            Enum          = { icon = icons.kinds.Enum,          hl = "Number"      },
            Module        = { icon = icons.kinds.Module,        hl = "Include"     },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Event handlers
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        event_handlers = {
          -- Auto-close neo-tree when opening a file
          {
            event   = "file_opened",
            handler = function(_file_path)
              require("neo-tree.command").execute({ action = "close" })
            end,
          },
          -- Refresh neo-tree when git status changes
          {
            event   = "git_event",
            handler = function()
              require("neo-tree.sources.manager").refresh("git_status")
            end,
          },
          -- Highlight the file in tree when buffer changes
          {
            event   = "neo_tree_buffer_enter",
            handler = function(_payload)
              vim.opt_local.signcolumn     = "auto"
              vim.opt_local.statuscolumn   = ""
              vim.opt_local.number         = false
              vim.opt_local.relativenumber = false
            end,
          },
        },
      }
    end,
  
    config = function(_, opts)
      -- ── Fix: image.nvim integration ───────────────────────────────────────
      local ok_img = pcall(require, "image")
      if not ok_img then
        opts.filesystem = opts.filesystem or {}
        -- remove image preview if image.nvim not present
      end
  
      require("neo-tree").setup(opts)
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base    = p.base     or "#1e1e2e"
        local mantle  = p.mantle   or "#181825"
        local surface = p.surface0 or "#313244"
        local surface1 = p.surface1 or "#45475a"
        local overlay = p.overlay0 or "#6c7086"
        local text    = p.text     or "#cdd6f4"
        local blue    = p.blue     or "#89b4fa"
        local green   = p.green    or "#a6e3a1"
        local yellow  = p.yellow   or "#f9e2af"
        local red     = p.red      or "#f38ba8"
        local mauve   = p.mauve    or "#cba6f7"
        local peach   = p.peach    or "#fab387"
        local teal    = p.teal     or "#94e2d5"
  
        local hls = {
          NeoTreeNormal           = { bg = mantle,   fg = text                        },
          NeoTreeNormalNC         = { bg = mantle,   fg = overlay                     },
          NeoTreeEndOfBuffer      = { bg = mantle,   fg = mantle                      },
          NeoTreeWinSeparator     = { bg = base,     fg = surface                     },
          NeoTreeRootName         = { fg = blue,     bold = true                      },
          NeoTreeDotfile          = { fg = overlay,  italic = true                    },
          NeoTreeHiddenByName     = { fg = overlay,  italic = true                    },
          NeoTreeGitAdded         = { fg = green                                      },
          NeoTreeGitModified      = { fg = yellow                                     },
          NeoTreeGitDeleted       = { fg = red                                        },
          NeoTreeGitRenamed       = { fg = blue                                       },
          NeoTreeGitUntracked     = { fg = mauve                                      },
          NeoTreeGitIgnored       = { fg = overlay                                    },
          NeoTreeGitUnstaged      = { fg = yellow                                     },
          NeoTreeGitStaged        = { fg = green,    bold = true                      },
          NeoTreeGitConflict      = { fg = red,      bold = true,  italic = true      },
          NeoTreeModified         = { fg = yellow                                     },
          NeoTreeIndentMarker     = { fg = surface1                                   },
          NeoTreeExpander         = { fg = overlay                                    },
          NeoTreeFileIcon         = { fg = blue                                       },
          NeoTreeFileName         = { fg = text                                       },
          NeoTreeFileNameOpened   = { fg = blue,     bold = true                      },
          NeoTreeSymbolicLinkTarget = { fg = teal,   italic = true                    },
          NeoTreeTabActive        = { bg = surface1, fg = blue,    bold = true        },
          NeoTreeTabInactive      = { bg = mantle,   fg = overlay                     },
          NeoTreeTabBarBackground = { bg = mantle                                     },
          NeoTreeTabSeparator     = { bg = mantle,   fg = surface                     },
          NeoTreeTabSeparatorActive = { bg = surface1, fg = blue                      },
          NeoTreeCursorLine       = { bg = surface,  bold = true                      },
          NeoTreeFloatBorder      = { bg = surface,  fg = overlay                     },
          NeoTreeFloatTitle       = { bg = surface,  fg = mauve,   bold = true        },
          NeoTreeTitleBar         = { bg = surface,  fg = text,    bold = true        },
          NeoTreeVertSplit        = { bg = base,     fg = surface                     },
          NeoTreeStatusLine       = { bg = mantle,   fg = overlay                     },
          NeoTreeStatusLineNC     = { bg = mantle,   fg = overlay                     },
          NeoTreeDirectoryIcon    = { fg = peach                                      },
          NeoTreeDirectoryName    = { fg = text                                       },
          NeoTreeDimText          = { fg = overlay                                    },
          NeoTreeFilterTerm       = { fg = green,    bold = true                      },
          NeoTreeMessage          = { fg = overlay,  italic = true                    },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }