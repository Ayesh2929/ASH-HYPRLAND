-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/editor/telescope.lua — Fuzzy Finder                            ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: nvim-telescope/telescope.nvim                                       ║
-- ║                                                                              ║
-- ║  Extensions loaded:                                                          ║
-- ║    fzf              — C-based fuzzy sort (10x faster)                       ║
-- ║    file_browser     — built-in file manager                                 ║
-- ║    ui-select        — vim.ui.select replacement                             ║
-- ║    notify           — notification history                                  ║
-- ║    noice            — noice message history                                 ║
-- ║    project          — project switcher                                      ║
-- ║    frecency         — frequency + recency ranked MRU                        ║
-- ║    undo             — undo tree browser                                     ║
-- ║    aerial           — aerial symbol picker                                  ║
-- ║    import           — auto-import picker                                    ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • Catppuccin borderless / bordered / ivy / dropdown layouts              ║
-- ║    • Live grep with type filtering                                           ║
-- ║    • Multi-select with trouble integration                                   ║
-- ║    • 50+ keymaps organised by category                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec
return {
    "nvim-telescope/telescope.nvim",
    cmd          = "Telescope",
    version      = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond  = function() return vim.fn.executable("make") == 1 end,
      },
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-project.nvim",
      "nvim-tree/nvim-web-devicons",
      "rcarriga/nvim-notify",
      "debugloop/telescope-undo.nvim",
      "stevearc/aerial.nvim",
      "tsakirist/telescope-lazy.nvim",
    },
  
    keys = {
      -- ── Files ─────────────────────────────────────────────────────────────
      { "<leader>ff",  "<Cmd>Telescope find_files<CR>",                                    desc = "  Find files"                  },
      { "<leader>fF",  "<Cmd>Telescope find_files hidden=true no_ignore=true<CR>",         desc = "  Find all files (hidden)"     },
      { "<leader>fr",  "<Cmd>Telescope oldfiles<CR>",                                      desc = "  Recent files"                },
      { "<leader>fn",  "<Cmd>enew<CR>",                                                    desc = "  New file"                    },
      { "<leader>fc",  function() require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") }) end, desc = "  Find config files" },
  
      -- ── Search / Grep ─────────────────────────────────────────────────────
      { "<leader>sg",  "<Cmd>Telescope live_grep<CR>",                                     desc = "  Live grep"                   },
      { "<leader>sG",  "<Cmd>Telescope live_grep glob_pattern=!{node_modules,.git}<CR>",   desc = "  Live grep (filtered)"        },
      { "<leader>sw",  "<Cmd>Telescope grep_string<CR>",                                   desc = "  Grep word under cursor"      },
      { "<leader>sW",  function()
          require("telescope.builtin").grep_string({
            word_match = "-w",
            search     = vim.fn.expand("<cword>"),
          })
        end,                                                                                desc = "  Grep exact word"            },
      { "<leader>sw",  "<Cmd>Telescope grep_string<CR>",                                   mode = "v",  desc = "  Grep selection"  },
      { "<leader>s/",  function()
          require("telescope.builtin").live_grep({
            grep_open_files  = true,
            prompt_title     = "Live Grep (Open Files)",
          })
        end,                                                                                desc = "  Grep open files"            },
  
      -- ── Git ───────────────────────────────────────────────────────────────
      { "<leader>gc",  "<Cmd>Telescope git_commits<CR>",                                   desc = "  Git commits"                 },
      { "<leader>gC",  "<Cmd>Telescope git_bcommits<CR>",                                  desc = "  Git buffer commits"          },
      { "<leader>gb",  "<Cmd>Telescope git_branches<CR>",                                  desc = "  Git branches"                },
      { "<leader>gS",  "<Cmd>Telescope git_status<CR>",                                   desc = "  Git status"                  },
      { "<leader>gs",  "<Cmd>Telescope git_stash<CR>",                                    desc = "  Git stash"                   },
  
      -- ── LSP ───────────────────────────────────────────────────────────────
      { "<leader>ss",  "<Cmd>Telescope lsp_document_symbols<CR>",                          desc = "  Document symbols"            },
      { "<leader>sS",  "<Cmd>Telescope lsp_dynamic_workspace_symbols<CR>",                 desc = "  Workspace symbols"           },
      { "<leader>sr",  "<Cmd>Telescope lsp_references<CR>",                                desc = "  References"                  },
      { "<leader>sd",  "<Cmd>Telescope lsp_definitions<CR>",                               desc = "  Definitions"                 },
      { "<leader>sD",  "<Cmd>Telescope lsp_type_definitions<CR>",                          desc = "  Type definitions"            },
      { "<leader>si",  "<Cmd>Telescope lsp_implementations<CR>",                           desc = "  Implementations"             },
      { "<leader>sx",  "<Cmd>Telescope diagnostics<CR>",                                   desc = "  Diagnostics (workspace)"     },
      { "<leader>sX",  "<Cmd>Telescope diagnostics bufnr=0<CR>",                           desc = "  Diagnostics (buffer)"        },
  
      -- ── Vim builtins ──────────────────────────────────────────────────────
      { "<leader>sb",  "<Cmd>Telescope buffers sort_mru=true sort_lastused=true<CR>",      desc = "  Buffers"                     },
      { "<leader>sk",  "<Cmd>Telescope keymaps<CR>",                                       desc = "󰌌  Keymaps"                    },
      { "<leader>sm",  "<Cmd>Telescope marks<CR>",                                         desc = "  Marks"                       },
      { "<leader>sj",  "<Cmd>Telescope jumplist<CR>",                                      desc = "  Jump list"                   },
      { "<leader>sR",  "<Cmd>Telescope registers<CR>",                                     desc = "  Registers"                   },
      { "<leader>sc",  "<Cmd>Telescope command_history<CR>",                               desc = "  Command history"             },
      { "<leader>so",  "<Cmd>Telescope vim_options<CR>",                                   desc = "  Vim options"                 },
      { "<leader>sO",  "<Cmd>Telescope colorscheme<CR>",                                   desc = "  Colorschemes"                },
      { "<leader>sa",  "<Cmd>Telescope autocommands<CR>",                                  desc = "  Autocommands"                },
      { "<leader>sH",  "<Cmd>Telescope highlights<CR>",                                    desc = "  Highlight groups"            },
      { "<leader>sh",  "<Cmd>Telescope help_tags<CR>",                                     desc = "  Help tags"                   },
      { "<leader>sM",  "<Cmd>Telescope man_pages<CR>",                                     desc = "  Man pages"                   },
      { "<leader>s;",  "<Cmd>Telescope resume<CR>",                                        desc = "  Resume last search"          },
  
      -- ── Extensions ────────────────────────────────────────────────────────
      { "<leader>su",  "<Cmd>Telescope undo<CR>",                                          desc = "  Undo tree"                   },
      { "<leader>sp",  "<Cmd>Telescope project<CR>",                                       desc = "  Projects"                    },
      { "<leader>sn",  "<Cmd>Telescope notify<CR>",                                        desc = "  Notifications"               },
      { "<leader>sl",  "<Cmd>Telescope lazy<CR>",                                          desc = "  Lazy plugins"                },
      { "<leader>se",  "<Cmd>Telescope aerial<CR>",                                        desc = "  Aerial symbols"              },
      { "<leader>sf",  "<Cmd>Telescope file_browser<CR>",                                  desc = "  File browser"                },
      { "<leader>sF",  "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",   desc = "  File browser (file dir)"     },
  
      -- ── Quick search (no prefix) ──────────────────────────────────────────
      { "<C-p>",       "<Cmd>Telescope find_files<CR>",                                    desc = "  Find files (quick)"          },
      { "<leader><leader>", "<Cmd>Telescope buffers sort_mru=true<CR>",                    desc = "  Switch buffer"               },
    },
  
    opts = function()
      local actions      = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local icons        = Ash.icons
  
      -- ── Colour palette ────────────────────────────────────────────────────
      local p = {}
      pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
      local base    = p.base     or "#1e1e2e"
      local mantle  = p.mantle   or "#181825"
      local crust   = p.crust    or "#11111b"
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
  
      -- ── Custom actions ────────────────────────────────────────────────────
  
      -- Send selected items to Trouble
      local function send_to_trouble(prompt_bufnr)
        local ok, trouble = pcall(require, "trouble.sources.telescope")
        if ok then
          trouble.open(prompt_bufnr)
        else
          actions.send_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end
      end
  
      -- Flash integration: jump to result with flash
      local function flash_jump(prompt_bufnr)
        local ok, flash = pcall(require, "flash")
        if not ok then return end
        flash.jump({
          pattern     = "^",
          label       = { after = { 0, 0 } },
          search      = {
            mode      = "search",
            exclude   = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                  ~= "TelescopeResults"
              end,
            },
          },
          action      = function(match)
            local picker = action_state.get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end
  
      -- ── Layout: borderless (default) ──────────────────────────────────────
      local function make_layout_borderless()
        return {
          horizontal   = {
            prompt_position   = "top",
            preview_width     = 0.55,
            results_width     = 0.8,
            width             = 0.87,
            height            = 0.80,
            preview_cutoff    = 120,
          },
        }
      end
  
      -- ── Layout: ivy (bottom strip) ────────────────────────────────────────
      local function make_layout_ivy()
        return {
          bottom_pane  = {
            height            = 0.4,
            preview_cutoff    = 120,
            prompt_position   = "top",
          },
        }
      end
  
      return {
        defaults = {
          prompt_prefix    = " " .. icons.ui.Search .. " ",
          selection_caret  = icons.ui.ChevronRight .. " ",
          entry_prefix     = "  ",
          multi_icon       = icons.ui.Check .. " ",
          path_display     = { "truncate" },
          sorting_strategy = "ascending",
          layout_strategy  = "horizontal",
          layout_config    = make_layout_borderless(),
          results_title    = false,
          color_devicons   = true,
  
          -- Borderless style (matches Catppuccin integration)
          borderchars      = {
            prompt  = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
            results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
            preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          },
  
          winblend         = 0,
          file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.cargo/",
            "target/",
            "__pycache__/",
            "%.pytest_cache/",
            "dist/",
            "build/",
            "%.lock$",
            "%.min%.js$",
            "%.min%.css$",
          },
  
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!**/.git/*",
            "--glob=!**/node_modules/*",
            "--glob=!**/__pycache__/*",
            "--glob=!**/target/*",
            "--glob=!**/.cargo/*",
            "--trim",
          },
  
          -- ── Default mappings ─────────────────────────────────────────
          mappings = {
            i = {
              ["<C-n>"]       = actions.cycle_history_next,
              ["<C-p>"]       = actions.cycle_history_prev,
              ["<C-j>"]       = actions.move_selection_next,
              ["<C-k>"]       = actions.move_selection_previous,
              ["<C-c>"]       = actions.close,
              ["<Down>"]      = actions.move_selection_next,
              ["<Up>"]        = actions.move_selection_previous,
              ["<CR>"]        = actions.select_default,
              ["<C-x>"]       = actions.select_horizontal,
              ["<C-v>"]       = actions.select_vertical,
              ["<C-t>"]       = actions.select_tab,
              -- Multi-select
              ["<Tab>"]       = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"]     = actions.toggle_selection + actions.move_selection_better,
              ["<C-q>"]       = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"]       = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-l>"]       = actions.complete_tag,
              ["<C-_>"]       = actions.which_key,
              -- Preview scroll
              ["<C-u>"]       = actions.preview_scrolling_up,
              ["<C-d>"]       = actions.preview_scrolling_down,
              ["<C-f>"]       = actions.preview_scrolling_right,
              ["<C-b>"]       = actions.preview_scrolling_left,
              -- Page
              ["<PageUp>"]    = actions.results_scrolling_up,
              ["<PageDown>"]  = actions.results_scrolling_down,
              -- Trouble
              ["<C-t>"]       = send_to_trouble,
              -- Flash jump
              ["<C-s>"]       = flash_jump,
            },
            n = {
              ["<esc>"]       = actions.close,
              ["q"]           = actions.close,
              ["<CR>"]        = actions.select_default,
              ["<C-x>"]       = actions.select_horizontal,
              ["<C-v>"]       = actions.select_vertical,
              ["<C-t>"]       = actions.select_tab,
              ["<Tab>"]       = actions.toggle_selection + actions.move_selection_worse,
              ["<S-Tab>"]     = actions.toggle_selection + actions.move_selection_better,
              ["<C-q>"]       = actions.send_to_qflist + actions.open_qflist,
              ["<M-q>"]       = actions.send_selected_to_qflist + actions.open_qflist,
              ["j"]           = actions.move_selection_next,
              ["k"]           = actions.move_selection_previous,
              ["H"]           = actions.move_to_top,
              ["M"]           = actions.move_to_middle,
              ["L"]           = actions.move_to_bottom,
              ["<Down>"]      = actions.move_selection_next,
              ["<Up>"]        = actions.move_selection_previous,
              ["gg"]          = actions.move_to_top,
              ["G"]           = actions.move_to_bottom,
              ["<C-u>"]       = actions.preview_scrolling_up,
              ["<C-d>"]       = actions.preview_scrolling_down,
              ["<C-f>"]       = actions.preview_scrolling_right,
              ["<C-b>"]       = actions.preview_scrolling_left,
              ["<PageUp>"]    = actions.results_scrolling_up,
              ["<PageDown>"]  = actions.results_scrolling_down,
              ["?"]           = actions.which_key,
              ["<C-t>"]       = send_to_trouble,
              ["s"]           = flash_jump,
            },
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Picker overrides
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        pickers = {
          find_files = {
            hidden       = true,
            find_command = {
              "fd", "--type", "f",
              "--strip-cwd-prefix",
              "--hidden",
              "--follow",
              "--exclude", ".git",
              "--exclude", "node_modules",
              "--exclude", "__pycache__",
              "--exclude", "target",
              "--exclude", ".cargo",
            },
          },
  
          live_grep = {
            additional_args = function()
              return { "--hidden", "--follow" }
            end,
          },
  
          grep_string = {
            additional_args = { "--hidden", "--follow" },
          },
  
          buffers = {
            theme            = "dropdown",
            previewer        = false,
            sort_mru         = true,
            sort_lastused    = true,
            show_all_buffers = true,
            ignore_current_buffer = true,
            layout_config    = {
              width   = 0.5,
              height  = 0.5,
            },
            mappings = {
              i = { ["<C-d>"] = actions.delete_buffer },
              n = { ["dd"]    = actions.delete_buffer },
            },
          },
  
          git_commits = { theme = "ivy" },
          git_bcommits = { theme = "ivy" },
          git_branches = { theme = "ivy" },
          git_status   = { theme = "ivy" },
  
          lsp_references = {
            theme            = "dropdown",
            show_line        = false,
            layout_config    = { width = 0.7, height = 0.6 },
          },
  
          lsp_definitions = {
            show_line        = false,
            theme            = "dropdown",
          },
  
          diagnostics = {
            theme            = "ivy",
            initial_mode     = "normal",
            layout_config    = { preview_cutoff = 9999 },
          },
  
          colorscheme = {
            enable_preview = true,
          },
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Extension configs
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        extensions = {
          -- ── fzf: native C-based sorting ───────────────────────────────
          fzf = {
            fuzzy                  = true,
            override_generic_sorter = true,
            override_file_sorter   = true,
            case_mode              = "smart_case",
          },
  
          -- ── file_browser ──────────────────────────────────────────────
          file_browser = {
            theme            = "ivy",
            hijack_netrw     = true,
            hidden           = { file_browser = true, folder_browser = true },
            grouped          = true,
            files            = true,
            auto_depth       = true,
            select_buffer    = true,
            hide_parent_dir  = false,
            git_status       = true,
            mappings         = {
              i = {
                ["<C-h>"] = require("telescope._extensions.file_browser.actions").goto_parent_dir,
                ["<C-e>"] = require("telescope._extensions.file_browser.actions").create,
                ["<C-r>"] = require("telescope._extensions.file_browser.actions").rename,
                ["<C-d>"] = require("telescope._extensions.file_browser.actions").remove,
                ["<C-y>"] = require("telescope._extensions.file_browser.actions").copy,
                ["<C-m>"] = require("telescope._extensions.file_browser.actions").move,
              },
            },
          },
  
          -- ── ui-select ─────────────────────────────────────────────────
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({
              borderchars    = {
                prompt  = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
                results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
              },
              width          = 0.5,
              previewer      = false,
              prompt_title   = false,
            }),
          },
  
          -- ── undo tree ─────────────────────────────────────────────────
          undo = {
            side_by_side       = true,
            layout_strategy    = "vertical",
            layout_config      = {
              preview_height   = 0.8,
            },
            mappings = {
              i = {
                ["<CR>"]   = require("telescope-undo.actions").yank_additions,
                ["<S-CR>"] = require("telescope-undo.actions").yank_deletions,
                ["<C-CR>"] = require("telescope-undo.actions").restore,
              },
            },
          },
  
          -- ── project ───────────────────────────────────────────────────
          project = {
            base_dirs      = { "~/projects", "~/work" },
            hidden_files   = false,
            theme          = "dropdown",
            order_by       = "recent",
            search_by      = "full_path",
            sync_with_nvim_tree = true,
          },
        },
      }
    end,
  
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
  
      -- ── Load extensions ───────────────────────────────────────────────────
      local extensions = {
        "fzf",
        "file_browser",
        "ui-select",
        "notify",
        "project",
        "undo",
        "aerial",
        "lazy",
      }
      for _, ext in ipairs(extensions) do
        pcall(telescope.load_extension, ext)
      end
  
      -- ── Highlight groups ──────────────────────────────────────────────────
      local function apply_hl()
        local p = {}
        pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
        local base    = p.base     or "#1e1e2e"
        local mantle  = p.mantle   or "#181825"
        local crust   = p.crust    or "#11111b"
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
          -- ── Chrome ────────────────────────────────────────────────────
          TelescopeNormal           = { bg = base,    fg = text                        },
          TelescopeBorder           = { bg = base,    fg = base                        },
          TelescopePromptNormal     = { bg = mantle,  fg = text                        },
          TelescopePromptBorder     = { bg = mantle,  fg = mantle                      },
          TelescopePromptTitle      = { bg = blue,    fg = base,     bold = true       },
          TelescopePromptPrefix     = { bg = mantle,  fg = blue,     bold = true       },
          TelescopePromptCounter    = { bg = mantle,  fg = overlay,  italic = true     },
          TelescopePreviewNormal    = { bg = crust,   fg = text                        },
          TelescopePreviewBorder    = { bg = crust,   fg = crust                       },
          TelescopePreviewTitle     = { bg = teal,    fg = base,     bold = true       },
          TelescopeResultsNormal    = { bg = base,    fg = text                        },
          TelescopeResultsBorder    = { bg = base,    fg = base                        },
          TelescopeResultsTitle     = { bg = base,    fg = base                        },
          -- ── Selection ─────────────────────────────────────────────────
          TelescopeSelection        = { bg = surface, fg = text,     bold = true       },
          TelescopeSelectionCaret   = { bg = surface, fg = blue,     bold = true       },
          TelescopeMultiSelection   = { bg = surface, fg = mauve                       },
          TelescopeMultiIcon        = { fg = green                                     },
          -- ── Matching ──────────────────────────────────────────────────
          TelescopeMatching         = { fg = yellow,  bold = true                      },
          -- ── Previewers ────────────────────────────────────────────────
          TelescopePreviewLine      = { bg = surface1                                  },
          TelescopePreviewMatch     = { fg = yellow,  bold = true                      },
          TelescopePreviewPipe      = { fg = teal                                      },
          TelescopePreviewCharDev   = { fg = yellow                                    },
          TelescopePreviewDirectory = { fg = blue                                      },
          TelescopePreviewBlock     = { fg = red                                       },
          TelescopePreviewLink      = { fg = teal,    italic = true                    },
          TelescopePreviewSocket    = { fg = mauve                                     },
          TelescopePreviewRead      = { fg = overlay                                   },
          TelescopePreviewWrite     = { fg = green                                     },
          TelescopePreviewExecute   = { fg = peach,   bold = true                      },
          TelescopePreviewHyphen    = { fg = overlay                                   },
          TelescopePreviewSticky    = { fg = mauve                                     },
          TelescopePreviewSize      = { fg = teal                                      },
          TelescopePreviewUser      = { fg = yellow                                    },
          TelescopePreviewGroup     = { fg = peach                                     },
          TelescopePreviewDate      = { fg = blue                                      },
          TelescopePreviewMessage   = { fg = red,     bold = true                      },
          TelescopePreviewMessageFillchar = { fg = overlay                             },
        }
  
        for name, val in pairs(hls) do
          vim.api.nvim_set_hl(0, name, val)
        end
      end
  
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
    end,
  }