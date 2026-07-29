-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       ✂️  LUASNIP — ULTRA SNIPPET ENGINE v5.0 OMEGA                             ║
-- ║   VSCode · SnipMate · Lua-native snippets · dynamic nodes · transformations    ║
-- ║   tree-sitter aware · per-filetype · restore on re-enter · ASH custom snips   ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP — snippet placeholder colours
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
    local hl = vim.api.nvim_set_hl
  
    -- Active snippet placeholder (current tabstop)
    hl(0, "LuasnipChoiceNodePassive", { italic = true, fg = "#7aa2f7" })
    hl(0, "LuasnipChoiceNodeActive",  {
      bold      = true,
      underline = true,
      sp        = "#ff9e64",
      fg        = "#ff9e64",
    })
  
    -- Insert node (editable placeholder)
    hl(0, "LuasnipInsertNodePassive", { fg = "#9399b2"                })
    hl(0, "LuasnipInsertNodeActive",  {
      bold   = true,
      fg     = "#9ece6a",
      bg     = "#1a2b1a",
    })
  
    -- ASH palette sync
    local ok, ash = pcall(require, "ash.theme")
    if ok and ash.palette then
      local p = ash.palette
      if p.orange then
        hl(0, "LuasnipChoiceNodeActive", {
          bold      = true,
          underline = true,
          sp        = p.orange,
          fg        = p.orange,
        })
      end
      if p.green then
        hl(0, "LuasnipInsertNodeActive", {
          bold = true,
          fg   = p.green,
          bg   = p.surface0 or "#1a2b1a",
        })
      end
      if p.blue then
        hl(0, "LuasnipChoiceNodePassive", { italic = true, fg = p.blue })
      end
      local dim = p.overlay0 or p.subtext0 or "#9399b2"
      hl(0, "LuasnipInsertNodePassive", { fg = dim })
    end
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- ✂️  ASH CUSTOM SNIPPETS — ultra developer productivity set
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  local function register_ash_snippets(ls)
    local s   = ls.snippet
    local t   = ls.text_node
    local i   = ls.insert_node
    local f   = ls.function_node
    local c   = ls.choice_node
    local d   = ls.dynamic_node
    local sn  = ls.snippet_node
    local fmt = require("luasnip.extras.fmt").fmt
    local rep = require("luasnip.extras").rep
    local m   = require("luasnip.extras").match
    local n   = require("luasnip.extras").nonempty
    local dl  = require("luasnip.extras").dynamic_lambda
    local r   = require("luasnip.extras").rep
  
    -- ── Global / all-ft snippets ─────────────────────────────────────────────
  
    -- ASH todo comment with username
    local ash_todo = s("atodo", fmt(
      "-- ASH: {}({}) {}: {}",
      {
        c(1, {
          t("TODO"),
          t("FIXME"),
          t("HACK"),
          t("NOTE"),
          t("PERF"),
          t("WARN"),
          t("DOCS"),
        }),
        f(function() return os.getenv("USER") or "ash" end),
        i(2, "category"),
        i(3, "description"),
      }
    ))
  
    -- ISO-8601 timestamp
    local timestamp = s("ts", {
      f(function() return os.date("%Y-%m-%dT%H:%M:%S") end),
    })
  
    -- UUID v4 (random)
    local uuid = s("uuid", {
      f(function()
        local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        return template:gsub("[xy]", function(c2)
          local v = c2 == "x" and math.random(0, 0xf) or math.random(8, 0xb)
          return string.format("%x", v)
        end)
      end),
    })
  
    -- Lorem ipsum
    local lorem = s("lorem", {
      t("Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
        .. "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
        .. "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."),
    })
  
    ls.add_snippets("all", { ash_todo, timestamp, uuid, lorem })
  
    -- ── Lua snippets ─────────────────────────────────────────────────────────
  
    ls.add_snippets("lua", {
      -- Quick function
      s("fn", fmt("local function {}({})\n  {}\nend", {
        i(1, "name"), i(2, "args"), i(3, "-- body"),
      })),
  
      -- Module pattern
      s("mod", fmt(
        "local {} = {{}}\n\n{}\n\nreturn {}",
        { i(1, "M"), i(2, "-- methods"), rep(1) }
      )),
  
      -- Require with local name
      s("req", fmt('local {} = require("{}")', {
        i(1, "module"), i(2, "module.path"),
      })),
  
      -- Protected require
      s("preq", fmt(
        'local ok_{}, {} = pcall(require, "{}")\nif not ok_{} then return end',
        { i(1, "name"), rep(1), i(2, "module.path"), rep(1) }
      )),
  
      -- vim.keymap.set
      s("kmap", fmt(
        'vim.keymap.set({}, "{}", {}, {{ desc = "{}" }})',
        {
          c(1, { t('"n"'), t('"i"'), t('"v"'), t('{ "n", "v" }') }),
          i(2, "<leader>x"),
          i(3, "function() end"),
          i(4, "description"),
        }
      )),
  
      -- nvim_create_autocmd
      s("au", fmt(
        'vim.api.nvim_create_autocmd("{}", {{\n  group = {},\n  callback = function(ev)\n    {}\n  end,\n}})',
        { i(1, "BufReadPre"), i(2, "aug"), i(3, "-- body") }
      )),
  
      -- vim.notify
      s("notif", fmt(
        'vim.notify("{}", vim.log.levels.{}, {{ title = "{}" }})',
        {
          i(1, "message"),
          c(2, { t("INFO"), t("WARN"), t("ERROR"), t("DEBUG") }),
          i(3, "Title"),
        }
      )),
    })
  
    -- ── Python snippets ───────────────────────────────────────────────────────
  
    ls.add_snippets("python", {
      -- Dataclass
      s("dc", fmt(
        "@dataclass\nclass {}:\n    {}: {} = {}",
        { i(1, "ClassName"), i(2, "field"), i(3, "str"), i(4, '""') }
      )),
  
      -- Type annotation
      s("ann", fmt("{}: {} = {}", { i(1, "name"), i(2, "type"), i(3, "value") })),
  
      -- pytest fixture
      s("fix", fmt(
        "@pytest.fixture\ndef {}({}):\n    {}",
        { i(1, "fixture_name"), i(2), i(3, "yield") }
      )),
  
      -- Context manager
      s("ctx", fmt(
        "with {} as {}:\n    {}",
        { i(1, "context"), i(2, "result"), i(3, "pass") }
      )),
  
      -- f-string
      s("fs", fmt('f"{{{}}}"', { i(1, "expression") })),
  
      -- Async def
      s("adef", fmt(
        "async def {}({}) -> {}:\n    {}",
        { i(1, "name"), i(2, "args"), i(3, "None"), i(4, "pass") }
      )),
    })
  
    -- ── Rust snippets ─────────────────────────────────────────────────────────
  
    ls.add_snippets("rust", {
      -- Impl block
      s("impl", fmt(
        "impl{} {}{} {{\n    {}\n}}",
        {
          c(1, { t(""), sn(nil, { t("<"), i(1, "T"), t(">") }) }),
          i(2, "Type"),
          c(3, { t(""), sn(nil, { t(" for "), i(1, "Trait") }) }),
          i(4, "// methods"),
        }
      )),
  
      -- Derive macro
      s("der", fmt("#[derive({})]\n", { i(1, "Debug, Clone") })),
  
      -- Result type
      s("res", fmt("Result<{}, {}>", { i(1, "T"), i(2, "Error") })),
  
      -- Match arm
      s("ma", fmt("{} => {{\n    {}\n}}", { i(1, "pattern"), i(2, "// body") })),
  
      -- Tokio async main
      s("amain", fmt(
        "#[tokio::main]\nasync fn main() -> Result<(), Box<dyn std::error::Error>> {{\n    {}\n    Ok(())\n}}",
        { i(1, "// body") }
      )),
  
      -- Struct with fields
      s("st", fmt(
        "#[derive(Debug)]\npub struct {} {{\n    pub {}: {},\n}}",
        { i(1, "Name"), i(2, "field"), i(3, "Type") }
      )),
    })
  
    -- ── Go snippets ───────────────────────────────────────────────────────────
  
    ls.add_snippets("go", {
      -- Error check
      s("ec", fmt(
        'if err != nil {{\n    return {}\n}}',
        { c(1, { t("err"), t("nil, err"), t('fmt.Errorf("…: %w", err)') }) }
      )),
  
      -- goroutine + channel
      s("gor", fmt(
        "go func() {{\n    {}\n}}()",
        { i(1, "// body") }
      )),
  
      -- context with cancel
      s("ctx", fmt(
        "ctx, cancel := context.WithTimeout(context.Background(), {} * time.Second)\ndefer cancel()\n{}",
        { i(1, "30"), i(2) }
      )),
  
      -- Interface
      s("iface", fmt(
        "type {} interface {{\n    {}({}) {}\n}}",
        { i(1, "Name"), i(2, "Method"), i(3, "args"), i(4, "error") }
      )),
  
      -- Table-driven test
      s("tdt", fmt(
        'func Test{}(t *testing.T) {{\n    tests := []struct{{{}}}{{\n        {{\n            name: "{}",\n        }},\n    }}\n    for _, tt := range tests {{\n        t.Run(tt.name, func(t *testing.T) {{\n            {}\n        }})\n    }}\n}}',
        { i(1, "FuncName"), i(2), i(3, "case name"), i(4, "// assert") }
      )),
    })
  
    -- ── TypeScript / JavaScript snippets ──────────────────────────────────────
  
    ls.add_snippets({ "typescript", "typescriptreact" }, {
      -- React FC
      s("rfc", fmt(
        "const {}: React.FC<{}> = ({{}}) => {{\n  return (\n    <div>\n      {}\n    </div>\n  )\n}}\n\nexport default {}",
        { i(1, "Component"), i(2, "Props"), i(3), rep(1) }
      )),
  
      -- useState hook
      s("us", fmt(
        "const [{}, set{}] = useState<{}>({});",
        { i(1, "value"), i(2, "Value"), i(3, "string"), i(4, '""') }
      )),
  
      -- useEffect hook
      s("ue", fmt(
        "useEffect(() => {{\n  {}\n  return () => {{\n    {}\n  }}\n}}, [{}])",
        { i(1, "// effect"), i(2, "// cleanup"), i(3) }
      )),
  
      -- Interface
      s("int", fmt(
        "interface {} {{\n  {}: {}\n}}",
        { i(1, "Name"), i(2, "prop"), i(3, "string") }
      )),
  
      -- Arrow function
      s("af", fmt(
        "const {} = ({}: {}): {} => {{\n  {}\n}}",
        { i(1, "fn"), i(2, "arg"), i(3, "type"), i(4, "ReturnType"), i(5) }
      )),
  
      -- Zod schema
      s("zod", fmt(
        'const {}Schema = z.object({{\n  {}: z.{}({}),\n}})\ntype {} = z.infer<typeof {}Schema>',
        { i(1, "Name"), i(2, "field"), i(3, "string"), i(4), rep(1), rep(1) }
      )),
    })
  
    -- ── Markdown snippets ─────────────────────────────────────────────────────
  
    ls.add_snippets("markdown", {
      -- Code block with language
      s("cb", fmt(
        "```{}\n{}\n```",
        { i(1, "lua"), i(2, "-- code") }
      )),
  
      -- Callout / admonition
      s("ca", fmt(
        "> [!{}]\n> {}",
        {
          c(1, { t("NOTE"), t("TIP"), t("IMPORTANT"), t("WARNING"), t("CAUTION") }),
          i(2, "text"),
        }
      )),
  
      -- Link
      s("lk", fmt("[{}]({})", { i(1, "text"), i(2, "url") })),
  
      -- Table (3 columns)
      s("tbl", fmt(
        "| {} | {} | {} |\n| --- | --- | --- |\n| {} | {} | {} |",
        { i(1, "H1"), i(2, "H2"), i(3, "H3"), i(4), i(5), i(6) }
      )),
  
      -- Frontmatter
      s("fm", fmt(
        "---\ntitle: {}\ndate: {}\ntags: [{}]\n---",
        {
          i(1, "Title"),
          f(function() return os.date("%Y-%m-%d") end),
          i(2, "tag"),
        }
      )),
    })
  end
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- 📦 PLUGIN SPEC
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  return {
    {
      "L3MON4D3/LuaSnip",
      build        = "make install_jsregexp",
      event        = "InsertEnter",
      dependencies = {
        "rafamadriz/friendly-snippets",
        "honza/vim-snippets",
      },
  
      keys = {
        -- Expand / jump forward
        {
          "<C-l>",
          function()
            local ls = require("luasnip")
            if ls.expand_or_jumpable() then ls.expand_or_jump() end
          end,
          mode   = { "i", "s" },
          desc   = "✂️  Snippet expand / next",
          silent = true,
        },
        -- Jump backward
        {
          "<C-h>",
          function()
            local ls = require("luasnip")
            if ls.jumpable(-1) then ls.jump(-1) end
          end,
          mode   = { "i", "s" },
          desc   = "✂️  Snippet prev",
          silent = true,
        },
        -- Cycle choice node
        {
          "<C-j>",
          function()
            local ls = require("luasnip")
            if ls.choice_active() then ls.change_choice(1) end
          end,
          mode   = { "i", "s" },
          desc   = "✂️  Snippet choice next",
          silent = true,
        },
        {
          "<C-k>",
          function()
            local ls = require("luasnip")
            if ls.choice_active() then ls.change_choice(-1) end
          end,
          mode   = { "i", "s" },
          desc   = "✂️  Snippet choice prev",
          silent = true,
        },
        -- Reload snippets in dev
        {
          "<leader>sr",
          function()
            require("luasnip.loaders.from_lua").load({
              paths = vim.fn.stdpath("config") .. "/lua/plugins/completion/snippets/",
            })
            vim.notify("✂️  Snippets reloaded", vim.log.levels.INFO, { title = "LuaSnip" })
          end,
          desc   = "✂️  Reload snippets",
          silent = true,
        },
      },
  
      opts = {
        -- ── History: re-enter snippets ────────────────────────────────────────
        history             = true,
  
        -- ── Update on every text change ───────────────────────────────────────
        updateevents        = "TextChanged,TextChangedI",
  
        -- ── Keep highlights after leaving snippet ────────────────────────────
        enable_autosnippets = true,
  
        -- ── Delete snippets from jumplist when text changes ───────────────────
        delete_check_events = "TextChanged",
  
        -- ── Region check events ───────────────────────────────────────────────
        region_check_events = "CursorMoved,CursorHold,InsertEnter",
  
        -- ── Store selection for $TM_SELECTED_TEXT ─────────────────────────────
        store_selection_keys = "<Tab>",
  
        -- ── Ext options: highlight active node ────────────────────────────────
        ext_opts = {
          [require("luasnip.util.types").choiceNode] = {
            active   = { virt_text = { { "⊙", "LuasnipChoiceNodeActive" } } },
            passive  = { virt_text = { { "○", "LuasnipChoiceNodePassive" } } },
          },
          [require("luasnip.util.types").insertNode] = {
            active   = { virt_text = { { "▸", "LuasnipInsertNodeActive" } } },
            passive  = { virt_text = { { "·", "LuasnipInsertNodePassive" } } },
          },
        },
  
        -- ── ft_func: detect filetype from treesitter ──────────────────────────
        ft_func = function()
          return vim.split(vim.bo.filetype, ".", { plain = true })
        end,
  
        -- ── Load from: VSCode, SnipMate, Lua paths ────────────────────────────
        load_ft_func = require("luasnip.extras.filetype_functions").extend_load_ft({
          markdown = { "lua", "python", "bash" },
          html     = { "javascript", "css" },
          vue      = { "javascript", "typescript", "html", "css" },
          svelte   = { "javascript", "typescript", "html", "css" },
        }),
      },
  
      config = function(_, opts)
        local ls = require("luasnip")
        ls.setup(opts)
  
        setup_highlights()
  
        -- ── Load VSCode snippets (friendly-snippets) ──────────────────────────
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_vscode").lazy_load({
          paths = { vim.fn.stdpath("config") .. "/snippets" },
        })
  
        -- ── Load SnipMate snippets (vim-snippets) ─────────────────────────────
        require("luasnip.loaders.from_snipmate").lazy_load()
  
        -- ── Load Lua snippets (from nvim config) ──────────────────────────────
        require("luasnip.loaders.from_lua").lazy_load({
          paths = { vim.fn.stdpath("config") .. "/lua/plugins/completion/snippets/" },
        })
  
        -- ── Register ASH custom snippets ──────────────────────────────────────
        register_ash_snippets(ls)
  
        -- ── Autocmds ──────────────────────────────────────────────────────────
        local aug = vim.api.nvim_create_augroup("AshLuaSnip", { clear = true })
  
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
              "✂️  LuaSnip highlights synced with ASH theme",
              vim.log.levels.INFO,
              { title = "ASH LuaSnip", timeout = 1200 }
            )
          end,
        })
  
        -- Auto-unlink snippets when leaving insert/select mode
        vim.api.nvim_create_autocmd("ModeChanged", {
          group    = aug,
          pattern  = { "s:n", "i:*" },
          callback = function()
            if ls.session
              and ls.session.current_nodes[vim.api.nvim_get_current_buf()]
              and not ls.session.jump_active
            then
              ls.unlink_current()
            end
          end,
        })
  
        if vim.g.ash_debug then
          vim.notify(
            "✂️  LuaSnip loaded — history: true, autosnippets: true",
            vim.log.levels.DEBUG,
            { title = "ASH LuaSnip" }
          )
        end
      end,
    },
  }