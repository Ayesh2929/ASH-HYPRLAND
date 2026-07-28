-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/plugins/editor/treesitter.lua — Syntax Tree & Highlighting             ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Plugin: nvim-treesitter/nvim-treesitter                                     ║
-- ║                                                                              ║
-- ║  Companion plugins:                                                          ║
-- ║    nvim-treesitter-context    — sticky function header                      ║
-- ║    nvim-treesitter-textobjects — smart text objects                         ║
-- ║    nvim-ts-autotag            — auto close / rename HTML tags               ║
-- ║    ts-comments.nvim           — context-aware comment strings               ║
-- ║    rainbow-delimiters         — rainbow brackets                            ║
-- ║                                                                              ║
-- ║  Features:                                                                   ║
-- ║    • 60+ language parsers auto-installed                                    ║
-- ║    • Incremental selection via Treesitter nodes                              ║
-- ║    • Smart text objects: @function.inner / @class.outer etc.               ║
-- ║    • Swap: move arguments / parameters left / right                        ║
-- ║    • Goto next/prev function / class / block / conditional                 ║
-- ║    • Large-file guard: TS disabled above 512KB                              ║
-- ║    • Catppuccin integration for rainbow delimiters                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

---@type LazyPluginSpec[]
return {
    -- ── Main treesitter plugin ─────────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter",
      version      = false,
      build        = ":TSUpdate",
      event        = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
      lazy         = vim.fn.argc(-1) == 0,   -- load immediately when file passed as arg
      cmd          = {
        "TSInstall",
        "TSBufEnable",
        "TSBufDisable",
        "TSModuleInfo",
        "TSUpdate",
        "TSUpdateSync",
      },
      dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
        "nvim-treesitter/nvim-treesitter-context",
        "windwp/nvim-ts-autotag",
        "HiPhish/rainbow-delimiters.nvim",
        "JoosepAlviste/nvim-ts-context-commentstring",
        "RRethy/nvim-treesitter-endwise",
      },
  
      keys = {
        -- Incremental selection
        { "<C-space>", desc = "TS: Increment selection"     },
        { "<bs>",      desc = "TS: Decrement selection", mode = "x" },
        -- Text-object navigation
        { "]f",  desc = "  Next function"      },
        { "[f",  desc = "  Prev function"      },
        { "]c",  desc = "  Next class"         },
        { "[c",  desc = "  Prev class"         },
        { "]b",  desc = "  Next block"         },
        { "[b",  desc = "  Prev block"         },
        { "]a",  desc = "  Next argument"      },
        { "[a",  desc = "  Prev argument"      },
        -- Swap
        { "<leader>ra", desc = "  Swap next argument"  },
        { "<leader>rA", desc = "  Swap prev argument"  },
        { "<leader>rp", desc = "  Swap next parameter" },
        { "<leader>rP", desc = "  Swap prev parameter" },
      },
  
      opts = {
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Parsers to auto-install (ensure = always install if missing)
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        ensure_installed = {
          -- ── Systems languages ─────────────────────────────────────────
          "rust", "c", "cpp", "go", "zig",
          -- ── Scripting ─────────────────────────────────────────────────
          "python", "lua", "bash", "fish", "zsh",
          -- ── Web ───────────────────────────────────────────────────────
          "javascript", "typescript", "tsx", "jsx",
          "html", "css", "scss", "svelte", "vue", "astro",
          "graphql", "prisma",
          -- ── JVM / Mobile ──────────────────────────────────────────────
          "java", "kotlin", "groovy", "scala",
          -- ── Functional ────────────────────────────────────────────────
          "haskell", "elixir", "erlang", "gleam", "ocaml",
          "clojure", "scheme", "racket",
          -- ── Data / Config ─────────────────────────────────────────────
          "json", "jsonc", "yaml", "toml", "ini", "csv", "tsv",
          "xml", "html",
          -- ── DevOps / Infra ────────────────────────────────────────────
          "dockerfile", "hcl", "terraform",
          "nix", "puppet", "ruby",
          -- ── Docs / Prose ──────────────────────────────────────────────
          "markdown", "markdown_inline", "latex",
          "org", "rst", "asciidoc",
          -- ── Shell / System ────────────────────────────────────────────
          "make", "cmake", "just",
          "awk", "sed", "regex",
          -- ── Git ───────────────────────────────────────────────────────
          "git_config", "git_rebase", "gitcommit",
          "gitignore", "gitattributes",
          -- ── Neovim specific ───────────────────────────────────────────
          "vim", "vimdoc", "luadoc", "luap",
          -- ── Query languages ───────────────────────────────────────────
          "sql", "sparql",
          -- ── Shader ────────────────────────────────────────────────────
          "glsl", "wgsl",
          -- ── Misc ──────────────────────────────────────────────────────
          "hyprlang", "rasi", "kdl",
          "comment", "diff", "editorconfig",
          "ssh_config", "tmux", "desktop",
        },
  
        -- Auto-install missing parsers
        auto_install = true,
  
        -- ── Highlighting ──────────────────────────────────────────────────
        highlight = {
          enable   = true,
          -- Additional vim regex highlighting for indentation (some edge cases)
          additional_vim_regex_highlighting = { "markdown", "org" },
          -- Large file guard
          disable  = function(lang, buf)
            if vim.b[buf].large_file then return true end
            local max_filesize = Ash.perf.ts_max_file_size -- 512 KB
            local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              vim.b[buf].large_file = true
              return true
            end
            return false
          end,
        },
  
        -- ── Indentation ──────────────────────────────────────────────────
        indent = {
          enable  = true,
          disable = { "python", "yaml" },  -- these have better native indent
        },
  
        -- ── Incremental selection ─────────────────────────────────────────
        incremental_selection = {
          enable  = true,
          keymaps = {
            init_selection    = "<C-space>",
            node_incremental  = "<C-space>",
            scope_incremental = "<C-s>",
            node_decremental  = "<bs>",
          },
        },
  
        -- ── Auto-tag (HTML / JSX / TSX) ───────────────────────────────────
        autotag = {
          enable        = true,
          enable_rename = true,
          enable_close  = true,
          enable_close_on_slash = false,
          filetypes     = {
            "html", "xml", "jsx", "tsx",
            "svelte", "vue", "astro",
            "javascript", "typescript",
            "javascriptreact", "typescriptreact",
            "markdown",
          },
        },
  
        -- ── Endwise (auto end / endif / done) ────────────────────────────
        endwise = {
          enable = true,
        },
  
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        -- Text objects
        -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        textobjects = {
          -- ── Select ────────────────────────────────────────────────────
          select = {
            enable    = true,
            lookahead = true,   -- jump forward to next textobject
            keymaps   = {
              -- Function
              ["af"] = { query = "@function.outer",   desc = "around function" },
              ["if"] = { query = "@function.inner",   desc = "inside function" },
              -- Class
              ["ac"] = { query = "@class.outer",      desc = "around class"    },
              ["ic"] = { query = "@class.inner",       desc = "inside class"    },
              -- Block / scope
              ["ab"] = { query = "@block.outer",      desc = "around block"    },
              ["ib"] = { query = "@block.inner",       desc = "inside block"    },
              -- Conditional
              ["ai"] = { query = "@conditional.outer", desc = "around if"      },
              ["ii"] = { query = "@conditional.inner", desc = "inside if"      },
              -- Loop
              ["al"] = { query = "@loop.outer",        desc = "around loop"    },
              ["il"] = { query = "@loop.inner",        desc = "inside loop"    },
              -- Parameter / argument
              ["aa"] = { query = "@parameter.outer",   desc = "around argument" },
              ["ia"] = { query = "@parameter.inner",   desc = "inside argument" },
              -- Call
              ["aF"] = { query = "@call.outer",        desc = "around call"    },
              ["iF"] = { query = "@call.inner",        desc = "inside call"    },
              -- Comment
              ["aK"] = { query = "@comment.outer",     desc = "around comment" },
              ["iK"] = { query = "@comment.inner",     desc = "inside comment" },
              -- Attribute / decorator
              ["aA"] = { query = "@attribute.outer",   desc = "around attribute" },
              ["iA"] = { query = "@attribute.inner",   desc = "inside attribute" },
              -- Assignment
              ["a="] = { query = "@assignment.outer",  desc = "around assignment" },
              ["i="] = { query = "@assignment.inner",  desc = "inside assignment" },
              ["l="] = { query = "@assignment.lhs",    desc = "assignment LHS"   },
              ["r="] = { query = "@assignment.rhs",    desc = "assignment RHS"   },
              -- Number
              ["an"] = { query = "@number.inner",      desc = "around number"  },
            },
            -- Wrap: include surrounding whitespace in selection
            selection_modes = {
              ["@parameter.outer"] = "v",
              ["@function.outer"]  = "V",
              ["@class.outer"]     = "<C-v>",
            },
            include_surrounding_whitespace = true,
          },
  
          -- ── Swap ──────────────────────────────────────────────────────
          swap = {
            enable  = true,
            swap_next = {
              ["<leader>ra"] = { query = "@parameter.inner", desc = "Swap next argument"  },
              ["<leader>rp"] = { query = "@property.outer",  desc = "Swap next property"  },
              ["<leader>rf"] = { query = "@function.outer",  desc = "Swap next function"  },
            },
            swap_previous = {
              ["<leader>rA"] = { query = "@parameter.inner", desc = "Swap prev argument"  },
              ["<leader>rP"] = { query = "@property.outer",  desc = "Swap prev property"  },
              ["<leader>rF"] = { query = "@function.outer",  desc = "Swap prev function"  },
            },
          },
  
          -- ── Move ──────────────────────────────────────────────────────
          move = {
            enable              = true,
            set_jumps           = true,    -- add to jumplist
            goto_next_start = {
              ["]f"] = { query = "@function.outer",    desc = "Next function start"    },
              ["]c"] = { query = "@class.outer",       desc = "Next class start"       },
              ["]b"] = { query = "@block.outer",       desc = "Next block start"       },
              ["]a"] = { query = "@parameter.inner",   desc = "Next argument start"    },
              ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
              ["]l"] = { query = "@loop.outer",        desc = "Next loop start"        },
              ["]s"] = { query = "@scope",             desc = "Next scope",   query_group = "locals" },
              ["]z"] = { query = "@fold",              desc = "Next fold",    query_group = "folds"  },
            },
            goto_next_end = {
              ["]F"] = { query = "@function.outer",    desc = "Next function end"      },
              ["]C"] = { query = "@class.outer",       desc = "Next class end"         },
              ["]B"] = { query = "@block.outer",       desc = "Next block end"         },
            },
            goto_previous_start = {
              ["[f"] = { query = "@function.outer",    desc = "Prev function start"    },
              ["[c"] = { query = "@class.outer",       desc = "Prev class start"       },
              ["[b"] = { query = "@block.outer",       desc = "Prev block start"       },
              ["[a"] = { query = "@parameter.inner",   desc = "Prev argument start"    },
              ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
              ["[l"] = { query = "@loop.outer",        desc = "Prev loop start"        },
              ["[s"] = { query = "@scope",             desc = "Prev scope",   query_group = "locals" },
              ["[z"] = { query = "@fold",              desc = "Prev fold",    query_group = "folds"  },
            },
            goto_previous_end = {
              ["[F"] = { query = "@function.outer",    desc = "Prev function end"      },
              ["[C"] = { query = "@class.outer",       desc = "Prev class end"         },
              ["[B"] = { query = "@block.outer",       desc = "Prev block end"         },
            },
          },
  
          -- ── LSP interop ───────────────────────────────────────────────
          lsp_interop = {
            enable          = true,
            border          = "rounded",
            floating_preview_opts = {},
            peek_definition_code = {
              ["<leader>pf"] = "@function.outer",
              ["<leader>pc"] = "@class.outer",
            },
          },
        },
      },
  
      config = function(_, opts)
        -- ── ts-context-commentstring setup (must be before TS) ─────────────
        require("ts_context_commentstring").setup({
          enable_autocmd = false,
        })
  
        -- ── Patch vim.filetype for hyprlang ──────────────────────────────
        -- TS parser for hyprlang may not register automatically
        vim.treesitter.language.register("hyprlang", "hyprlang")
  
        -- ── Main setup ────────────────────────────────────────────────────
        require("nvim-treesitter.configs").setup(opts)
  
        -- ── Folding: use TS expr ──────────────────────────────────────────
        vim.opt.foldmethod = "expr"
        vim.opt.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
        vim.opt.foldlevel  = 99
  
        -- ── Move: repeatable with ; and , ────────────────────────────────
        local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
        vim.keymap.set({ "n", "x", "o" }, ";",  ts_repeat_move.repeat_last_move)
        vim.keymap.set({ "n", "x", "o" }, ",",  ts_repeat_move.repeat_last_move_opposite)
        -- Override f/t/F/T to be repeatable with ;/,
        vim.keymap.set({ "n", "x", "o" }, "f",  ts_repeat_move.builtin_f_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "F",  ts_repeat_move.builtin_F_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "t",  ts_repeat_move.builtin_t_expr, { expr = true })
        vim.keymap.set({ "n", "x", "o" }, "T",  ts_repeat_move.builtin_T_expr, { expr = true })
      end,
    },
  
    -- ── Treesitter context ─────────────────────────────────────────────────
    {
      "nvim-treesitter/nvim-treesitter-context",
      event = { "BufReadPost", "BufNewFile" },
      keys = {
        {
          "<leader>ut",
          function()
            local tsc = require("treesitter-context")
            tsc.toggle()
            vim.notify(
              (require("treesitter-context.config").get("enabled") and " " or "󰅖 ")
                .. "Treesitter context " ..
                (require("treesitter-context.config").get("enabled") and "on" or "off"),
              vim.log.levels.INFO,
              { title = "ASH NeoVim" }
            )
          end,
          desc = "  Toggle treesitter context",
        },
        {
          "[C",
          function() require("treesitter-context").go_to_context(vim.v.count1) end,
          desc = "  Jump to context",
        },
      },
      opts = {
        enable          = true,
        max_lines       = 4,           -- max lines of context
        min_window_height = 20,        -- min window height to show context
        line_numbers    = true,
        multiline_threshold = 10,      -- collapse multiline nodes
        trim_scope      = "outer",
        mode            = "cursor",    -- "cursor" | "topline"
        separator       = nil,
        zindex          = 20,
        on_attach       = function(buf)
          -- Disable for large files
          return not vim.b[buf].large_file
        end,
      },
      config = function(_, opts)
        require("treesitter-context").setup(opts)
  
        -- Highlight group
        local function apply_hl()
          local p = {}
          pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
          vim.api.nvim_set_hl(0, "TreesitterContext", {
            bg     = p.mantle    or "#181825",
            italic = true,
          })
          vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", {
            bg  = p.mantle    or "#181825",
            fg  = p.overlay0  or "#6c7086",
          })
          vim.api.nvim_set_hl(0, "TreesitterContextSeparator", {
            fg  = p.surface0  or "#313244",
          })
          vim.api.nvim_set_hl(0, "TreesitterContextBottom", {
            underline = true,
            sp        = p.surface1 or "#45475a",
          })
        end
  
        apply_hl()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
      end,
    },
  
    -- ── Rainbow delimiters ─────────────────────────────────────────────────
    {
      "HiPhish/rainbow-delimiters.nvim",
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        local rainbow = require("rainbow-delimiters")
  
        -- ── Strategy map ────────────────────────────────────────────────
        require("rainbow-delimiters.setup").setup({
          strategy = {
            [""]            = rainbow.strategy["global"],
            commonlisp      = rainbow.strategy["local"],
          },
          query = {
            [""]            = "rainbow-delimiters",
            lua             = "rainbow-blocks",
            javascript      = "rainbow-delimiters-react",
            typescript      = "rainbow-delimiters-react",
            tsx             = "rainbow-delimiters-react",
          },
          priority = {
            [""]   = 110,
            lua    = 210,
          },
          highlight = {
            "RainbowDelimiterRed",
            "RainbowDelimiterYellow",
            "RainbowDelimiterBlue",
            "RainbowDelimiterOrange",
            "RainbowDelimiterGreen",
            "RainbowDelimiterViolet",
            "RainbowDelimiterCyan",
          },
        })
  
        -- ── Highlight groups from Catppuccin palette ─────────────────────
        local function apply_hl()
          local p = {}
          pcall(function() p = require("catppuccin.palettes").get_palette() or {} end)
  
          local rainbow_colours = {
            p.red    or "#f38ba8",
            p.yellow or "#f9e2af",
            p.blue   or "#89b4fa",
            p.peach  or "#fab387",
            p.green  or "#a6e3a1",
            p.mauve  or "#cba6f7",
            p.teal   or "#94e2d5",
          }
          local hl_names = {
            "RainbowDelimiterRed",
            "RainbowDelimiterYellow",
            "RainbowDelimiterBlue",
            "RainbowDelimiterOrange",
            "RainbowDelimiterGreen",
            "RainbowDelimiterViolet",
            "RainbowDelimiterCyan",
          }
          for i, name in ipairs(hl_names) do
            vim.api.nvim_set_hl(0, name, {
              fg        = rainbow_colours[i],
              nocombine = true,
            })
          end
        end
  
        apply_hl()
        vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })
      end,
    },
  }