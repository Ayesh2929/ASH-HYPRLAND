-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🧠 GEN.NVIM — ULTRA INLINE LLM GENERATOR v5.0 OMEGA                     ║
-- ║   Ollama-powered · inline generation · chat · custom prompts · streaming      ║
-- ║   multi-model · buffer-aware · ASH theme-synced popup                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  hl(0, "GenNormal",         { link = "NormalFloat"   })
  hl(0, "GenBorder",         { link = "FloatBorder"   })
  hl(0, "GenTitle",          { bold = true, fg = "#f97316" })
  hl(0, "GenOutput",         { fg = "#cdd6f4"              })
  hl(0, "GenThinking",       { bold = true, italic = true, fg = "#f9e2af" })
  hl(0, "GenModel",          { italic = true, fg = "#9399b2" })
  hl(0, "GenPromptPrefix",   { bold = true, fg = "#7aa2f7" })
  hl(0, "GenCode",           { bg = "#1e2030", fg = "#cdd6f4" })
  hl(0, "GenError",          { bold = true, fg = "#f38ba8" })
  hl(0, "GenSuccess",        { bold = true, fg = "#9ece6a" })
  hl(0, "GenVirtualText",    { italic = true, fg = "#6e738d" })
  hl(0, "GenSelection",      { bold = true, fg = "#9ece6a", bg = "#1a2b1a" })

  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p = ash.palette
    local orange = p.peach or "#f97316"
    hl(0, "GenTitle", { bold = true, fg = orange })
    if p.text    then hl(0, "GenOutput",        { fg = p.text               }) end
    if p.yellow  then hl(0, "GenThinking",      { bold = true, italic = true, fg = p.yellow }) end
    if p.blue    then hl(0, "GenPromptPrefix",  { bold = true, fg = p.blue   }) end
    if p.green   then hl(0, "GenSuccess",       { bold = true, fg = p.green  }) end
    if p.red     then hl(0, "GenError",         { bold = true, fg = p.red    }) end
    if p.green   then
      hl(0, "GenSelection", { bold = true, fg = p.green, bg = p.surface0 or "#1a2b1a" })
    end
    if p.surface1 then hl(0, "GenCode", { bg = p.surface1, fg = p.text or "#cdd6f4" }) end
    local dim = p.overlay0 or "#6e738d"
    hl(0, "GenVirtualText", { italic = true, fg = dim })
    hl(0, "GenModel",       { italic = true, fg = dim })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 MODEL MANAGEMENT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local OLLAMA_HOST = os.getenv("OLLAMA_HOST") or "http://localhost:11434"

local function get_models()
  local result = vim.fn.system(
    "curl -s " .. OLLAMA_HOST .. "/api/tags 2>/dev/null"
  )
  if vim.v.shell_error ~= 0 then return {} end

  local ok, data = pcall(vim.fn.json_decode, result)
  if not ok or not data or not data.models then return {} end

  return vim.tbl_map(function(m) return m.name end, data.models)
end

