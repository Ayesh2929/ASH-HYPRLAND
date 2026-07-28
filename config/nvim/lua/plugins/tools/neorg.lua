-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       📓 NEORG — ULTRA ORG-MODE FOR NEOVIM v5.0 OMEGA                         ║
-- ║   Workspaces · journal · todos · calendar · concealer · export                ║
-- ║   treesitter · LSP-like features · ASH theme-synced                           ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — rich org-mode colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- ── Headings ──────────────────────────────────────────────────────────────
    hl(0, "@neorg.headings.1.prefix",    { bold = true, fg = "#7aa2f7" })
    hl(0, "@neorg.headings.2.prefix",    { bold = true, fg = "#9ece6a" })
    hl(0, "@neorg.headings.3.prefix",    { bold = true, fg = "#f9e2af" })
    hl(0, "@neorg.headings.4.prefix",    { bold = true, fg = "#f38ba8" })
    hl(0, "@neorg.headings.5.prefix",    { bold = true, fg = "#cba6f7" })
    hl(0, "@neorg.headings.6.prefix",    { bold = true, fg = "#94e2d5" })
  
    hl(0, "@neorg.headings.1.title",     { bold = true, fg = "#7aa2f7" })
    hl(0, "@neorg.headings.2.title",     { bold = true, fg = "#9ece6a" })
    hl(0, "@neorg.headings.3.title",     { bold = true, fg = "#f9e2af" })
    hl(0, "@neorg.headings.4.title",     { bold = true, fg = "#f38ba8" })
    hl(0, "@neorg.headings.5.title",     { bold = true, fg = "#cba6f7" })
    hl(0, "@neorg.headings.6.title",     { bold = true, fg = "#94e2d5" })
  
    -- ── Todo items ────────────────────────────────────────────────────────────
    hl(0, "@neorg.todo_items.done.1",    { bold = true, fg = "#9ece6a" })
    hl(0, "@neorg.todo_items.undone.1",  { fg = "#9399b2"              })
    hl(0, "@neorg.todo_items.pending.1", { bold = true, fg = "#f9e2af" })
    hl(0, "@neorg.todo_items.uncertain.1",{ fg = "#cba6f7"             })
    hl(0, "@neorg.todo_items.urgent.1",  { bold = true, fg = "#f38ba8" })
    hl(0, "@neorg.todo_items.recurring.1",{ fg = "#89b4fa"             })
    hl(0, "@neorg.todo_items.on_hold.1", { fg = "#fab387"              })
    hl(0, "@neorg.todo_items.cancelled.1",{ fg = "#9399b2", strikethrough = true })
  
    -- ── Code & markup ─────────────────────────────────────────────────────────
    hl(0, "@neorg.markup.bold",          { bold = true                })
    hl(0, "@neorg.markup.italic",        { italic = true              })
    hl(0, "@neorg.markup.underline",     { underline = true           })
    hl(0, "@neorg.markup.strikethrough", { strikethrough = true       })
    hl(0, "@neorg.markup.verbatim",      { fg = "#7dcfff", bg = "#1e2030" })
    hl(0, "@neorg.markup.math",          { italic = true, fg = "#9ece6a" })
    hl(0, "@neorg.markup.superscript",   { fg = "#fab387"             })
    hl(0, "@neorg.markup.subscript",     { fg = "#fab387"             })
    hl(0, "@neorg.markup.spoiler",       { fg = "#1e2030", bg = "#9399b2" })
    hl(0, "@neorg.markup.link_target",   { underline = true, fg = "#89b4fa" })
    hl(0, "@neorg.markup.link_location", { italic = true, fg = "#89b4fa" })
    hl(0, "@neorg.markup.anchor_declaration",{ bold = true, fg = "#cba6f7" })
  
    -- ── Lists ─────────────────────────────────────────────────────────────────
    hl(0, "@neorg.lists.unordered.1.prefix", { bold = true, fg = "#7aa2f7" })
    hl(0, "@neorg.lists.unordered.2.prefix", { bold = true, fg = "#9ece6a" })
    hl(0, "@neorg.lists.unordered.3.prefix", { bold = true, fg = "#f9e2af" })
    hl(0, "@neorg.lists.ordered.1.prefix",   { bold = true, fg = "#89b4fa" })
    hl(0, "@neorg.lists.ordered.2.prefix",   { bold = true, fg = "#94e2d5" })
  
    -- ── Tags ──────────────────────────────────────────────────────────────────
    hl(0, "@neorg.tags.ranged_verbatim.begin", { bold = true, fg = "#cba6f7" })
    hl(0, "@neorg.tags.ranged_verbatim.end",   { bold = true, fg = "#cba6f7" })
    hl(0, "@neorg.tags.ranged_verbatim.name",  { bold = true, fg = "#89b4fa" })
  
    -- ── Definitions ───────────────────────────────────────────────────────────
    hl(0, "@neorg.definitions.single.prefix",  { bold = true, fg = "#94e2d5" })
    hl(0, "@neorg.definitions.multi.prefix",   { bold = true, fg = "#94e2d5" })
  
    -- ── Footnotes ─────────────────────────────────────────────────────────────
    hl(0, "@neorg.footnotes.single.prefix",    { italic = true, fg = "#9399b2" })
    hl(0, "@neorg.footnotes.multi.prefix",     { italic = true, fg = "#9399b2" })
  
    -- ── Quotes ────────────────────────────────────────────────────────────────
    hl(0, "@neorg.quotes.1.prefix",  { fg = "#9399b2"              })
    hl(0, "@neorg.quotes.1.content", { italic = true, fg = "#9399b2" })
  
    -- ── Concealer ─────────────────────────────────────────────────────────────
    hl(0, "@neorg.conceals.link",    { underline = true, fg = "#89b4fa" })
  
    -- ── ASH palette sync ──────────────────────────────────────────────────────
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.blue   then
        hl(0, "@neorg.headings.1.prefix", { bold = true, fg = p.blue })
        hl(0, "@neorg.headings.1.title",  { bold = true, fg = p.blue })
      end
      if p.green  then
        hl(0, "@neorg.headings.2.prefix",  { bold = true, fg = p.green })
        hl(0, "@neorg.headings.2.title",   { bold = true, fg = p.green })
        hl(0, "@neorg.todo_items.done.1",  { bold = true, fg = p.green })
      end
      if p.yellow then
        hl(0, "@neorg.headings.3.prefix",    { bold = true, fg = p.yellow })
        hl(0, "@neorg.headings.3.title",     { bold = true, fg = p.yellow })
        hl(0, "@neorg.todo_items.pending.1", { bold = true, fg = p.yellow })
      end
      if p.red    then
        hl(0, "@neorg.headings.4.prefix",  { bold = true, fg = p.red })
        hl(0, "@neorg.headings.4.title",   { bold = true, fg = p.red })
        hl(0, "@neorg.todo_items.urgent.1",{ bold = true, fg = p.red })
      end
      if p.mauve  then
        hl(0, "@neorg.headings.5.prefix", { bold = true, fg = p.mauve })
        hl(0, "@neorg.headings.5.title",  { bold = true, fg = p.mauve })
      end
      if p.teal   then
        hl(0, "@neorg.headings.6.prefix", { bold = true, fg = p.teal })
        hl(0, "@neorg.headings.6.title",  { bold = true, fg = p.teal })
      end
      if p.surface1 then
        hl(0, "@neorg.markup.verbatim", {
          fg = p.cyan or "#7dcfff",
          bg = p.surface1,
        })
      end
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 🔧 WORKSPACE CONFIGURATION
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local HOME     = os.getenv("HOME") or vim.fn.expand("~")
  local NOTES_DIR = HOME .. "/Notes"
  
  local WORKSPACES = {
    { name = "notes",   path = NOTES_DIR .. "/notes"   },
    { name = "journal", path = NOTES_DIR .. "/journal"  },
    { name = "work",    path = NOTES_DIR .. "/work"     },
    { name = "projects",path = NOTES_DIR .. "/projects" },
    { name = "inbox",   path = NOTES_DIR .. "/inbox"    },
    { name = "archive", path = NOTES_DIR .. "/archive"  },
  }
  
  -- Ensure workspace directories exist
  local function ensure_workspaces()
    for _, ws in ipairs(WORKSPACES) do
      if vim.fn.isdirectory(ws.path) == 0 then
        vim.fn.mkdir(ws.path, "p")
      end
    end
  end
  
  -- Smart workspace picker
  local function pick_workspace()
    local ws_names = vim.tbl_map(function(w) return w.name end, WORKSPACES)
  
    vim.ui.select(ws_names, { prompt = "📓 Neorg workspace: " }, function(name)
      if name then
        vim.cmd("Neorg workspace " .. name)
      end
    end)
  end
  
  -- Quick journal entry
  local function new_journal_entry()
    local date = os.date("%Y-%m-%d")
    local time = os.date("%H:%M")
    vim.cmd("Neorg journal today")
    vim.notify(
      string.format("📓 Journal entry: %s %s", date, time),
      vim.log.levels.INFO,
      { title = "Neorg", timeout = 1200 }
    )
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "nvim-neorg/neorg",
      version      = "*",
      ft           = "norg",
      cmd          = "Neorg",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-neorg/lua-utils.nvim",
        "pysan3/pathlib.nvim",
        "nvim-neotest/nvim-nio",
        -- ── Optional modules ────────────────────────────────────────────────────
        { "vhyrro/luarocks.nvim",  priority = 1000, config = true },
        { "benlubas/neorg-conceal-wrap",           optional = true },
      },
  
      keys = {
        -- ── Workspace ───────────────────────────────────────────────────────────
        { "<leader>nw",  pick_workspace,                              desc = "📓 Neorg: Workspace picker"          },
        { "<leader>ni",  "<cmd>Neorg index<cr>",                      desc = "📓 Neorg: Index"                     },
        { "<leader>nrn", "<cmd>Neorg return<cr>",                     desc = "📓 Neorg: Return to last file"        },
  
        -- ── Journal ─────────────────────────────────────────────────────────────
        { "<leader>njt", new_journal_entry,                           desc = "📓 Neorg: Journal today"             },
        { "<leader>njy", "<cmd>Neorg journal yesterday<cr>",          desc = "📓 Neorg: Journal yesterday"         },
        { "<leader>njtm","<cmd>Neorg journal tomorrow<cr>",           desc = "📓 Neorg: Journal tomorrow"          },
        { "<leader>njc", "<cmd>Neorg journal toc open<cr>",           desc = "📓 Neorg: Journal TOC"               },
  
        -- ── Notes ───────────────────────────────────────────────────────────────
        { "<leader>nnn", "<cmd>Neorg keybind all core.dirman.new-note<cr>", desc = "📓 Neorg: New note"            },
        { "<leader>nnf", function()
            local ok, tele = pcall(require, "telescope.builtin")
            if ok then
              tele.find_files({
                prompt_title = "📓 Neorg notes",
                cwd          = NOTES_DIR,
                search_dirs  = { NOTES_DIR },
              })
            else
              vim.cmd("Neorg keybind all core.telescope.find_norg_files")
            end
          end,                                                         desc = "📓 Neorg: Find notes"               },
        { "<leader>nng", function()
            local ok, tele = pcall(require, "telescope.builtin")
            if ok then
              tele.live_grep({
                prompt_title = "📓 Grep notes",
                cwd          = NOTES_DIR,
              })
            end
          end,                                                         desc = "📓 Neorg: Grep notes"               },
  
        -- ── TODO ────────────────────────────────────────────────────────────────
        { "<leader>ntl", "<cmd>Neorg keybind all core.qol.todo-items.list<cr>", desc = "📓 Neorg: TODO list"       },
  
        -- ── Export ──────────────────────────────────────────────────────────────
        { "<leader>nep", "<cmd>Neorg export to-file pandoc<cr>",      desc = "📓 Neorg: Export (pandoc)"           },
  
        -- ── Table of contents ────────────────────────────────────────────────────
        { "<leader>ntc", "<cmd>Neorg generate-workspace-summary<cr>", desc = "📓 Neorg: Workspace summary"         },
  
        -- ── Mode ─────────────────────────────────────────────────────────────────
        { "<leader>nm",  "<cmd>Neorg mode norg<cr>",                  desc = "📓 Neorg: Switch to norg mode"        },
  
        -- ── Info ──────────────────────────────────────────────────────────────────
        {
          "<leader>nni",
          function()
            vim.notify(
              table.concat({
                "📓 Neorg Environment",
                "──────────────────────────────────",
                string.format("  Notes dir:  %s", NOTES_DIR),
                string.format("  Workspaces: %d configured", #WORKSPACES),
                string.format("  Neovim:     %s", vim.version().major .. "." .. vim.version().minor),
                string.format("  pandoc:     %s", vim.fn.executable("pandoc") == 1 and "✅" or "⭕"),
                string.format("  xdg-open:   %s", vim.fn.executable("xdg-open") == 1 and "✅" or "⭕"),
              }, "\n"),
              vim.log.levels.INFO,
              { title = "Neorg Info" }
            )
          end,
          desc = "📓 Neorg: Environment info",
        },
      },
  
      opts = {
        load = {
          -- ── Core modules ──────────────────────────────────────────────────────
          ["core.defaults"]          = {},    -- Load all default modules
  
          -- ── Concealer (render markup) ─────────────────────────────────────────
          ["core.concealer"] = {
            config = {
              folds = true,
              icon_preset = "diamond",
              icons = {
                todo = {
                  done        = { icon = "󰄬", highlight = "@neorg.todo_items.done.1"    },
                  pending     = { icon = "󰔟", highlight = "@neorg.todo_items.pending.1" },
                  undone      = { icon = "○",  highlight = "@neorg.todo_items.undone.1"  },
                  urgent      = { icon = "󰀦", highlight = "@neorg.todo_items.urgent.1"  },
                  uncertain   = { icon = "?",  highlight = "@neorg.todo_items.uncertain.1" },
                  on_hold     = { icon = "󰏤", highlight = "@neorg.todo_items.on_hold.1" },
                  cancelled   = { icon = "󰜺", highlight = "@neorg.todo_items.cancelled.1" },
                  recurring   = { icon = "↺",  highlight = "@neorg.todo_items.recurring.1" },
                },
                list = {
                  icons = { "◆", "❖", "▸", "▹", "•", "‣" },
                },
                heading = {
                  icons = { "◉", "○", "✿", "✸", "❋", "❖" },
                },
                quote = {
                  icons = { "│", "│", "│", "│", "│", "│" },
                },
                code_block = {
                  spell_check  = false,
                  content_only = true,
                  padding      = { left = 4 },
                  conceal      = true,
                  nodes        = { "ranged_verbatim_tag" },
                  highlight    = "CursorLine",
                  width        = "page",
                },
              },
            },
          },
  
          -- ── Directory manager (workspaces) ────────────────────────────────────
          ["core.dirman"] = {
            config = {
              workspaces         = (function()
                local ws = {}
                for _, w in ipairs(WORKSPACES) do
                  ws[w.name] = w.path
                end
                return ws
              end)(),
              default_workspace  = "notes",
              open_last_workspace= false,
              use_popup          = true,
              index              = "index.norg",
            },
          },
  
          -- ── Completion ─────────────────────────────────────────────────────────
          ["core.completion"] = {
            config = {
              engine   = "nvim-cmp",
              name     = "Neorg",
            },
          },
  
          -- ── Integrations ──────────────────────────────────────────────────────
          ["core.integrations.nvim-cmp"]      = {},
          ["core.integrations.treesitter"]    = {},
          ["core.integrations.telescope"]     = {},
  
          -- ── Journal ───────────────────────────────────────────────────────────
          ["core.journal"] = {
            config = {
              workspace          = "journal",
              journal_folder     = ".",
              use_template       = true,
              template_name      = "journal_template.norg",
              strategy           = "flat",
            },
          },
  
          -- ── Export ────────────────────────────────────────────────────────────
          ["core.export"] = {
            config = {
              export_dir         = "~/Notes/export",
            },
          },
          ["core.export.markdown"] = {
            config = {
              extensions         = "all",
            },
          },
  
          -- ── Highlights ────────────────────────────────────────────────────────
          ["core.highlights"] = {},
  
          -- ── Looking Glass (code block execution) ──────────────────────────────
          ["core.looking-glass"] = {},
  
          -- ── Presenter (slideshow) ─────────────────────────────────────────────
          ["core.presenter"] = {
            config = {
              zen_mode = "zen-mode",
            },
          },
  
          -- ── TODO items tracker ─────────────────────────────────────────────────
          ["core.qol.todo-items"] = {},
  
          -- ── Tangle (extract code blocks) ──────────────────────────────────────
          ["core.tangle"] = {
            config = {
              tangle_on_write = false,
            },
          },
  
          -- ── Mode ──────────────────────────────────────────────────────────────
          ["core.mode"] = {},
  
          -- ── Keybinds ──────────────────────────────────────────────────────────
          ["core.keybinds"] = {
            config = {
              default_keybinds    = true,
              neorg_leader        = "<LocalLeader>",
              hook                = function(keybinds)
                -- Extra keybinds inside neorg files
                keybinds.map("norg", "n", "<C-t>", "<cmd>Neorg journal today<cr>")
                keybinds.map("norg", "n", "<M-CR>", function()
                  vim.cmd("Neorg keybind all core.itero.next-iteration")
                end)
              end,
            },
          },
  
          -- ── Esupports (better editing) ────────────────────────────────────────
          ["core.esupports.metagen"] = {
            config = {
              type       = "auto",
              update_date= true,
            },
          },
          ["core.esupports.hop"] = {},
          ["core.esupports.indent"] = {
            config = { format_on_enter = true, format_on_escape = true },
          },
  
          -- ── Auto commands ─────────────────────────────────────────────────────
          ["core.autocommands"]  = {},
  
          -- ── UI ────────────────────────────────────────────────────────────────
          ["core.ui"]            = {},
          ["core.ui.calendar"]   = {},
  
          -- ── Storage ───────────────────────────────────────────────────────────
          ["core.storage"] = {
            config = {
              path = vim.fn.stdpath("data") .. "/neorg.mpack",
            },
          },
  
          -- ── Summary ───────────────────────────────────────────────────────────
          ["core.summary"] = {
            config = {
              strategy    = "default",
              workspace   = "notes",
            },
          },
  
          -- ── Syntax ────────────────────────────────────────────────────────────
          ["core.syntax"] = {},
        },
      },
  
      config = function(_, opts)
        -- Ensure workspace dirs exist
        ensure_workspaces()
  
        require("neorg").setup(opts)
  
        setup_highlights()
  
        -- ── Neovim-cmp source registration ────────────────────────────────────
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
          cmp.setup.filetype("norg", {
            sources = cmp.config.sources({
              { name = "neorg",   priority = 1100 },
              { name = "buffer",  priority = 500  },
              { name = "path",    priority = 400  },
              { name = "spell",   priority = 300  },
              { name = "emoji",   priority = 200  },
            }),
          })
        end
  
        -- ── Treesitter parser for norg ─────────────────────────────────────────
        local ok_ts, ts = pcall(require, "nvim-treesitter.parsers")
        if ok_ts and not ts.get_parser_configs().norg then
          -- norg parser installed automatically by neorg
        end
  
        local aug = vim.api.nvim_create_augroup("AshNeorg", { clear = true })
  
        -- Filetype-specific settings
        vim.api.nvim_create_autocmd("FileType", {
          group   = aug,
          pattern = "norg",
          callback = function()
            vim.opt_local.expandtab    = true
            vim.opt_local.shiftwidth   = 2
            vim.opt_local.tabstop      = 2
            vim.opt_local.softtabstop  = 2
            vim.opt_local.textwidth    = 80
            vim.opt_local.wrap         = true
            vim.opt_local.linebreak    = true
            vim.opt_local.spell        = true
            vim.opt_local.spelllang    = "en_us"
            vim.opt_local.conceallevel = 2
            vim.opt_local.concealcursor= "nc"
            vim.opt_local.foldlevel    = 99
  
            -- Local keymaps
            local function bmap(lhs, rhs, desc2)
              vim.keymap.set("n", lhs, rhs, {
                buffer  = true,
                silent  = true,
                desc    = "📓 " .. desc2,
              })
            end
  
            bmap("<M-CR>",    "<cmd>Neorg keybind norg core.itero.next-iteration<cr>", "New item below")
            bmap("<C-Space>", "<cmd>Neorg keybind norg core.qol.todo-items.cycle<cr>", "Cycle todo")
            bmap("<M-d>",     "<cmd>Neorg keybind norg core.tempus.insert-date<cr>",   "Insert date")
            bmap("gd",        "<cmd>Neorg keybind norg core.esupports.hop.hop-link<cr>","Follow link")
            bmap("gf",        "<cmd>Neorg keybind norg core.esupports.hop.hop-link<cr>","Follow link (gf)")
          end,
        })
  
        vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
        vim.api.nvim_create_autocmd("User", {
          group   = aug,
          pattern = "AshThemeChanged",
          callback = function()
            setup_highlights()
            vim.notify("📓 Neorg highlights synced with ASH theme", vim.log.levels.INFO,
              { title = "ASH Neorg", timeout = 1200 })
          end,
        })
  
        -- ── Create journal template if missing ────────────────────────────────
        local tmpl_path = NOTES_DIR .. "/journal/journal_template.norg"
        if vim.fn.filereadable(tmpl_path) == 0 and vim.fn.isdirectory(NOTES_DIR .. "/journal") == 1 then
          local tmpl = table.concat({
            "@document.meta",
            "title: {TODAY}",
            "description: Daily journal entry",
            "authors: [ash]",
            "categories: [journal]",
            "created: {TODAY}",
            "@end",
            "",
            "* Morning",
            "",
            "** Intentions",
            "",
            "- ( ) ",
            "",
            "** Gratitude",
            "",
            "- ",
            "",
            "* Afternoon",
            "",
            "** Progress",
            "",
            "- ",
            "",
            "* Evening",
            "",
            "** Reflections",
            "",
            "> ",
            "",
            "** Tomorrow",
            "",
            "- ( ) ",
            "",
          }, "\n")
          local f = io.open(tmpl_path, "w")
          if f then f:write(tmpl); f:close() end
        end
  
        if vim.g.ash_debug then
          vim.notify(
            string.format("📓 Neorg loaded — %d workspaces at %s", #WORKSPACES, NOTES_DIR),
            vim.log.levels.DEBUG,
            { title = "ASH Neorg" }
          )
        end
      end,
    },
  }