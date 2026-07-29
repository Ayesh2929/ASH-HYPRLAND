; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       󰣇 HYPRLAND CONFIG — TREESITTER INJECTIONS v5.0 OMEGA                    ║
; ║   Shell command injection · regex injection · Lua/Python exec injection        ║
; ║   Environment variable values · config include paths · plugin configs          ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🐚 SHELL COMMAND INJECTION — exec / exec-once params
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; exec = command arguments → highlight as bash
(keyword
  name: (identifier) @_exec
  (#match? @_exec "^exec")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; exec-once with complex shell pipeline
(keyword
  name: (identifier) @_exec_once
  (#eq? @_exec_once "exec-once")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.combined))

; exec with [workspace=...] flag prefix
(keyword
  name: (identifier) @_exec_flag
  (#match? @_exec_flag "^exec")
  (#set! injection.language "bash"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 SOURCE INJECTION — source = /path/to/file.conf
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; source file paths — highlight path as string
(keyword
  name: (identifier) @_source
  (#eq? @_source "source")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌐 BIND DISPATCHER INJECTION — shell commands in bind dispatchers
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; bind = MOD, key, exec, <shell-command>
; The last param of a bind with exec dispatcher → inject as bash
(keyword
  name: (identifier) @_bind
  (#match? @_bind "^bind")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔤 REGEX INJECTION — windowrule class/title patterns (regex strings)
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; windowrulev2 class: and title: values often contain regex
; Inject regex highlighting for class= and title= matcher values
(keyword
  name: (identifier) @_wr
  (#any-of? @_wr "windowrule" "windowrulev2" "layerrule")
  params: (params) @injection.content
  (#set! injection.language "regex")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📁 PLUGIN PATH INJECTION — plugin = /path/to/.so
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; plugin paths as bash strings (no actual injection but marks the content)
(keyword
  name: (identifier) @_plugin
  (#eq? @_plugin "plugin")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌡️  MONITOR TRANSFORM / MODELINE INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; monitor = name, resolution, position, scale → bash for complex descriptions
(keyword
  name: (identifier) @_monitor
  (#eq? @_monitor "monitor")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔒 ENV VARIABLE INJECTION — env = KEY, VALUE
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; env = VAR_NAME, value
; Value portion can contain shell-style content
(keyword
  name: (identifier) @_env
  (#eq? @_env "env")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENT INJECTION — special markers inside comments
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; TODO / FIXME / HACK / NOTE comments — inject comment content
((comment) @injection.content
  (#set! injection.language "comment"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 ASH THEME COMMENTS — special colour preview annotations
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Comments containing hex colours for colour preview plugins
((comment) @injection.content
  (#match? @injection.content "#[0-9a-fA-F]{6,8}")
  (#set! injection.language "comment"))

; ASH-specific metadata comments (# @ash:key value)
((comment) @injection.content
  (#match? @injection.content "^#.*@ash:")
  (#set! injection.language "comment"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧩 SUBMAP INJECTION — submap names as labels
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; submap = name — the name is a plain identifier
(keyword
  name: (identifier) @_submap
  (#eq? @_submap "submap")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🖼️  WORKSPACE RULES INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; workspace = name, rule1, rule2, ...
(keyword
  name: (identifier) @_workspace
  (#eq? @_workspace "workspace")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔌 DEVICE CONFIG INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; device { name = "...", ... }
; Device names can be complex strings — inject as bash for quoted content
(section
  name: (identifier) @_device_section
  (#eq? @_device_section "device")
  (assignment
    name: (identifier) @_device_name
    (#eq? @_device_name "name")
    value: (_) @injection.content
    (#set! injection.language "bash")
    (#set! injection.include-unnamed true)))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📊 BEZIER CURVE INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; bezier = name, x1, y1, x2, y2 — numeric params, no injection needed
; but keep for reference if future bezier DSL parsing is needed
(keyword
  name: (identifier) @_bezier
  (#eq? @_bezier "bezier")
  params: (params) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎭 ASH HYPRLAND SCRIPT INJECTIONS
; These patterns detect common ASH dotfiles patterns and inject accordingly
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; exec = ash <command> — ASH CLI commands get bash injection
(keyword
  name: (identifier) @_ash_exec
  (#match? @_ash_exec "^exec")
  params: (params) @injection.content
  (#match? @injection.content "ash ")
  (#set! injection.language "bash")
  (#set! injection.combined))

; exec = hyprctl <dispatch> — hyprctl dispatch commands
(keyword
  name: (identifier) @_hyprctl_exec
  (#match? @_hyprctl_exec "^exec")
  params: (params) @injection.content
  (#match? @injection.content "hyprctl ")
  (#set! injection.language "bash")
  (#set! injection.combined))

; exec = waybar / dunst / swaync / swww / etc. (common autostart programs)
(keyword
  name: (identifier) @_autostart
  (#match? @_autostart "^exec")
  params: (params) @injection.content
  (#match? @injection.content
    "(waybar|dunst|swaync|swww|hyprpaper|hypridle|hyprlock|nm-applet|blueman)")
  (#set! injection.language "bash")
  (#set! injection.combined))