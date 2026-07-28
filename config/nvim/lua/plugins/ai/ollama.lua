-- ╔══════════════════════════════════════════════════════════════════════════════════╗
-- ║       🦙 OLLAMA — ULTRA LOCAL AI ENGINE v5.0 OMEGA                             ║
-- ║   Local LLM inference · code generation · chat · explain · refactor           ║
-- ║   model management · streaming · context-aware · ASH theme-synced             ║
-- ╚══════════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🎨 HIGHLIGHT SETUP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  hl(0, "OllamaNormal",      { link = "NormalFloat"   })
  hl(0, "OllamaBorder",      { link = "FloatBorder"   })
  hl(0, "OllamaTitle",       { bold = true, fg = "#f97316" })
  hl(0, "OllamaModel",       { bold = true, italic = true, fg = "#f97316" })
  hl(0, "OllamaPrompt",      { bold = true, fg = "#7aa2f7" })
  hl(0, "OllamaResponse",    { fg = "#cdd6f4"                })
  hl(0, "OllamaCode",        { bg = "#1e2030", fg = "#cdd6f4" })
  hl(0, "OllamaThinking",    { bold = true, italic = true, fg = "#f9e2af" })
  hl(0, "OllamaError",       { bold = true, fg = "#f38ba8"    })
  hl(0, "OllamaSuccess",     { bold = true, fg = "#9ece6a"    })
  hl(0, "OllamaStreaming",   { italic = true, fg = "#9399b2"  })

  local ok, ash = pcall(require, "ash.theme")
  if ok and ash.palette then
    local p = ash.palette
    local orange = p.peach or "#f97316"
    hl(0, "OllamaTitle",    { bold = true, fg = orange })
    hl(0, "OllamaModel",    { bold = true, italic = true, fg = orange })
    if p.blue   then hl(0, "OllamaPrompt",   { bold = true, fg = p.blue   }) end
    if p.text   then hl(0, "OllamaResponse", { fg = p.text               }) end
    if p.green  then hl(0, "OllamaSuccess",  { bold = true, fg = p.green  }) end
    if p.red    then hl(0, "OllamaError",    { bold = true, fg = p.red    }) end
    if p.yellow then hl(0, "OllamaThinking", { bold = true, italic = true, fg = p.yellow }) end
    if p.surface1 then hl(0, "OllamaCode",   { bg = p.surface1, fg = p.text or "#cdd6f4" }) end
    local dim = p.overlay0 or "#9399b2"
    hl(0, "OllamaStreaming", { italic = true, fg = dim })
  end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔧 OLLAMA UTILITIES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local OLLAMA_HOST = os.getenv("OLLAMA_HOST") or "http://localhost:11434"

-- Check if Ollama server is running
local function is_ollama_running()
  local result = vim.fn.system("curl -s --max-time 2 " .. OLLAMA_HOST .. "/api/tags 2>/dev/null")
  return vim.v.shell_error == 0 and result ~= ""
end

-- Get list of available local models
local function get_local_models()
  local result = vim.fn.system(
    "curl -s " .. OLLAMA_HOST .. "/api/tags 2>/dev/null"
  )
  if vim.v.shell_error ~= 0 then return {} end

  local ok, data = pcall(vim.fn.json_decode, result)
  if not ok or not data or not data.models then return {} end

  return vim.tbl_map(function(m)
    return m.name
  end, data.models)
end

-- Pull a model
local function pull_model()
  vim.ui.input({ prompt = "🦙 Model to pull (e.g. llama3.2): " }, function(model)
    if not model or model == "" then return end

    vim.notify("🦙 Pulling " .. model .. "…", vim.log.levels.INFO,
      { title = "Ollama" })

    vim.fn.jobstart(
      { "ollama", "pull", model },
      {
        on_exit = function(_, code)
          vim.schedule(function()
            if code == 0 then
              vim.notify("🦙 ✅ Pulled: " .. model, vim.log.levels.INFO,
                { title = "Ollama" })
            else
              vim.notify("🦙 ❌ Failed to pull: " .. model, vim.log.levels.ERROR,
                { title = "Ollama" })
            end
          end)
        end,
      }
    )
  end)
end