local function pick_model()
  local models = get_models()
  if #models == 0 then
    vim.notify("🧠 No Ollama models found. Is Ollama running?", vim.log.levels.WARN,
      { title = "Gen" })
    return
  end

  vim.ui.select(models, { prompt = "🧠 Select model: " }, function(model)
    if model then
      require("gen").model = model
      vim.notify("🧠 Model: " .. model, vim.log.levels.INFO,
        { title = "Gen", timeout = 1200 })
    end
  end)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "David-Kunz/gen.nvim",
    event        = "VeryLazy",
    dependencies = {},

    keys = {
      -- ── Main picker ────────────────────────────────────────────────────────
      {
        "<leader>ag",
        "<cmd>Gen<cr>",
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Open prompt picker",
        silent = true,
      },
      -- ── Model ─────────────────────────────────────────────────────────────
      {
        "<leader>agm",
        pick_model,
        desc   = "🧠 Gen: Pick model",
        silent = true,
      },

      -- ── Quick prompts ─────────────────────────────────────────────────────
      {
        "<leader>age",
        function() require("gen").select_prompt("Enhance_Code") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Enhance code",
        silent = true,
      },
      {
        "<leader>agx",
        function() require("gen").select_prompt("Explain_Code") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Explain code",
        silent = true,
      },
      {
        "<leader>agr",
        function() require("gen").select_prompt("Review_Code") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Review code",
        silent = true,
      },
      {
        "<leader>agf",
        function() require("gen").select_prompt("Fix_Code") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Fix code",
        silent = true,
      },
      {
        "<leader>agt",
        function() require("gen").select_prompt("Add_Tests") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Add tests",
        silent = true,
      },
      {
        "<leader>agc",
        function() require("gen").select_prompt("Generate_Code") end,
        desc   = "🧠 Gen: Generate code",
        silent = true,
      },
      {
        "<leader>agd",
        function() require("gen").select_prompt("Docstring") end,
        mode   = { "n", "v" },
        desc   = "🧠 Gen: Add docstring",
        silent = true,
      },
      {
        "<leader>agq",
        function()
          vim.ui.input({ prompt = "🧠 Ask: " }, function(q)
            if q and q ~= "" then
              require("gen").run_cmd(q)
            end
          end)
        end,
        desc   = "🧠 Gen: Ask question",
        silent = true,
      },
      {
        "<leader>agi",
        function()
          local model = require("gen").model
          vim.notify(
            table.concat({
              "🧠 Gen.nvim Status",
              "──────────────────────────────────",
              string.format("  Model:  %s", model),
              string.format("  Host:   %s", OLLAMA_HOST),
              string.format("  Ollama: %s", vim.fn.executable("ollama") == 1 and "✅" or "⭕"),
            }, "\n"),
            vim.log.levels.INFO,
            { title = "Gen.nvim" }
          )
        end,
        desc   = "🧠 Gen: Info",
        silent = true,
      },
    },

    opts = {
      -- ── Model ─────────────────────────────────────────────────────────────
      model = (function()
        local models = get_models()
        local preferred = {
          "codestral:latest",
          "deepseek-coder-v2:latest",
          "llama3.1:latest",
          "llama3.2:latest",
          "codellama:latest",
        }
        for _, pref in ipairs(preferred) do
          if vim.tbl_contains(models, pref) then return pref end
        end
        return models[1] or "llama3.2"
      end)(),

      -- ── Host ─────────────────────────────────────────────────────────────
      host        = OLLAMA_HOST:gsub("http://", ""):gsub(":11434", ""),
      port        = "11434",

      -- ── Display ───────────────────────────────────────────────────────────
      display_mode= "float",

      -- ── Show model ────────────────────────────────────────────────────────
      show_model  = true,

      -- ── No strip trailing whitespace in replace mode ───────────────────────
      no_auto_close = false,

      -- ── Float window ─────────────────────────────────────────────────────
      init        = function(_)
        pcall(io.popen, "ollama serve > /dev/null 2>&1 &")
      end,

      -- ── Prompts ───────────────────────────────────────────────────────────
      prompts     = {
        Generate_Code = {
          prompt  = "Generate $filetype code for: $input\n\nReturn ONLY the code with comments.",
          replace = false,
        },

        Enhance_Code = {
          prompt  = [[Enhance this $filetype code by improving:
- Code quality and readability
- Performance
- Error handling
- Following best practices

```$filetype
$text
```

Return the enhanced code only.]],
          replace = true,
          extract = "```$filetype(.-)```",
        },

        Explain_Code = {
          prompt  = [[Explain this $filetype code concisely:

```$filetype
$text
```

Focus on: what it does, how it works, and any noteworthy patterns.]],
          replace = false,
        },

        Review_Code = {
          prompt  = [[Review this $filetype code for:
🐛 Bugs | 🔒 Security | ⚡ Performance | 📖 Readability

```$filetype
$text
```

Be specific and actionable.]],
          replace = false,
        },

        Fix_Code = {
          prompt  = [[Fix all bugs and errors in this $filetype code:

```$filetype
$text
```

Return ONLY the corrected code.]],
          replace = true,
          extract = "```$filetype(.-)```",
        },

        Add_Tests = {
          prompt  = [[Write comprehensive tests for this $filetype code:

```$filetype
$text
```

Cover: happy path, edge cases, errors. Use standard test framework for $filetype.]],
          replace = false,
        },

        Docstring = {
          prompt  = [[Add documentation/docstrings to this $filetype code:

```$filetype
$text
```

Return the fully documented code.]],
          replace = true,
          extract = "```$filetype(.-)```",
        },

        Optimize_Performance = {
          prompt  = [[Optimize this $filetype code for maximum performance:

```$filetype
$text
```

Return the optimized code with comments explaining changes.]],
          replace = true,
          extract = "```$filetype(.-)```",
        },

        Improve_Writing = {
          prompt  = "Improve this text for clarity and style:\n\n$text\n\nReturn the improved version.",
          replace = true,
        },

        Summarize = {
          prompt  = "Summarize this concisely:\n\n$text",
          replace = false,
        },

        -- ── ASH-specific ──────────────────────────────────────────────────
        ASH_Explain_Config = {
          prompt  = [[You are an ASH OMEGA v5.0 Neovim configuration expert.
Explain this configuration code:

```$filetype
$text
```

Focus on: what it configures, why each setting matters, and best practices.]],
          replace = false,
        },

        ASH_Generate_Snippet = {
          prompt  = "Generate a LuaSnip snippet in JSON format for $filetype for: $input",
          replace = false,
        },

        Ask = {
          prompt  = "$input",
          replace = false,
        },
      },
    },

    config = function(_, opts)
      require("gen").setup(opts)

      setup_highlights()

      local aug = vim.api.nvim_create_augroup("AshGenNvim", { clear = true })

      -- Buffer settings for gen output window
      vim.api.nvim_create_autocmd("FileType", {
        group   = aug,
        pattern = "gen",
        callback = function(ev)
          vim.b[ev.buf].miniindentscope_disable = true
          vim.b[ev.buf].minianimate_disable     = true
          vim.opt_local.wrap     = true
          vim.opt_local.linebreak= true
          vim.opt_local.spell    = false
          vim.opt_local.number   = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn     = "no"

          -- Extra keymaps in gen window
          vim.keymap.set("n", "q",     "<cmd>quit<cr>",          { buffer = ev.buf, desc = "🧠 Gen: Close" })
          vim.keymap.set("n", "<esc>", "<cmd>quit<cr>",          { buffer = ev.buf, desc = "🧠 Gen: Close" })
          vim.keymap.set("n", "gy",    "gg\"*yG``",             { buffer = ev.buf, desc = "🧠 Gen: Yank all" })
          vim.keymap.set("n", "gr",    function()
            local gen = require("gen")
            gen.run_cmd(vim.fn.input("🧠 Follow-up: "))
          end, { buffer = ev.buf, desc = "🧠 Gen: Follow-up" })
        end,
      })

      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("🧠 Gen.nvim highlights synced", vim.log.levels.INFO,
            { title = "ASH Gen", timeout = 1200 })
        end,
      })

      if vim.g.ash_debug then
        local model = require("gen").model
        vim.notify(
          string.format("🧠 Gen.nvim loaded — model: %s", model),
          vim.log.levels.DEBUG,
          { title = "ASH Gen" }
        )
      end
    end,
  },
}
