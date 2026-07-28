-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║  lua/core/filetype.lua — Custom Filetype Detection & Settings               ║
-- ║  ASH DOTFILES v5.0 OMEGA                                                    ║
-- ║                                                                              ║
-- ║  Responsibilities:                                                           ║
-- ║    • Register custom filetypes via vim.filetype.add()                       ║
-- ║    • Per-filetype indent / wrap / spell overrides via FileType autocmd      ║
-- ║    • Icon → filetype mapping consumed by neo-tree / lualine                 ║
-- ║    • Comment-string overrides for uncommon formats                          ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- § 01  CUSTOM FILETYPE DETECTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- vim.filetype.add() is the modern API (Nvim ≥ 0.8).
-- Pattern keys use Lua patterns; filename keys are exact matches.

vim.filetype.add({
    -- ── Exact filename matches ────────────────────────────────────────────────
    filename = {
      -- Hyprland ecosystem
      ["hyprland.conf"]     = "hyprlang",
      ["hyprlock.conf"]     = "hyprlang",
      ["hypridle.conf"]     = "hyprlang",
      ["hyprpaper.conf"]    = "hyprlang",
      ["hyprpaper.conf"]    = "hyprlang",
      ["monitors.conf"]     = "hyprlang",
      ["autostart.conf"]    = "hyprlang",
      ["windowrules.conf"]  = "hyprlang",
      ["animations.conf"]   = "hyprlang",
      ["keybinds.conf"]     = "hyprlang",
      ["colors.conf"]       = "hyprlang",
      -- Waybar
      ["config.jsonc"]      = "jsonc",
      -- Kitty
      ["kitty.conf"]        = "kitty",
      -- Fish shell
      ["config.fish"]       = "fish",
      ["fish_variables"]    = "fish",
      -- Shell
      [".env"]              = "sh",
      [".envrc"]            = "sh",
      -- Rasi (rofi)
      ["config.rasi"]       = "rasi",
      -- Git
      [".gitignore_global"] = "gitignore",
      [".gitattributes"]    = "gitattributes",
      -- Nix
      ["flake.nix"]         = "nix",
      -- Docker
      ["Dockerfile"]        = "dockerfile",
      ["docker-compose.yml"] = "yaml.docker-compose",
      -- Justfile
      ["Justfile"]          = "just",
      ["justfile"]          = "just",
      -- Makefile variants
      ["GNUmakefile"]       = "make",
      -- Ansible
      ["site.yml"]          = "yaml.ansible",
      ["playbook.yml"]      = "yaml.ansible",
      -- Editor config
      [".editorconfig"]     = "editorconfig",
      -- Direnv
      [".envrc"]            = "direnv",
      -- Sway
      ["sway/config"]       = "swayconfig",
      -- i3
      ["i3/config"]         = "i3config",
    },
  
    -- ── Pattern / glob matches ────────────────────────────────────────────────
    pattern = {
      -- Hyprland config directory
      [".*/hypr/.*%.conf"]          = "hyprlang",
      [".*/hyprland/.*%.conf"]      = "hyprlang",
      -- Waybar module configs
      [".*/waybar/.*%.jsonc"]       = "jsonc",
      [".*/rofi/.*%.rasi"]          = "rasi",
      -- Fish functions & completions
      [".*/fish/.*%.fish"]          = "fish",
      [".*/functions/.*%.fish"]     = "fish",
      [".*/completions/.*%.fish"]   = "fish",
      -- Kitty sessions / themes
      [".*/kitty/.*%.conf"]         = "kitty",
      -- Systemd units
      [".*%.service"]               = "systemd",
      [".*%.timer"]                 = "systemd",
      [".*%.socket"]                = "systemd",
      [".*%.target"]                = "systemd",
      [".*%.mount"]                 = "systemd",
      [".*%.path"]                  = "systemd",
      -- Env files
      [".*%.env%..*"]               = "sh",
      [".env%.local"]               = "sh",
      [".env%.production"]          = "sh",
      [".env%.development"]         = "sh",
      -- Neovim spell files
      [".*%.add"]                   = "conf",
      -- Tmux
      [".*/tmux/.*%.tmux"]          = "tmux",
      [".*tmux%.conf"]              = "tmux",
      -- SSH
      [".*/ssh/config%.d/.*"]       = "sshconfig",
      -- Markdown with YAML front-matter
      [".*%.mdx"]                   = "markdown.mdx",
      -- Ansible
      [".*/ansible/.*%.yml"]        = "yaml.ansible",
      [".*/playbooks/.*%.yml"]      = "yaml.ansible",
      [".*/roles/.*/tasks/.*%.yml"] = "yaml.ansible",
      -- Terraform
      [".*%.tf"]                    = "terraform",
      [".*%.tfvars"]                = "terraform-vars",
      -- Helm templates
      [".*/templates/.*%.yaml"]     = "helm",
      -- Sway config
      [".*/sway/config"]            = "swayconfig",
      [".*/sway/config%.d/.*"]      = "swayconfig",
      -- GPG
      [".*%.gpg"]                   = function(_, _)
        return nil -- binary; don't override
      end,
    },
  
    -- ── Extension matches ─────────────────────────────────────────────────────
    extension = {
      -- Hyprland
      ["hypr"]     = "hyprlang",
      -- Rasi (rofi)
      ["rasi"]     = "rasi",
      -- Fish
      ["fish"]     = "fish",
      -- KDL (zellij / other)
      ["kdl"]      = "kdl",
      -- Nix
      ["nix"]      = "nix",
      -- Just
      ["just"]     = "just",
      -- Terraform
      ["tf"]       = "terraform",
      ["tfvars"]   = "terraform-vars",
      -- Gleam
      ["gleam"]    = "gleam",
      -- Zig
      ["zig"]      = "zig",
      -- WGSL (WebGPU shader)
      ["wgsl"]     = "wgsl",
      -- GLSL variants
      ["frag"]     = "glsl",
      ["vert"]     = "glsl",
      ["geom"]     = "glsl",
      ["comp"]     = "glsl",
      -- Mustache / Handlebars
      ["hbs"]      = "handlebars",
      ["mustache"] = "mustache",
      -- Spicetify
      ["xpui"]     = "ini",
      -- SDDM QML
      ["qml"]      = "qml",
      -- Astro
      ["astro"]    = "astro",
      -- Svelte
      ["svelte"]   = "svelte",
      -- MDX
      ["mdx"]      = "markdown.mdx",
      -- Prisma
      ["prisma"]   = "prisma",
    },
  })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 02  PER-FILETYPE BUFFER-LOCAL SETTINGS
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Central location: avoids scattered after/ftplugin files for simple tweaks.
  -- Complex filetype setups live in their dedicated lua/plugins/lang/*.lua.
  
  local ft_group = vim.api.nvim_create_augroup("AshCore_FileType", { clear = true })
  
  ---@class FtSettings
  ---@field ts       integer?   tabstop
  ---@field sw       integer?   shiftwidth
  ---@field et       boolean?   expandtab
  ---@field wrap     boolean?   wrap
  ---@field spell    boolean?   spell
  ---@field tw       integer?   textwidth
  ---@field cc       string?    colorcolumn
  ---@field cms      string?    commentstring
  ---@field fo_add   string?    formatoptions to add
  ---@field fo_rem   string?    formatoptions to remove
  
  ---@type table<string, FtSettings>
  local ft_settings = {
    -- ── Indentation: 4 spaces ──────────────────────────────────────────────
    python       = { ts = 4, sw = 4, et = true,  tw = 88,  cc = "89",  cms = "# %s" },
    rust         = { ts = 4, sw = 4, et = true,  tw = 100, cc = "101"               },
    go           = { ts = 4, sw = 4, et = false, cc = "100"                         },
    java         = { ts = 4, sw = 4, et = true,  cc = "120"                         },
    kotlin       = { ts = 4, sw = 4, et = true,  cc = "120"                         },
    swift        = { ts = 4, sw = 4, et = true,  cc = "120"                         },
    c            = { ts = 4, sw = 4, et = true,  cc = "80"                          },
    cpp          = { ts = 4, sw = 4, et = true,  cc = "100"                         },
    cs           = { ts = 4, sw = 4, et = true,  cc = "120"                         },
    php          = { ts = 4, sw = 4, et = true,  cc = "120"                         },
    ruby         = { ts = 2, sw = 2, et = true,  cc = "120"                         },
    haskell      = { ts = 2, sw = 2, et = true,  cc = "80"                          },
    elixir       = { ts = 2, sw = 2, et = true,  cc = "98"                          },
    -- ── Indentation: 2 spaces ──────────────────────────────────────────────
    lua          = { ts = 2, sw = 2, et = true,  cc = "100", cms = "-- %s"          },
    javascript   = { ts = 2, sw = 2, et = true,  cc = "100"                         },
    typescript   = { ts = 2, sw = 2, et = true,  cc = "100"                         },
    javascriptreact = { ts = 2, sw = 2, et = true, cc = "100"                       },
    typescriptreact = { ts = 2, sw = 2, et = true, cc = "100"                       },
    html         = { ts = 2, sw = 2, et = true,  wrap = false                       },
    css          = { ts = 2, sw = 2, et = true                                       },
    scss         = { ts = 2, sw = 2, et = true                                       },
    svelte       = { ts = 2, sw = 2, et = true                                       },
    vue          = { ts = 2, sw = 2, et = true                                       },
    astro        = { ts = 2, sw = 2, et = true                                       },
    json         = { ts = 2, sw = 2, et = true,  cc = ""                            },
    jsonc        = { ts = 2, sw = 2, et = true,  cc = "", cms = "// %s"             },
    yaml         = { ts = 2, sw = 2, et = true,  cc = ""                            },
    toml         = { ts = 2, sw = 2, et = true                                       },
    nix          = { ts = 2, sw = 2, et = true,  cc = "100"                         },
    terraform    = { ts = 2, sw = 2, et = true,  cc = "80"                          },
    fish         = { ts = 4, sw = 4, et = true,  cms = "# %s"                       },
    bash         = { ts = 2, sw = 2, et = true,  cms = "# %s"                       },
    sh           = { ts = 2, sw = 2, et = true,  cms = "# %s"                       },
    zsh          = { ts = 2, sw = 2, et = true,  cms = "# %s"                       },
    hyprlang     = { ts = 2, sw = 2, et = true,  cms = "# %s"                       },
    rasi         = { ts = 2, sw = 2, et = true,  cms = "// %s"                      },
    -- ── Prose / writing ────────────────────────────────────────────────────
    markdown     = { ts = 2, sw = 2, et = true,  wrap = true, spell = true, tw = 80 },
    ["markdown.mdx"] = { ts = 2, sw = 2, et = true, wrap = true, tw = 80            },
    text         = { wrap = true, spell = true,  tw = 80                            },
    tex          = { wrap = true, spell = true,  tw = 80, cms = "% %s"              },
    rst          = { wrap = true, spell = true,  tw = 80, cms = ".. %s"             },
    org          = { wrap = true, spell = true,  tw = 80, cms = "# %s"              },
    norg         = { wrap = true, spell = true,  tw = 100                            },
    gitcommit    = { wrap = true, spell = true,  tw = 72, cc = "73"                 },
    -- ── Special ────────────────────────────────────────────────────────────
    make         = { ts = 4, sw = 4, et = false                                      },
    just         = { ts = 4, sw = 4, et = false, cms = "# %s"                       },
    sql          = { ts = 2, sw = 2, et = true,  cms = "-- %s"                      },
    dockerfile   = { ts = 4, sw = 4, et = true,  cms = "# %s"                       },
    systemd      = { ts = 4, sw = 4, et = true,  cms = "# %s"                       },
    tmux         = { ts = 2, sw = 2, et = true,  cms = "# %s"                       },
    sshconfig    = { ts = 2, sw = 2, et = true                                       },
    editorconfig = { ts = 2, sw = 2, et = true                                       },
    qml          = { ts = 4, sw = 4, et = true                                       },
    gleam        = { ts = 2, sw = 2, et = true,  cc = "100"                         },
    zig          = { ts = 4, sw = 4, et = true,  cc = "100"                         },
    glsl         = { ts = 4, sw = 4, et = true                                       },
    prisma       = { ts = 2, sw = 2, et = true                                       },
  }
  
  -- Collect all filetypes for the pattern list
  local ft_list = vim.tbl_keys(ft_settings)
  
  vim.api.nvim_create_autocmd("FileType", {
    group   = ft_group,
    pattern = ft_list,
    desc    = "Apply per-filetype buffer settings (ASH)",
    callback = function(ev)
      local ft  = ev.match
      local cfg = ft_settings[ft]
      if not cfg then return end
  
      local bo  = vim.bo[ev.buf]
      local opt = vim.opt_local
  
      if cfg.ts    ~= nil then bo.tabstop      = cfg.ts  end
      if cfg.sw    ~= nil then bo.shiftwidth   = cfg.sw  end
      if cfg.et    ~= nil then bo.expandtab    = cfg.et  end
      if cfg.tw    ~= nil then bo.textwidth    = cfg.tw  end
      if cfg.wrap  ~= nil then opt.wrap        = cfg.wrap end
      if cfg.spell ~= nil then opt.spell       = cfg.spell end
      if cfg.cc    ~= nil then opt.colorcolumn = cfg.cc  end
      if cfg.cms   ~= nil then bo.commentstring = cfg.cms end
  
      if cfg.fo_add then opt.formatoptions:append(cfg.fo_add) end
      if cfg.fo_rem then opt.formatoptions:remove(cfg.fo_rem) end
    end,
  })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 03  COMMENTSTRING EXTRAS (for ts-context-commentstring fallback)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Some filetypes need commentstring but aren't in the settings table above.
  
  vim.api.nvim_create_autocmd("FileType", {
    group   = ft_group,
    pattern = {
      "hyprlang", "rasi", "kdl",
      "helm", "terraform", "terraform-vars",
      "just", "fish", "direnv",
    },
    desc    = "Ensure commentstring for special filetypes",
    callback = function(ev)
      local cms_map = {
        hyprlang       = "# %s",
        rasi           = "// %s",
        kdl            = "// %s",
        helm           = "{{/* %s */}}",
        terraform      = "# %s",
        ["terraform-vars"] = "# %s",
        just           = "# %s",
        fish           = "# %s",
        direnv         = "# %s",
      }
      local ft  = ev.match
      local cms = cms_map[ft]
      if cms then vim.bo[ev.buf].commentstring = cms end
    end,
  })
  
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- § 04  ICON → FILETYPE MAP  (consumed by nvim-web-devicons / neo-tree)
  -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  -- Expose a curated mapping that devicons can consume for custom filetypes
  -- that don't have built-in icon support.
  
  ---@class AshFiletype
  ---@field icon  string   Nerd Font icon
  ---@field color string   Hex color
  ---@field name  string   Label
  
  ---@type table<string, AshFiletype>
  local M = {}
  
  M.custom_icons = {
    hyprlang      = { icon = " ",   color = "#00d4d4", name = "HyprLang"     },
    rasi          = { icon = " ",   color = "#e95678", name = "Rasi"         },
    fish          = { icon = " ",   color = "#4fc2f7", name = "Fish"         },
    kitty         = { icon = "󰄛 ",   color = "#f9a825", name = "Kitty"        },
    just          = { icon = " ",   color = "#ff6c00", name = "Justfile"     },
    kdl           = { icon = " ",   color = "#b0bec5", name = "KDL"          },
    nix           = { icon = " ",   color = "#7ebae4", name = "Nix"          },
    gleam         = { icon = "⬡ ",   color = "#ffaff3", name = "Gleam"        },
    astro         = { icon = " ",   color = "#e84d6d", name = "Astro"        },
    svelte        = { icon = " ",   color = "#ff3e00", name = "Svelte"       },
    prisma        = { icon = " ",   color = "#5a67d8", name = "Prisma"       },
    terraform     = { icon = "󱁢 ",   color = "#7b42bc", name = "Terraform"    },
    dockerfile    = { icon = "󰡨 ",   color = "#0db7ed", name = "Dockerfile"   },
    systemd       = { icon = " ",   color = "#f5a623", name = "Systemd"      },
    ["markdown.mdx"] = { icon = " ", color = "#fcb900", name = "MDX"         },
    ["yaml.ansible"] = { icon = " ", color = "#ee0000", name = "Ansible"     },
    ["yaml.docker-compose"] = { icon = "󰡨 ", color = "#0db7ed", name = "DockerCompose" },
    direnv        = { icon = " ",   color = "#89b4fa", name = "Direnv"       },
    glsl          = { icon = "󰯾 ",   color = "#67c1f5", name = "GLSL"         },
    wgsl          = { icon = "󰯾 ",   color = "#67c1f5", name = "WGSL"         },
  }
  
  -- Register with nvim-web-devicons if it's loaded
  vim.schedule(function()
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then return end
    devicons.set_icon(M.custom_icons)
  end)
  
  return M