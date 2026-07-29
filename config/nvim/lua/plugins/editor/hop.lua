-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦘 HOP.NVIM — ULTRA PRECISION MOTION v5.0 OMEGA                          ║
-- ║   Word/pattern/line/anywhere jumping · multi-window · hint themes               ║
-- ║   Complement to flash.nvim for line-targeted & multi-char patterns              ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📖 OPERATION REFERENCE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
--  <leader>hw   HopWord               jump to start of any word
--  <leader>hW   HopWordBC             jump to word (backward)
--  <leader>hb   HopWordCurrentLine    jump to word on current line
--  <leader>hl   HopLine               jump to line start
--  <leader>hL   HopLineStart          jump to non-blank line start
--  <leader>hv   HopVertical           jump to same column different row
--  <leader>ha   HopAnywhere           jump to any position (any char)
--  <leader>hp   HopPattern            jump to typed pattern
--  <leader>hc   HopChar1              jump to single char
--  <leader>hC   HopChar2              jump to 2-char bigram
--  <leader>h1   HopChar1CurrentLine   1-char on current line
--  <leader>h2   HopChar2CurrentLine   2-char on current line
--  <leader>hn   HopNodes              jump to TS node boundaries
--  <leader>hg   HopPastePasteWord     paste word at hop target
--  <leader>hy   HopYankWord           yank word at hop target

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT PALETTE — distinct from flash to avoid confusion
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Primary hint label
    hl(0, "HopNextKey",   { bold = true, fg = "#ff9e64", bg = "NONE" })
    -- Secondary hint (second char of 2-char sequence)
    hl(0, "HopNextKey1",  { bold = true, fg = "#7dcfff", bg = "NONE" })
    -- Tertiary hint
    hl(0, "HopNextKey2",  { bold = true, fg = "#9ece6a", bg = "NONE" })
    -- Dimmed backdrop
    hl(0, "HopUnmatched", { fg = "#3b4261", bg = "NONE"               })
    -- Cursor hint
    hl(0, "HopCursor",    { bold = true, link = "Cursor"              })
    -- Preview highlight
    hl(0, "HopPreview",   { bold = true, link = "IncSearch"           })
  
    -- ASH palette sync
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.orange  then hl(0, "HopNextKey",   { bold = true, fg = p.orange  }) end
      if p.blue    then hl(0, "HopNextKey1",  { bold = true, fg = p.blue    }) end
      if p.green   then hl(0, "HopNextKey2",  { bold = true, fg = p.green   }) end
      if p.overlay0 then hl(0, "HopUnmatched", { fg = p.overlay0            }) end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 ADVANCED COMMANDS — custom hop actions
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  -- Jump to a word and yank it into the unnamed register
  local function hop_yank_word()
    local hop = require("hop")
    hop.hint_words({
      hint_position = require("hop.hint").HintPosition.BEGIN,
      current_line_only = false,
      callback = function(pos)
        local buf  = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_buf_get_lines(buf, pos.line, pos.line + 1, false)[1] or ""
        -- Extract the word at pos.character
        local before = line:sub(1, pos.character)
        local after  = line:sub(pos.character + 1)
        local word   = (before:match("[%w_]+$") or "") .. (after:match("^[%w_]+") or "")
        if word ~= "" then
          vim.fn.setreg('"', word)
          vim.fn.setreg("+", word)
          vim.notify(
            '🦘 Yanked: "' .. word .. '"',
            vim.log.levels.INFO,
            { title = "Hop Yank", timeout = 1500 }
          )
        end
      end,
    })
  end
  
  -- Jump to a word and paste it at cursor
  local function hop_paste_word()
    local hop      = require("hop")
    local saved    = vim.fn.getreg('"')
    local saved_t  = vim.fn.getregtype('"')
  
    hop.hint_words({
      callback = function(pos)
        local buf  = vim.api.nvim_get_current_buf()
        local line = vim.api.nvim_buf_get_lines(buf, pos.line, pos.line + 1, false)[1] or ""
        local after = line:sub(pos.character + 1)
        local word  = (line:sub(1, pos.character):match("[%w_]+$") or "")
                       .. (after:match("^[%w_]+") or "")
        if word ~= "" then
          vim.fn.setreg('"', word, "c")
          vim.cmd("normal! p")
        end
        -- Restore previous register
        vim.defer_fn(function()
          vim.fn.setreg('"', saved, saved_t)
        end, 50)
      end,
    })
  end
  
  -- Hop to any Treesitter node boundary
  local function hop_ts_nodes()
    local hop   = require("hop")
    local buf   = vim.api.nvim_get_current_buf()
    local nodes = {}
  
    local function collect_nodes(node)
      if not node then return end
      local sr, sc = node:start()
      local er, ec = node:end_()
      table.insert(nodes, { line = sr, character = sc })
      table.insert(nodes, { line = er, character = ec })
      for child in node:iter_children() do
        collect_nodes(child)
      end
    end
  
    local ok_ts, ts = pcall(vim.treesitter.get_parser, buf)
    if not ok_ts then
      vim.notify("⚠ No Treesitter parser for this buffer", vim.log.levels.WARN, { title = "Hop" })
      return
    end
  
    local tree = ts:parse()[1]
    if tree then collect_nodes(tree:root()) end
  
    -- Deduplicate
    local seen, unique = {}, {}
    for _, n in ipairs(nodes) do
      local key = n.line .. ":" .. n.character
      if not seen[key] then
        seen[key] = true
        table.insert(unique, n)
      end
    end
  
    hop.hint_with_pos(unique, {})
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "smoka7/hop.nvim",
      version = "*",
      event   = "VeryLazy",
  
      opts = {
        -- ── Key sequence ────────────────────────────────────────────────────────
        -- Home-row biased, distinct from flash labels
        keys              = "etovxqpdygfblzhckisuran",
  
        -- ── Quit key ─────────────────────────────────────────────────────────────
        quit_key          = "<Esc>",
  
        -- ── Match case sensitivity ───────────────────────────────────────────────
        case_insensitive  = true,
  
        -- ── Jump beyond viewport ─────────────────────────────────────────────────
        -- "off"     → only current window
        -- "multi"   → all visible windows
        multi_windows     = true,
  
        -- ── Uppercase bias: prefer shorter sequences ──────────────────────────────
        uppercase_labels  = false,
  
        -- ── Virtual lines (fold, extmarks) ───────────────────────────────────────
        ignore_injections = false,
  
        -- ── Character hint direction ──────────────────────────────────────────────
        -- "after_texel" | "before_cursor" | "auto"
        hint_position     = require("hop.hint").HintPosition.BEGIN,
  
        -- ── Visual extensions ─────────────────────────────────────────────────────
        -- Show dim overlay on backdrop (like flash backdrop)
        extensions        = {},
  
        -- ── Virtual text bias ─────────────────────────────────────────────────────
        current_line_only = false,
      },
  
      keys = {
        -- ── 🦘 Word jumps ─────────────────────────────────────────────────────
        { "<leader>hw",  "<cmd>HopWord<cr>",             desc = "🦘 Hop Word"                  },
        { "<leader>hW",  "<cmd>HopWordBC<cr>",           desc = "🦘 Hop Word (backward)"       },
        { "<leader>hb",  "<cmd>HopWordCurrentLine<cr>",  desc = "🦘 Hop Word (line)"           },
        { "<leader>hB",  "<cmd>HopWordCurrentLineBC<cr>",desc = "🦘 Hop Word (line, backward)" },
        { "<leader>hM",  "<cmd>HopWordMW<cr>",           desc = "🦘 Hop Word (multi-window)"   },
  
        -- ── 📏 Line jumps ─────────────────────────────────────────────────────
        { "<leader>hl",  "<cmd>HopLine<cr>",             desc = "🦘 Hop Line"                  },
        { "<leader>hL",  "<cmd>HopLineStart<cr>",        desc = "🦘 Hop Line Start"            },
        { "<leader>hv",  "<cmd>HopVertical<cr>",         desc = "🦘 Hop Vertical"              },
  
        -- ── 🔤 Char jumps ─────────────────────────────────────────────────────
        { "<leader>hc",  "<cmd>HopChar1<cr>",            desc = "🦘 Hop Char1"                 },
        { "<leader>hC",  "<cmd>HopChar2<cr>",            desc = "🦘 Hop Char2 (bigram)"        },
        { "<leader>h1",  "<cmd>HopChar1CurrentLine<cr>", desc = "🦘 Hop Char1 (line)"          },
        { "<leader>h2",  "<cmd>HopChar2CurrentLine<cr>", desc = "🦘 Hop Char2 (line)"          },
  
        -- ── 🔍 Pattern jump ──────────────────────────────────────────────────
        { "<leader>hp",  "<cmd>HopPattern<cr>",          desc = "🦘 Hop Pattern"               },
  
        -- ── 🌍 Anywhere ───────────────────────────────────────────────────────
        { "<leader>ha",  "<cmd>HopAnywhere<cr>",         desc = "🦘 Hop Anywhere"              },
        { "<leader>hA",  "<cmd>HopAnywhereMW<cr>",       desc = "🦘 Hop Anywhere (multi-win)"  },
  
        -- ── 🌳 Treesitter nodes ────────────────────────────────────────────────
        { "<leader>hn",  hop_ts_nodes,                   desc = "🦘 Hop TS Nodes"              },
  
        -- ── 📋 Actions ────────────────────────────────────────────────────────
        { "<leader>hy",  hop_yank_word,                  desc = "🦘 Hop Yank Word"             },
        { "<leader>hg",  hop_paste_word,                 desc = "🦘 Hop Paste Word"            },
  
        -- ── Operator-pending mode ─────────────────────────────────────────────
        { "<leader>hw",  "<cmd>HopWord<cr>",  mode = "o", desc = "🦘 Hop Word (operator)" },
        { "<leader>ha",  "<cmd>HopAnywhere<cr>", mode = "o", desc = "🦘 Hop Anywhere (operator)" },
        { "<leader>hl",  "<cmd>HopLine<cr>",  mode = "o", desc = "🦘 Hop Line (operator)"  },
  
        -- ── Visual mode ───────────────────────────────────────────────────────
        { "<leader>hw",  "<cmd>HopWord<cr>",  mode = "v", desc = "🦘 Hop Word (visual)"  },
        { "<leader>ha",  "<cmd>HopAnywhere<cr>", mode = "v", desc = "🦘 Hop Anywhere (visual)" },
      },
  
      config = function(_, opts)
        require("hop").setup(opts)
  
        setup_highlights()
  
        local aug = vim.api.nvim_create_augroup("AshHop", { clear = true })
  
        vim.api.nvim_create_autocmd("ColorScheme", {
          group    = aug,
          callback = setup_highlights,
        })
  
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify(
              "🦘 Hop highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH Hop", timeout = 1200 }
            )
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify("🦘 Hop.nvim loaded", vim.log.levels.DEBUG, { title = "ASH Hop" })
        end
      end,
    },
  }