-- Show Ollama status
local function show_status()
  local running = is_ollama_running()
  local models  = running and get_local_models() or {}
  local ver     = vim.fn.trim(vim.fn.system("ollama --version 2>/dev/null"))

  local lines = {
    "🦙 Ollama Status",
    "──────────────────────────────────",
    string.format("  Server:  %s", running and "✅ Running" or "❌ Offline"),
    string.format("  Host:    %s", OLLAMA_HOST),
    string.format("  Version: %s", ver ~= "" and ver or "unknown"),
    string.format("  Models:  %d installed", #models),
  }

  for _, m in ipairs(models) do
    table.insert(lines, "    • " .. m)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Ollama" })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 📦 PLUGIN SPEC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

return {
  {
    "nomnivore/ollama.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd          = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
    event        = "VeryLazy",

    keys = {
      -- ── Prompt actions ────────────────────────────────────────────────────
      { "<leader>oo",  "<cmd>Ollama<cr>",                         desc = "🦙 Ollama: Open menu",        mode = { "n", "v" } },
      { "<leader>om",  "<cmd>OllamaModel<cr>",                    desc = "🦙 Ollama: Switch model"       },
      { "<leader>os",  show_status,                               desc = "🦙 Ollama: Status"             },
      { "<leader>op",  pull_model,                                desc = "🦙 Ollama: Pull model"         },

      -- ── Code actions ──────────────────────────────────────────────────────
      {
        "<leader>oe",
        ":<C-u>Ollama Explain_Code<cr>",
        mode  = { "n", "v" },
        desc  = "🦙 Ollama: Explain code",
      },
      {
        "<leader>or",
        ":<C-u>Ollama Review_Code<cr>",
        mode  = { "n", "v" },
        desc  = "🦙 Ollama: Review code",
      },
      {
        "<leader>og",
        ":<C-u>Ollama Generate_Code<cr>",
        desc  = "🦙 Ollama: Generate code",
      },
      {
        "<leader>of",
        ":<C-u>Ollama Fix_Code<cr>",
        mode  = { "n", "v" },
        desc  = "🦙 Ollama: Fix code",
      },
      {
        "<leader>ot",
        ":<C-u>Ollama Add_Tests<cr>",
        mode  = { "n", "v" },
        desc  = "🦙 Ollama: Add tests",
      },
      {
        "<leader>od",
        ":<C-u>Ollama Document_Code<cr>",
        mode  = { "n", "v" },
        desc  = "🦙 Ollama: Document code",
      },
      {
        "<leader>oc",
        ":<C-u>Ollama Chat<cr>",
        desc  = "🦙 Ollama: Chat",
      },
      {
        "<leader>oq",
        function()
          vim.ui.input({ prompt = "🦙 Ask Ollama: " }, function(q)
            if q and q ~= "" then
              vim.cmd("Ollama Ask " .. vim.fn.shellescape(q))
            end
          end)
        end,
        desc = "🦙 Ollama: Ask question",
      },
    },

    opts = {
      -- ── Server ───────────────────────────────────────────────────────────
      url    = OLLAMA_HOST,

      -- ── Default model ─────────────────────────────────────────────────────
      model  = (function()
        -- Auto-detect best available model
        local preferred = {
          "codestral:latest",
          "deepseek-coder-v2:latest",
          "llama3.1:latest",
          "llama3.2:latest",
          "codellama:latest",
          "mistral:latest",
          "qwen2.5-coder:latest",
          "phi3.5:latest",
        }
        local models = get_local_models()
        for _, pref in ipairs(preferred) do
          if vim.tbl_contains(models, pref) then
            return pref
          end
        end
        return models[1] or "llama3.2"
      end)(),

      -- ── Prompts ───────────────────────────────────────────────────────────
      prompts = {
        -- ── Code analysis ────────────────────────────────────────────────
        Explain_Code = {
          prompt = [[You are an expert programmer. Analyze and explain the following code in detail.
Focus on:
1. What the code does (high-level)
2. How it works (step by step)
3. Key patterns and idioms used
4. Potential issues or edge cases
5. Suggestions for improvement

Code:
```$ftype
$sel
```

Provide a clear, structured explanation.]],
          action = "display",
        },

        Review_Code = {
          prompt = [[You are a senior code reviewer. Review the following $ftype code for:

1. 🐛 Bugs and logical errors
2. 🔒 Security vulnerabilities
3. ⚡ Performance issues
4. 📖 Readability and maintainability
5. 🧪 Test coverage suggestions
6. 🏗️ Architecture concerns

Code:
```$ftype
$sel
```

Format your review with clear sections and specific line references where possible.]],
          action = "display",
        },

        Fix_Code = {
          prompt = [[You are an expert $ftype developer. Fix the following code.
Identify all bugs, errors, and issues. Provide the corrected code with explanations.

```$ftype
$sel
```

Return ONLY the fixed code followed by a brief explanation of changes.]],
          action = "replace",
          extract = "```$ftype\n(.-)```",
        },

        Generate_Code = {
          prompt  = "You are an expert $ftype developer. Generate clean, efficient, well-documented $ftype code for the following requirement:\n\n$input\n\nReturn ONLY the code with inline comments.",
          action  = "display",
          input   = "What should the code do?",
        },

        Add_Tests = {
          prompt = [[You are a testing expert. Write comprehensive tests for this $ftype code.
Include:
- Unit tests for each function/method
- Edge cases and boundary conditions
- Error handling tests
- Mock any external dependencies

```$ftype
$sel
```

Use the standard testing framework for $ftype.]],
          action  = "display",
        },

        Document_Code = {
          prompt = [[You are a technical writer. Add comprehensive documentation to this $ftype code.
Include:
- Function/method docstrings with parameter descriptions
- Return value documentation
- Example usage where appropriate
- Any important notes or caveats

```$ftype
$sel
```

Return the fully documented code.]],
          action  = "replace",
          extract = "```$ftype\n(.-)```",
        },

        Refactor_Code = {
          prompt = [[Refactor the following $ftype code to improve:
- Readability and clarity
- Performance and efficiency
- Maintainability
- Following best practices

```$ftype
$sel
```

Explain the changes you made.]],
          action  = "replace",
          extract = "```$ftype\n(.-)```",
        },

        Translate_Code = {
          prompt  = "Translate this $ftype code to $input. Keep the same logic and structure.\n\n```$ftype\n$sel\n```",
          action  = "display",
          input   = "Target language?",
        },

        -- ── Writing aids ──────────────────────────────────────────────────
        Improve_Text = {
          prompt  = "Improve the clarity, flow, and style of the following text. Keep the same meaning:\n\n$sel",
          action  = "replace",
          ftype   = { "markdown", "text", "rst", "org", "norg" },
        },

        Summarize = {
          prompt  = "Provide a concise summary of the following:\n\n$sel",
          action  = "display",
        },

        -- ── ASH-specific ─────────────────────────────────────────────────
        ASH_Theme_Config = {
          prompt  = "Generate an ASH dotfiles v5.0 theme configuration based on: $input\nOutput valid Lua for the ASH theme system.",
          action  = "display",
          input   = "Theme description or inspiration:",
        },

        Chat = {
          prompt  = "$input",
          action  = "display",
          input   = "Your message:",
        },

        Ask = {
          prompt  = "$input",
          action  = "display",
        },
      },
    },

    config = function(_, opts)
      require("ollama").setup(opts)

      setup_highlights()

      local aug = vim.api.nvim_create_augroup("AshOllama", { clear = true })

      -- Warn if Ollama is not running
      vim.defer_fn(function()
        if not is_ollama_running() then
          vim.notify(
            "🦙 Ollama server not detected at " .. OLLAMA_HOST .. "\nStart with: ollama serve",
            vim.log.levels.DEBUG,
            { title = "Ollama" }
          )
        end
      end, 3000)

      vim.api.nvim_create_autocmd("ColorScheme", { group = aug, callback = setup_highlights })
      vim.api.nvim_create_autocmd("User", {
        group   = aug,
        pattern = "AshThemeChanged",
        callback = function()
          setup_highlights()
          vim.notify("🦙 Ollama highlights synced", vim.log.levels.INFO,
            { title = "ASH Ollama", timeout = 1200 })
        end,
      })
    end,
  },
}