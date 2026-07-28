-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🎯 MINI.NVIM — ULTRA MODULAR MICRO-PLUGINS v5.0 OMEGA                    ║
-- ║   40+ mini modules · zero dependencies · blazing fast · ASH theme-aware        ║
-- ║   ai textobjects · animate · bufremove · clue · colors · files · icons         ║
-- ║   indentscope · move · operators · pairs · splitjoin · statusline · surround   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 SHARED HIGHLIGHT SETUP — ASH palette integration
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── mini.indentscope ──────────────────────────────────────────────────────
    hl(0, "MiniIndentscopeSymbol",       { link = "Comment"       })
    hl(0, "MiniIndentscopeSymbolOff",    { link = "NonText"       })
  
    -- ── mini.animate ──────────────────────────────────────────────────────────
    hl(0, "MiniAnimateCursor",           { reverse = true, nocombine = true })
    hl(0, "MiniAnimateNormalFloat",      { link = "NormalFloat"   })
  
    -- ── mini.clue ─────────────────────────────────────────────────────────────
    hl(0, "MiniClueBorder",              { link = "FloatBorder"   })
    hl(0, "MiniClueDescGroup",           { link = "DiagnosticHint"})
    hl(0, "MiniClueDescSingle",          { link = "NormalFloat"   })
    hl(0, "MiniClueNextKey",             { link = "DiagnosticInfo"})
    hl(0, "MiniClueNextKeyWithPostkeys", { link = "DiagnosticWarn"})
    hl(0, "MiniClueSeparator",           { link = "Comment"       })
    hl(0, "MiniClueTitle",               { bold = true            })
  
    -- ── mini.diff ─────────────────────────────────────────────────────────────
    hl(0, "MiniDiffSignAdd",             { link = "GitSignsAdd"    })
    hl(0, "MiniDiffSignChange",          { link = "GitSignsChange" })
    hl(0, "MiniDiffSignDelete",          { link = "GitSignsDelete" })
    hl(0, "MiniDiffOverAdd",             { link = "DiffAdd"        })
    hl(0, "MiniDiffOverChange",          { link = "DiffChange"     })
    hl(0, "MiniDiffOverContext",         { link = "DiffText"       })
    hl(0, "MiniDiffOverDelete",          { link = "DiffDelete"     })
  
    -- ── mini.files ────────────────────────────────────────────────────────────
    hl(0, "MiniFilesBorder",             { link = "FloatBorder"   })
    hl(0, "MiniFilesBorderModified",     { link = "DiagnosticWarn"})
    hl(0, "MiniFilesCursorLine",         { link = "CursorLine"    })
    hl(0, "MiniFilesDirectory",          { link = "Directory"     })
    hl(0, "MiniFilesFile",               { link = "Normal"        })
    hl(0, "MiniFilesNormal",             { link = "NormalFloat"   })
    hl(0, "MiniFilesTitle",              { bold = true            })
    hl(0, "MiniFilesTitleFocused",       { bold = true, reverse = true })
  
    -- ── mini.icons ────────────────────────────────────────────────────────────
    hl(0, "MiniIconsAzure",              { fg = "#7aa2f7"         })
    hl(0, "MiniIconsBlue",               { fg = "#89b4fa"         })
    hl(0, "MiniIconsCyan",               { fg = "#7dcfff"         })
    hl(0, "MiniIconsGreen",              { fg = "#9ece6a"         })
    hl(0, "MiniIconsGrey",               { fg = "#9399b2"         })
    hl(0, "MiniIconsOrange",             { fg = "#ff9e64"         })
    hl(0, "MiniIconsPurple",             { fg = "#bb9af7"         })
    hl(0, "MiniIconsRed",                { fg = "#f38ba8"         })
    hl(0, "MiniIconsYellow",             { fg = "#e0af68"         })
  
    -- ── mini.map ──────────────────────────────────────────────────────────────
    hl(0, "MiniMapNormal",               { link = "NormalFloat"   })
    hl(0, "MiniMapSymbolCount",          { link = "Special"       })
    hl(0, "MiniMapSymbolLine",           { link = "Title"         })
    hl(0, "MiniMapSymbolView",           { link = "Delimiter"     })
  
    -- ── mini.notify ───────────────────────────────────────────────────────────
    hl(0, "MiniNotifyBorder",            { link = "FloatBorder"   })
    hl(0, "MiniNotifyNormal",            { link = "NormalFloat"   })
    hl(0, "MiniNotifyTitle",             { bold = true            })
    hl(0, "MiniNotifyTitleError",        { bold = true, link = "DiagnosticError" })
    hl(0, "MiniNotifyTitleInfo",         { bold = true, link = "DiagnosticInfo"  })
    hl(0, "MiniNotifyTitleWarn",         { bold = true, link = "DiagnosticWarn"  })
    hl(0, "MiniNotifyTitleTrace",        { bold = true, link = "Comment"         })
  
    -- ── mini.pick ─────────────────────────────────────────────────────────────
    hl(0, "MiniPickBorder",              { link = "FloatBorder"   })
    hl(0, "MiniPickBorderBusy",          { link = "DiagnosticWarn"})
    hl(0, "MiniPickBorderText",          { bold = true            })
    hl(0, "MiniPickHeader",              { link = "DiagnosticInfo"})
    hl(0, "MiniPickIconDirectory",       { link = "Directory"     })
    hl(0, "MiniPickIconFile",            { link = "Normal"        })
    hl(0, "MiniPickMatchCurrent",        { link = "CursorLine"    })
    hl(0, "MiniPickMatchMarked",         { link = "Visual"        })
    hl(0, "MiniPickMatchRanges",         { link = "DiagnosticHint"})
    hl(0, "MiniPickNormal",              { link = "NormalFloat"   })
    hl(0, "MiniPickPreviewLine",         { link = "CursorLine"    })
    hl(0, "MiniPickPreviewRegion",       { link = "IncSearch"     })
    hl(0, "MiniPickPrompt",              { bold = true, link = "DiagnosticInfo" })
  
    -- ── mini.starter ──────────────────────────────────────────────────────────
    hl(0, "MiniStarterCurrent",          { link = "CursorLine"    })
    hl(0, "MiniStarterFooter",           { link = "Comment"       })
    hl(0, "MiniStarterHeader",           { bold = true, link = "Title" })
    hl(0, "MiniStarterInactive",         { link = "Comment"       })
    hl(0, "MiniStarterItem",             { link = "Normal"        })
    hl(0, "MiniStarterItemBullet",       { link = "Delimiter"     })
    hl(0, "MiniStarterItemPrefix",       { link = "DiagnosticHint"})
    hl(0, "MiniStarterQuery",            { link = "DiagnosticInfo"})
    hl(0, "MiniStarterSection",          { bold = true, link = "Keyword" })
  
    -- ── mini.statusline ───────────────────────────────────────────────────────
    hl(0, "MiniStatuslineDevinfo",       { link = "StatusLine"    })
    hl(0, "MiniStatuslineFileinfo",      { link = "StatusLine"    })
    hl(0, "MiniStatuslineFilename",      { link = "StatusLineNC"  })
    hl(0, "MiniStatuslineInactive",      { link = "StatusLineNC"  })
    hl(0, "MiniStatuslineModeNormal",    { bold = true, link = "Keyword"  })
    hl(0, "MiniStatuslineModeInsert",    { bold = true, link = "String"   })
    hl(0, "MiniStatuslineModeVisual",    { bold = true, link = "Function" })
    hl(0, "MiniStatuslineModeReplace",   { bold = true, link = "Constant" })
    hl(0, "MiniStatuslineModeCommand",   { bold = true, link = "Special"  })
    hl(0, "MiniStatuslineModeOther",     { bold = true, link = "Comment"  })
  
    -- ── mini.surround ─────────────────────────────────────────────────────────
    hl(0, "MiniSurroundHighlight",       { link = "IncSearch"     })
  
    -- ── mini.tabline ──────────────────────────────────────────────────────────
    hl(0, "MiniTablineCurrent",          { link = "TabLineSel"    })
    hl(0, "MiniTablineHidden",           { link = "TabLine"       })
    hl(0, "MiniTablineModifiedCurrent",  { bold = true, link = "TabLineSel" })
    hl(0, "MiniTablineModifiedHidden",   { link = "TabLine"       })
    hl(0, "MiniTablineModifiedVisible",  { link = "TabLineSel"    })
    hl(0, "MiniTablineTabpagesection",   { link = "Search"        })
    hl(0, "MiniTablineVisible",          { link = "TabLineSel"    })
  
    -- ── mini.trailspace ────────────────────────────────────────────────────────
    hl(0, "MiniTrailspace",              { link = "Error"         })
  
    -- ── mini.completion ────────────────────────────────────────────────────────
    hl(0, "MiniCompletionActiveParameter", { underline = true     })
  
    -- ── mini.cursorword ────────────────────────────────────────────────────────
    hl(0, "MiniCursorword",              { underline = true       })
    hl(0, "MiniCursorwordCurrent",       { underline = true       })
  
    -- ── mini.jump ─────────────────────────────────────────────────────────────
    hl(0, "MiniJump",                    { link = "Search"        })
    hl(0, "MiniJump2dDim",               { link = "Comment"       })
    hl(0, "MiniJump2dSpot",              { bold = true, nocombine = true, link = "Search" })
    hl(0, "MiniJump2dSpotAhead",         { nocombine = true, link = "DiagnosticInfo"     })
    hl(0, "MiniJump2dSpotUnique",        { bold = true, nocombine = true, link = "DiagnosticWarn" })
    hl(0, "MiniJump2dLabelUnique",       { bold = true, link = "Search" })
  
    -- ── mini.operators ─────────────────────────────────────────────────────────
    hl(0, "MiniOperatorsExchangeFrom",   { link = "IncSearch"     })
  
    -- ── mini.sessions ──────────────────────────────────────────────────────────
    -- (no specific highlights needed)
  
    -- ── mini.splitjoin ─────────────────────────────────────────────────────────
    -- (no specific highlights needed)
  
    -- ── mini.visits ───────────────────────────────────────────────────────────
    -- (no specific highlights needed)
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 MINI.AI — Advanced Textobjects
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_ai()
    return {
      "echasnovski/mini.ai",
      event   = { "BufReadPre", "BufNewFile" },
      version = false,
      opts    = function()
        local ai = require("mini.ai")
        return {
          -- Number of lines to search forward/backward for textobjects
          n_lines    = 500,
  
          -- Search method: "cover" | "cover_or_next" | "cover_or_prev" |
          --                "cover_or_nearest" | "next" | "prev" | "nearest"
          search_method = "cover_or_next",
  
          -- Custom textobjects
          custom_textobjects = {
            -- Whole buffer
            o = ai.gen_spec.treesitter({
              a = { "@block.outer",      "@conditional.outer", "@loop.outer"      },
              i = { "@block.inner",      "@conditional.inner", "@loop.inner"      },
            }),
            -- Functions
            f = ai.gen_spec.treesitter({
              a = "@function.outer",
              i = "@function.inner",
            }),
            -- Classes
            c = ai.gen_spec.treesitter({
              a = "@class.outer",
              i = "@class.inner",
            }),
            -- Comments
            C = ai.gen_spec.treesitter({
              a = "@comment.outer",
              i = "@comment.inner",
            }),
            -- Entire buffer  [buffer]
            B = function()
              local from  = { line = 1,                       col = 1 }
              local to    = { line = vim.fn.line("$"),         col = math.max(vim.fn.getline("$"):len(), 1) }
              return { from = from, to = to }
            end,
            -- Number (integer or float)
            N = ai.gen_spec.treesitter({
              a = "@number.outer",
              i = "@number.inner",
            }),
            -- Argument / parameter
            a = ai.gen_spec.treesitter({
              a = "@parameter.outer",
              i = "@parameter.inner",
            }),
            -- Key-value pair
            p = ai.gen_spec.treesitter({
              a = { "@pair.outer", "@field.outer" },
              i = { "@pair.inner", "@field.inner" },
            }),
            -- Return statement
            r = ai.gen_spec.treesitter({
              a = "@return.outer",
              i = "@return.inner",
            }),
            -- Backtick string
            ["`"] = ai.gen_spec.pair("`", "`", { type = "greedy" }),
            -- HTML / JSX tags
            t  = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
            -- Digits
            d  = { "%f[%d]%d+" },
            -- URL
            u  = {
              { "%f[%w]%w+://[%w%.%-_%+%?%%&=/#@]+%f[^%w]" },
            },
            -- Line (non-blank)
            L  = function(ai_type)
              local line_num = vim.fn.line(".")
              local line     = vim.fn.getline(line_num)
              if ai_type == "a" then
                return { from = { line = line_num, col = 1 },
                         to   = { line = line_num, col = line:len() } }
              end
              -- inner: exclude leading/trailing whitespace
              local from_col = line:find("%S") or 1
              local to_col   = line:match(".*%S()") or line:len()
              return { from = { line = line_num, col = from_col },
                       to   = { line = line_num, col = to_col   } }
            end,
          },
  
          -- Mappings: add/delete/replace inside/around  +  move/find
          mappings = {
            -- Main textobject prefixes
            around          = "a",
            inside          = "i",
            around_next     = "an",
            inside_next     = "in",
            around_last     = "al",
            inside_last     = "il",
            -- Move cursor to textobject
            goto_left       = "g[",
            goto_right      = "g]",
          },
        }
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎬 MINI.ANIMATE — Smooth Cursor & Scroll Animations
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_animate()
    return {
      "echasnovski/mini.animate",
      event   = "VeryLazy",
      version = false,
      opts    = function()
        local animate = require("mini.animate")
        local timing  = animate.gen_timing
  
        -- Helper: easing function (exponential out)
        local function ease_out(ratio)
          return math.pow(1 - ratio, 3) * 0 + (1 - math.pow(1 - ratio, 3)) * 1
        end
  
        return {
          -- ── Cursor ─────────────────────────────────────────────────────────
          cursor = {
            enable   = true,
            timing   = timing.linear({ duration = 80, unit = "total" }),
            path     = animate.gen_path.line({ predicate = function() return true end }),
          },
  
          -- ── Scroll ─────────────────────────────────────────────────────────
          scroll = {
            enable   = true,
            timing   = timing.linear({ duration = 120, unit = "total" }),
            subscroll = animate.gen_subscroll.equal({
              predicate = function(total_scroll)
                -- Only animate when scrolling more than 1 line
                return total_scroll > 1
              end,
            }),
          },
  
          -- ── Window resize ─────────────────────────────────────────────────
          resize = {
            enable   = true,
            timing   = timing.linear({ duration = 100, unit = "total" }),
            subresize = animate.gen_subresize.equal(),
          },
  
          -- ── Window open (float) ────────────────────────────────────────────
          open = {
            enable   = true,
            timing   = timing.linear({ duration = 150, unit = "total" }),
            winconfig = animate.gen_winconfig.wipe({ direction = "from_edge" }),
            winblend  = animate.gen_winblend.linear({ from = 80, to = 0 }),
          },
  
          -- ── Window close ──────────────────────────────────────────────────
          close = {
            enable   = true,
            timing   = timing.linear({ duration = 100, unit = "total" }),
            winconfig = animate.gen_winconfig.wipe({ direction = "to_edge" }),
            winblend  = animate.gen_winblend.linear({ from = 0, to = 80 }),
          },
        }
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🗑️  MINI.BUFREMOVE — Smart Buffer Deletion
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_bufremove()
    return {
      "echasnovski/mini.bufremove",
      version = false,
      keys    = {
        {
          "<leader>bd",
          function()
            local bd = require("mini.bufremove")
            if vim.bo.modified then
              local choice = vim.fn.confirm(
                "Save changes to " .. vim.fn.expand("%") .. "?",
                "&Yes\n&No\n&Cancel"
              )
              if choice == 1 then vim.cmd("write") end
              if choice ~= 3 then bd.delete(0, false) end
            else
              bd.delete(0, false)
            end
          end,
          desc = "🗑️  Delete Buffer",
        },
        {
          "<leader>bD",
          function() require("mini.bufremove").delete(0, true) end,
          desc = "🗑️  Delete Buffer (force)",
        },
        {
          "<leader>bu",
          function() require("mini.bufremove").unshow(0) end,
          desc = "🗑️  Unshow Buffer",
        },
        {
          "<leader>bw",
          function() require("mini.bufremove").wipeout(0, false) end,
          desc = "🗑️  Wipeout Buffer",
        },
      },
      opts = {},
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💡 MINI.CLUE — Contextual Keymap Hints (which-key alternative)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_clue()
    return {
      "echasnovski/mini.clue",
      version = false,
      event   = "VeryLazy",
      opts    = function()
        local clue      = require("mini.clue")
        local miniclue  = clue
  
        return {
          -- ── Triggers ──────────────────────────────────────────────────────
          triggers = {
            -- Leader combos
            { mode = "n", keys = "<Leader>"  },
            { mode = "x", keys = "<Leader>"  },
            -- Built-in completion
            { mode = "i", keys = "<C-x>"     },
            -- g-prefix
            { mode = "n", keys = "g"         },
            { mode = "x", keys = "g"         },
            -- Marks
            { mode = "n", keys = "'"         },
            { mode = "n", keys = "`"         },
            { mode = "x", keys = "'"         },
            { mode = "x", keys = "`"         },
            -- Registers
            { mode = "n", keys = '"'         },
            { mode = "x", keys = '"'         },
            { mode = "i", keys = "<C-r>"     },
            { mode = "c", keys = "<C-r>"     },
            -- Window commands
            { mode = "n", keys = "<C-w>"     },
            -- z-prefix
            { mode = "n", keys = "z"         },
            { mode = "x", keys = "z"         },
            -- Bracket navigation
            { mode = "n", keys = "["         },
            { mode = "n", keys = "]"         },
            -- ASH custom prefixes
            { mode = "n", keys = "<leader>a" },
            { mode = "n", keys = "<leader>h" },
            { mode = "n", keys = "<leader>j" },
          },
  
          -- ── Clues (group descriptions) ─────────────────────────────────────
          clues = {
            -- Built-ins
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers(),
            miniclue.gen_clues.windows(),
            miniclue.gen_clues.z(),
  
            -- Leader groups
            { mode = "n", keys = "<leader>b",  desc = "  Buffers"       },
            { mode = "n", keys = "<leader>c",  desc = "💬 Comments"     },
            { mode = "n", keys = "<leader>d",  desc = "  DAP Debug"     },
            { mode = "n", keys = "<leader>e",  desc = "󰙅  Explorer"     },
            { mode = "n", keys = "<leader>f",  desc = "🔭 Find/Files"   },
            { mode = "n", keys = "<leader>F",  desc = "⚡ FZF"          },
            { mode = "n", keys = "<leader>g",  desc = "  Git"          },
            { mode = "n", keys = "<leader>h",  desc = "🦘 Hop"         },
            { mode = "n", keys = "<leader>j",  desc = "⚡ Jump/Flash"  },
            { mode = "n", keys = "<leader>l",  desc = "  LSP"          },
            { mode = "n", keys = "<leader>m",  desc = "  Marks"        },
            { mode = "n", keys = "<leader>n",  desc = "  Notes/Neorg"  },
            { mode = "n", keys = "<leader>o",  desc = "  Open/Oil"     },
            { mode = "n", keys = "<leader>p",  desc = "󰏗  Package/Lazy" },
            { mode = "n", keys = "<leader>q",  desc = "  Quit/Session" },
            { mode = "n", keys = "<leader>r",  desc = "  Rename/Run"   },
            { mode = "n", keys = "<leader>s",  desc = "🔍 Search"      },
            { mode = "n", keys = "<leader>t",  desc = "📝 Todo/Test"   },
            { mode = "n", keys = "<leader>T",  desc = "🌳 Treesitter"  },
            { mode = "n", keys = "<leader>u",  desc = "  Toggle/UI"   },
            { mode = "n", keys = "<leader>w",  desc = "  Windows"     },
            { mode = "n", keys = "<leader>x",  desc = "🚨 Diagnostics" },
            { mode = "n", keys = "<leader>y",  desc = "  Yank"        },
            { mode = "n", keys = "<leader>z",  desc = "  Fold/Zen"    },
            { mode = "n", keys = "<leader>a",  desc = "🔥 ASH"        },
  
            -- x/visual leader
            { mode = "x", keys = "<leader>c",  desc = "💬 Comments"   },
            { mode = "x", keys = "<leader>g",  desc = "  Git"        },
            { mode = "x", keys = "<leader>s",  desc = "🔍 Search"    },
          },
  
          -- ── Window config ────────────────────────────────────────────────
          window = {
            delay          = 300,       -- ms before popup appears
            config         = {
              width        = "auto",
              border       = "rounded",
            },
            scroll_down    = "<C-d>",
            scroll_up      = "<C-u>",
          },
        }
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📊 MINI.DIFF — Inline Git Diff Signs
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_diff()
    return {
      "echasnovski/mini.diff",
      event   = { "BufReadPre", "BufNewFile" },
      version = false,
      keys    = {
        { "<leader>go", function() require("mini.diff").toggle_overlay(0) end,
          desc = "  Toggle Diff Overlay" },
      },
      opts = {
        -- ── View ──────────────────────────────────────────────────────────────
        view = {
          style       = "sign",
          signs       = { add = "▎", change = "▎", delete = "" },
          priority    = 199,
        },
        -- ── Source ────────────────────────────────────────────────────────────
        source      = nil,   -- auto-detect: git / none
        -- ── Delay ─────────────────────────────────────────────────────────────
        delay       = { text_change = 200 },
        -- ── Mappings ──────────────────────────────────────────────────────────
        mappings    = {
          apply      = "gh",
          reset      = "gH",
          textobject = "gh",
          goto_first = "[H",
          goto_prev  = "[h",
          goto_next  = "]h",
          goto_last  = "]H",
        },
        -- ── Options ────────────────────────────────────────────────────────────
        options     = { algorithm = "histogram", indent_heuristic = true, linematch = 60 },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📁 MINI.FILES — Oil-style File Manager
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_files()
    return {
      "echasnovski/mini.files",
      version = false,
      keys    = {
        {
          "<leader>fm",
          function()
            local mf = require("mini.files")
            if not mf.close() then
              mf.open(vim.api.nvim_buf_get_name(0), true)
              mf.reveal_cwd()
            end
          end,
          desc = "  Mini Files (file dir)",
        },
        {
          "<leader>fM",
          function()
            local mf = require("mini.files")
            if not mf.close() then
              mf.open(vim.uv.cwd(), true)
            end
          end,
          desc = "  Mini Files (cwd)",
        },
      },
      opts = {
        -- ── Content ─────────────────────────────────────────────────────────
        content = {
          -- Hide dotfiles by default (toggle with <leader>.)
          filter  = function(fs_entry)
            return not vim.startswith(fs_entry.name, ".")
          end,
          prefix  = nil,
          sort    = nil,
        },
        -- ── Mappings ──────────────────────────────────────────────────────────
        mappings = {
          close         = "q",
          go_in         = "l",
          go_in_plus    = "<CR>",
          go_out        = "h",
          go_out_plus   = "<BS>",
          reset         = "<leader>r",
          reveal_cwd    = "@",
          show_help     = "?",
          synchronize   = "=",
          trim_left     = "<",
          trim_right    = ">",
        },
        -- ── Options ────────────────────────────────────────────────────────────
        options = {
          permanent_delete = false,
          use_as_default_explorer = false,
        },
        -- ── Windows ────────────────────────────────────────────────────────────
        windows = {
          max_number  = math.huge,
          preview     = true,
          width_focus  = 30,
          width_nofocus= 15,
          width_preview= 50,
        },
      },
      config = function(_, opts)
        require("mini.files").setup(opts)
  
        -- Custom mappings inside mini.files buffers
        local aug = vim.api.nvim_create_augroup("AshMiniFiles", { clear = true })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "MiniFilesBufferCreate",
          callback = function(args)
            local buf = args.data.buf_id
            -- Toggle hidden files
            vim.keymap.set("n", "<leader>.", function()
              local mf      = require("mini.files")
              local cur_ent = mf.get_fs_entry()
              local show_hidden = false
  
              mf.refresh({
                content = {
                  filter = function(entry)
                    if show_hidden then return true end
                    return not vim.startswith(entry.name, ".")
                  end,
                },
              })
              show_hidden = not show_hidden
            end, { buffer = buf, desc = "  Toggle hidden files" })
  
            -- Open in split
            vim.keymap.set("n", "<C-x>", function()
              local mf    = require("mini.files")
              local entry = mf.get_fs_entry()
              if entry and entry.fs_type == "file" then
                mf.close()
                vim.cmd("split " .. vim.fn.fnameescape(entry.path))
              end
            end, { buffer = buf, desc = "  Open in horizontal split" })
  
            -- Open in vsplit
            vim.keymap.set("n", "<C-v>", function()
              local mf    = require("mini.files")
              local entry = mf.get_fs_entry()
              if entry and entry.fs_type == "file" then
                mf.close()
                vim.cmd("vsplit " .. vim.fn.fnameescape(entry.path))
              end
            end, { buffer = buf, desc = "  Open in vertical split" })
  
            -- Open in new tab
            vim.keymap.set("n", "<C-t>", function()
              local mf    = require("mini.files")
              local entry = mf.get_fs_entry()
              if entry and entry.fs_type == "file" then
                mf.close()
                vim.cmd("tabnew " .. vim.fn.fnameescape(entry.path))
              end
            end, { buffer = buf, desc = "  Open in new tab" })
  
            -- Copy path to clipboard
            vim.keymap.set("n", "y", function()
              local mf    = require("mini.files")
              local entry = mf.get_fs_entry()
              if entry then
                vim.fn.setreg("+", entry.path)
                vim.notify("📋 Copied: " .. entry.path, vim.log.levels.INFO,
                  { title = "Mini Files" })
              end
            end, { buffer = buf, desc = "📋 Copy path" })
          end,
        })
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🎯 MINI.ICONS — Comprehensive Icon Provider
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_icons()
    return {
      "echasnovski/mini.icons",
      version = false,
      lazy    = true,
      opts    = {
        -- Override default icons for ASH-specific filetypes
        extension = {
          ["hypr"]   = { glyph = "󰣇", hl = "MiniIconsBlue"   },
          ["rasi"]   = { glyph = "",  hl = "MiniIconsPurple" },
          ["fish"]   = { glyph = "",  hl = "MiniIconsGreen"  },
          ["kdl"]    = { glyph = "󱁾", hl = "MiniIconsOrange" },
          ["nix"]    = { glyph = "",  hl = "MiniIconsBlue"   },
          ["conf"]   = { glyph = "",  hl = "MiniIconsGrey"   },
          ["env"]    = { glyph = "",  hl = "MiniIconsYellow" },
          ["lock"]   = { glyph = "󰌾", hl = "MiniIconsRed"    },
          ["theme"]  = { glyph = "󰉦", hl = "MiniIconsYellow" },
          ["yuck"]   = { glyph = "󰗀", hl = "MiniIconsPurple" },
          ["ron"]    = { glyph = "",  hl = "MiniIconsOrange" },
          ["wgsl"]   = { glyph = "󰍷", hl = "MiniIconsGreen"  },
          ["glsl"]   = { glyph = "󰍷", hl = "MiniIconsCyan"   },
          ["frag"]   = { glyph = "󰍷", hl = "MiniIconsCyan"   },
          ["vert"]   = { glyph = "󰍷", hl = "MiniIconsGreen"  },
        },
        file = {
          [".gitignore"]      = { glyph = "󰊢",  hl = "MiniIconsOrange" },
          [".editorconfig"]   = { glyph = "",   hl = "MiniIconsGrey"   },
          ["Makefile"]        = { glyph = "",   hl = "MiniIconsGrey"   },
          ["Justfile"]        = { glyph = "",   hl = "MiniIconsGrey"   },
          ["Taskfile.yml"]    = { glyph = "",   hl = "MiniIconsYellow" },
          ["flake.nix"]       = { glyph = "",   hl = "MiniIconsBlue"   },
          ["docker-compose.yml"] = { glyph = "󰡨",hl = "MiniIconsBlue"  },
          ["Dockerfile"]      = { glyph = "󰡨",  hl = "MiniIconsBlue"   },
          [".env"]            = { glyph = "",   hl = "MiniIconsYellow" },
          ["lazy-lock.json"]  = { glyph = "󰒲",  hl = "MiniIconsGreen"  },
          ["stylua.toml"]     = { glyph = "",   hl = "MiniIconsCyan"   },
          [".luarc.json"]     = { glyph = "",   hl = "MiniIconsBlue"   },
          ["hyprland.conf"]   = { glyph = "󰣇",  hl = "MiniIconsBlue"   },
        },
        filetype = {
          hypr      = { glyph = "󰣇",  hl = "MiniIconsBlue"   },
          fish      = { glyph = "",  hl = "MiniIconsGreen"  },
          nix       = { glyph = "",  hl = "MiniIconsBlue"   },
          ron       = { glyph = "",  hl = "MiniIconsOrange" },
          wgsl      = { glyph = "󰍷", hl = "MiniIconsGreen"  },
          glsl      = { glyph = "󰍷", hl = "MiniIconsCyan"   },
          rasi      = { glyph = "",  hl = "MiniIconsPurple" },
          kdl       = { glyph = "󱁾", hl = "MiniIconsOrange" },
        },
      },
      init = function()
        -- Make mini.icons available as a drop-in for nvim-web-devicons
        package.preload["nvim-web-devicons"] = function()
          require("mini.icons").mock_nvim_web_devicons()
          return package.loaded["nvim-web-devicons"]
        end
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📏 MINI.INDENTSCOPE — Animated Indent Guides
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_indentscope()
    return {
      "echasnovski/mini.indentscope",
      version = false,
      event   = { "BufReadPre", "BufNewFile" },
      init    = function()
        -- Disable for certain filetypes before the plugin loads
        vim.api.nvim_create_autocmd("FileType", {
          pattern = {
            "alpha", "dashboard", "starter", "help",
            "neo-tree", "Trouble", "trouble", "lazy", "mason",
            "notify", "toggleterm", "lazyterm", "fzf",
            "TelescopePrompt", "snacks_dashboard",
          },
          callback = function()
            vim.b.miniindentscope_disable = true
          end,
        })
      end,
      opts = {
        -- ── Symbol ──────────────────────────────────────────────────────────
        symbol      = "│",
  
        -- ── Options ──────────────────────────────────────────────────────────
        options     = {
          -- When determining scope, try to use indent of the border lines
          border        = "both",
          -- Motion type for [i / ]i / ai / ii textobjects
          indent_at_cursor = true,
          -- Try to respect indent of treesitter nodes
          try_as_border = true,
        },
  
        -- ── Animation ────────────────────────────────────────────────────────
        draw = {
          -- Animate the drawing of the scope line
          animation   = require("mini.indentscope").gen_animation.linear({
            easing    = "out",
            duration  = 20,
            unit      = "step",
          }),
          -- Delay before animation starts (ms)
          delay       = 100,
        },
  
        -- ── Mappings ──────────────────────────────────────────────────────────
        mappings = {
          object_scope        = "ii",
          object_scope_with_border = "ai",
          goto_top            = "[i",
          goto_bottom         = "]i",
        },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ↕️  MINI.MOVE — Move Lines/Selections
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_move()
    return {
      "echasnovski/mini.move",
      version = false,
      event   = { "BufReadPre" },
      opts    = {
        mappings = {
          -- Move visual selection
          left  = "<M-h>",
          right = "<M-l>",
          down  = "<M-j>",
          up    = "<M-k>",
          -- Move current line in normal mode
          line_left  = "<M-h>",
          line_right = "<M-l>",
          line_down  = "<M-j>",
          line_up    = "<M-k>",
        },
        options = {
          reindent_linewise = true,
        },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔄 MINI.OPERATORS — Powerful Operator Extensions
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_operators()
    return {
      "echasnovski/mini.operators",
      version = false,
      event   = { "BufReadPre" },
      opts    = {
        -- Evaluate: gx{motion}  — evaluate as Lua/shell and replace
        evaluate  = { prefix = "g=" },
        -- Exchange:  gX{motion} — exchange two regions of text
        exchange   = { prefix = "gX", reindent_linewise = true },
        -- Multiply: gm{motion}  — duplicate text
        multiply   = { prefix = "gm" },
        -- Replace:   gr{motion}  — replace with register contents
        replace    = { prefix = "gr", reindent_linewise = true },
        -- Sort:      gs{motion}  — sort text (lines or delimited)
        sort       = { prefix = "gs" },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔔 MINI.NOTIFY — Beautiful Notifications
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_notify()
    return {
      "echasnovski/mini.notify",
      version  = false,
      priority = 1000,
      event    = "VeryLazy",
      opts     = {
        -- ── Content ─────────────────────────────────────────────────────────
        content = {
          format   = function(notif)
            local level_icons = {
              ERROR = " ",
              WARN  = " ",
              INFO  = " ",
              DEBUG = "󰃤 ",
              TRACE = "󰛉 ",
              OFF   = "  ",
            }
            local icon = level_icons[notif.level] or " "
            return string.format(
              "%s %s",
              icon,
              notif.msg
            )
          end,
          sort     = function(notif_arr)
            -- Sort by time descending (newest first)
            table.sort(notif_arr, function(a, b)
              return a.ts_update > b.ts_update
            end)
            return notif_arr
          end,
        },
  
        -- ── Window ────────────────────────────────────────────────────────────
        window = {
          config   = function()
            local col = vim.o.columns
            local row = vim.o.lines - vim.o.cmdheight - 1
            return {
              anchor   = "SE",
              col      = col,
              row      = row,
              border   = "rounded",
              zindex   = 999,
              width    = math.min(60, col - 4),
              max_width_share = 0.35,
            }
          end,
          max_width_share = 0.382,
          winblend = 25,
        },
  
        -- ── Durations (ms) ─────────────────────────────────────────────────────
        lsp_progress = {
          enable       = true,
          duration_last = 1000,
        },
      },
      config = function(_, opts)
        require("mini.notify").setup(opts)
        -- Override vim.notify globally
        vim.notify = require("mini.notify").make_notify()
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 💾 MINI.SESSIONS — Session Management
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_sessions()
    return {
      "echasnovski/mini.sessions",
      version = false,
      lazy    = false,
      keys    = {
        { "<leader>qs", function()
            local ms = require("mini.sessions")
            local name = vim.fn.input("Session name: ")
            if name ~= "" then ms.write(name) end
          end, desc = "💾 Save Session" },
        { "<leader>qS", function()
            local ms   = require("mini.sessions")
            local list = ms.list()
            if not list or #list == 0 then
              vim.notify("No sessions found", vim.log.levels.WARN, { title = "Sessions" })
              return
            end
            vim.ui.select(
              vim.tbl_map(function(s) return s.name end, list),
              { prompt = "Load session: " },
              function(name) if name then ms.read(name) end end
            )
          end, desc = "💾 Load Session"  },
        { "<leader>qd", function()
            local ms   = require("mini.sessions")
            local list = ms.list()
            if not list or #list == 0 then
              vim.notify("No sessions found", vim.log.levels.WARN, { title = "Sessions" })
              return
            end
            vim.ui.select(
              vim.tbl_map(function(s) return s.name end, list),
              { prompt = "Delete session: " },
              function(name) if name then ms.delete(name) end end
            )
          end, desc = "💾 Delete Session" },
        { "<leader>ql", function()
            local ms   = require("mini.sessions")
            local list = ms.list()
            if not list or #list == 0 then
              vim.notify("No sessions", vim.log.levels.INFO, { title = "Sessions" })
              return
            end
            local lines = vim.tbl_map(function(s)
              return string.format("%-30s  %s", s.name,
                os.date("%Y-%m-%d %H:%M", s.modify_time))
            end, list)
            vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO,
              { title = "💾 Sessions" })
          end, desc = "💾 List Sessions" },
      },
      opts = {
        autoread    = false,
        autowrite   = true,
        directory   = vim.fn.stdpath("data") .. "/sessions",
        file        = "",
        force       = { read = false, write = true, delete = false },
        hooks       = {
          pre  = { read = nil, write = nil, delete = nil },
          post = { read = nil, write = nil, delete = nil },
        },
        verbose     = { read = true, write = true, delete = true },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✂️  MINI.SPLITJOIN — Smart Split/Join Blocks
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_splitjoin()
    return {
      "echasnovski/mini.splitjoin",
      version = false,
      keys    = {
        { "gS", desc = "✂️  Split/Join toggle" },
      },
      opts    = {
        -- Single key toggles split ↔ join
        mappings  = { toggle = "gS", split = "", join = "" },
        detect    = { brackets = nil, separator = ",", exclude_regions = nil },
        split     = { hooks_pre = {}, hooks_post = {} },
        join      = {
          hooks_pre  = {},
          hooks_post = {
            require("mini.splitjoin").gen_hook.pad_brackets({ brackets = { "()", "{}", "[]" } }),
          },
        },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🧹 MINI.TRAILSPACE — Remove Trailing Whitespace
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_trailspace()
    return {
      "echasnovski/mini.trailspace",
      version = false,
      event   = { "BufWritePre" },
      keys    = {
        { "<leader>uw", function() require("mini.trailspace").trim()      end,
          desc = "🧹 Trim Trailing Whitespace" },
        { "<leader>uW", function() require("mini.trailspace").trim_last_lines() end,
          desc = "🧹 Trim Trailing Empty Lines" },
      },
      opts    = {},
      config  = function(_, opts)
        require("mini.trailspace").setup(opts)
        -- Auto-trim on save for code files
        local aug = vim.api.nvim_create_augroup("AshMiniTrailspace", { clear = true })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group    = aug,
          callback = function()
            local excluded_ft = { "markdown", "text", "org", "neorg", "diff", "gitcommit" }
            if not vim.tbl_contains(excluded_ft, vim.bo.filetype) then
              pcall(require("mini.trailspace").trim)
            end
          end,
        })
      end,
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📍 MINI.VISITS — Smart File Visit Tracking
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function spec_mini_visits()
    return {
      "echasnovski/mini.visits",
      version = false,
      event   = "VeryLazy",
      keys    = {
        { "<leader>fv",
          function()
            local mv    = require("mini.visits")
            local paths = mv.list_paths(nil, { recency_weight = 0.7 })
            if #paths == 0 then
              vim.notify("No visits yet", vim.log.levels.INFO, { title = "Mini Visits" })
              return
            end
            vim.ui.select(
              vim.tbl_map(function(p) return vim.fn.fnamemodify(p, ":~:.") end, paths),
              { prompt = "📍 Recent visits: " },
              function(_, idx) if idx then vim.cmd("edit " .. paths[idx]) end end
            )
          end,
          desc = "📍 Visit History",
        },
      },
      opts = {
        list   = { filter = nil, sort = nil },
        silent = false,
        store  = {
          autowrite  = true,
          normalize  = nil,
          path       = vim.fn.stdpath("data") .. "/mini-visits-index",
        },
        track  = { event = "BufEnter", delay = 1000 },
      },
    }
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 AGGREGATE RETURN — All mini.nvim specs
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    -- Core library (required by all mini modules)
    {
      "echasnovski/mini.nvim",
      version = false,
      lazy    = true,
    },
  
    -- ── Individual module specs ────────────────────────────────────────────────
    spec_mini_ai(),
    spec_mini_animate(),
    spec_mini_bufremove(),
    spec_mini_clue(),
    spec_mini_diff(),
    spec_mini_files(),
    spec_mini_icons(),
    spec_mini_indentscope(),
    spec_mini_move(),
    spec_mini_operators(),
    spec_mini_notify(),
    spec_mini_sessions(),
    spec_mini_splitjoin(),
    spec_mini_trailspace(),
    spec_mini_visits(),
  
    -- ── Global highlight + ASH hot-reload watcher ──────────────────────────────
    {
      "echasnovski/mini.nvim",
      name     = "mini-highlights",
      version  = false,
      lazy     = false,
      priority = 900,
      config   = function()
        setup_highlights()
        local aug = vim.api.nvim_create_augroup("AshMiniHighlights", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("🎯 Mini.nvim highlights synced", vim.log.levels.INFO,
              { title = "ASH Mini", timeout = 1200 })
          end,
        })
      end,
    },
  }