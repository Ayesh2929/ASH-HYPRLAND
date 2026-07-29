; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       🎨 RASI (ROFI STYLESHEET) — TREESITTER INJECTIONS v5.0 OMEGA             ║
; ║   Comment markers · @import paths · url() paths · calc() math                 ║
; ║   Colour function arguments · font strings · ASH theme references              ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENT INJECTION — special annotation markers
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Block comments /* ... */ → inject as comment
((comment) @injection.content
  (#set! injection.language "comment"))

; TODO / FIXME / NOTE / HACK / WARN inside block comments
((comment) @injection.content
  (#match? @injection.content "(TODO|FIXME|HACK|NOTE|WARN|PERF|ASH)")
  (#set! injection.language "comment"))

; ASH-specific metadata inside comments — @ash:key value
((comment) @injection.content
  (#match? @injection.content "@ash:")
  (#set! injection.language "comment"))

; Hex colour references inside comments (for colour preview)
((comment) @injection.content
  (#match? @injection.content "#[0-9a-fA-F]{3,8}")
  (#set! injection.language "comment"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📂 @IMPORT PATH INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @import "path/to/file.rasi" — inject path as bash string
(at_rule
  keyword: (at_keyword) @_import
  (#eq? @_import "@import")
  (string_value) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; @theme "theme-name" — inject theme name as bash
(at_rule
  keyword: (at_keyword) @_theme
  (#eq? @_theme "@theme")
  (string_value) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; @plugin "plugin-path" — inject plugin path as bash
(at_rule
  keyword: (at_keyword) @_plugin
  (#eq? @_plugin "@plugin")
  (string_value) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌐 URL() PATH INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; url("path") — inject as bash path
(function_call
  function: (identifier) @_url
  (#any-of? @_url "url" "image" "url-prefix")
  (argument
    (string_value) @injection.content
    (#set! injection.language "bash")
    (#set! injection.include-unnamed true)))

; url(path-without-quotes) — inject as bash
(function_call
  function: (identifier) @_url_bare
  (#any-of? @_url_bare "url" "image")
  (argument
    (identifier) @injection.content
    (#set! injection.language "bash")
    (#set! injection.include-unnamed true)))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 COLOUR FUNCTION ARGUMENT INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; rgba(r, g, b, a) argument list — each arg is a number
(function_call
  function: (identifier) @_colour_fn
  (#any-of? @_colour_fn "rgba" "rgb" "argb" "hsl" "hsla" "hwb")
  (argument_list) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; color-mix() function — complex colour mixing
(function_call
  function: (identifier) @_mix
  (#eq? @_mix "color-mix")
  (argument_list) @injection.content
  (#set! injection.language "css")
  (#set! injection.include-unnamed true))

; linear-gradient() / radial-gradient()
(function_call
  function: (identifier) @_gradient
  (#any-of? @_gradient
    "linear-gradient"
    "radial-gradient"
    "conic-gradient"
    "repeating-linear-gradient"
    "repeating-radial-gradient")
  (argument_list) @injection.content
  (#set! injection.language "css")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧮 CALC() EXPRESSION INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; calc() — inject as CSS expression
(function_call
  function: (identifier) @_calc
  (#any-of? @_calc "calc" "min" "max" "clamp" "round" "mod" "rem" "sin" "cos" "tan" "asin" "acos" "atan" "atan2" "pow" "sqrt" "hypot" "log" "exp" "abs" "sign")
  (argument_list) @injection.content
  (#set! injection.language "css")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ✏️  FONT STRING INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; font property string — font name and size (Pango markup format)
(property
  name: (identifier) @_font_prop
  (#eq? @_font_prop "font")
  value: (string_value) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔒 CONFIGURATION BLOCK VARIABLE INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; configuration { } block — the inner statements use a more specialised grammar
(configuration
  (ruleset) @injection.content
  (#set! injection.language "rasi")
  (#set! injection.combined))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 ASH COLOUR TOKEN INJECTION — colour preview in string values
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; String values containing hex colour codes (for colorizer plugins)
((string_value) @injection.content
  (#match? @injection.content "#[0-9a-fA-F]{3,8}")
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌅 BACKGROUND-IMAGE / CONTENT STRING INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; background-image property value → treat as path
(property
  name: (identifier) @_bg_img
  (#any-of? @_bg_img
    "background-image"
    "icon"
    "content"
    "cursor-image")
  value: (string_value) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 @VARIABLE REFERENCE INJECTION — @var in value position
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; var() CSS custom property reference
(function_call
  function: (identifier) @_var
  (#eq? @_var "var")
  (argument_list) @injection.content
  (#set! injection.language "css")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔧 ENV() VARIABLE INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; env(ENV_VAR, fallback) — environment variable lookup
(function_call
  function: (identifier) @_env
  (#eq? @_env "env")
  (argument_list) @injection.content
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎭 ASH ROFI THEME INTEGRATION — special ASH patterns
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; ASH colour variables follow the pattern @clr-* or @ash-*
((variable) @injection.content
  (#match? @injection.content "^@(clr|ash|color|colour)-")
  (#set! injection.language "bash")
  (#set! injection.include-unnamed true))

; ASH theme variable definitions inside /* @ash: ... */ comments
((comment) @injection.content
  (#match? @injection.content "^/\\* @ash:")
  (#set! injection.language "comment"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📐 MEDIA QUERY INJECTION — @media (...) conditions
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @media condition block → inject as CSS media query
(at_rule
  keyword: (at_keyword) @_media
  (#eq? @_media "@media")
  (block) @injection.content
  (#set! injection.language "css")
  (#set! injection.combined))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎬 KEYFRAMES INJECTION — @keyframes animation blocks
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; @keyframes name { ... } → inject as CSS
(at_rule
  keyword: (at_keyword) @_keyframes
  (#eq? @_keyframes "@keyframes")
  (block) @injection.content
  (#set! injection.language "css")
  (#set! injection.combined))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔍 STEPS() / CUBIC-BEZIER() TIMING INJECTION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; steps() and cubic-bezier() easing functions
(function_call
  function: (identifier) @_timing
  (#any-of? @_timing "steps" "cubic-bezier" "path")
  (argument_list) @injection.content
  (#set! injection.language "css")
  (#set! injection.include-unnamed true))