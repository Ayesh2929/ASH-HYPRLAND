; ╔══════════════════════════════════════════════════════════════════════════════════╗
; ║       󰣇 HYPRLAND CONFIG — TREESITTER HIGHLIGHTS v5.0 OMEGA                    ║
; ║   Complete semantic highlighting · sections · keywords · values · expressions  ║
; ║   Colours · modifiers · binds · window rules · animations · gestures           ║
; ╚══════════════════════════════════════════════════════════════════════════════════╝

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📝 COMMENTS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(comment) @comment @spell

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🗂️  SECTION HEADERS — top-level config blocks
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Section names (general { ... }, input { ... }, etc.)
(section
  name: (identifier) @keyword.type
  (#any-of? @keyword.type
    "general"
    "decoration"
    "animations"
    "input"
    "gestures"
    "group"
    "misc"
    "binds"
    "xwayland"
    "opengl"
    "render"
    "cursor"
    "debug"
    "ecosystem"
    "experimental"))

; Subsection names (e.g. touchpad { ... } inside input)
(section
  (section
    name: (identifier) @keyword.type))

; All identifiers used as section names (broader catch)
(section
  name: (identifier) @type)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔑 KEYWORD STATEMENTS — top-level directives
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Core directives
(keyword
  name: (identifier) @keyword
  (#any-of? @keyword
    "monitor"
    "exec"
    "exec-once"
    "exec-shutdown"
    "windowrule"
    "windowrulev2"
    "layerrule"
    "bind"
    "binde"
    "bindr"
    "bindn"
    "bindm"
    "bindl"
    "bindit"
    "bindrt"
    "bindnt"
    "workspace"
    "wsbind"
    "env"
    "source"
    "plugin"
    "submap"
    "bezier"
    "animation"
    "device"
    "masterEnable"
    "master"
    "dwindle"
    "decoration"
    "general"))

; exec variants — run commands
(keyword
  name: (identifier) @function.macro
  (#match? @function.macro "^exec"))

; bind variants — key bindings
(keyword
  name: (identifier) @function
  (#match? @function "^bind"))

; windowrule / windowrulev2 — window matching rules
(keyword
  name: (identifier) @attribute
  (#any-of? @attribute
    "windowrule"
    "windowrulev2"
    "layerrule"))

; source — file inclusion
(keyword
  name: (identifier) @keyword.import
  (#eq? @keyword.import "source"))

; env — environment variable
(keyword
  name: (identifier) @keyword.modifier
  (#eq? @keyword.modifier "env"))

; monitor — display configuration
(keyword
  name: (identifier) @keyword.type
  (#eq? @keyword.type "monitor"))

; workspace — workspace rules
(keyword
  name: (identifier) @keyword.type
  (#eq? @keyword.type "workspace"))

; bezier — animation curve
(keyword
  name: (identifier) @function.call
  (#eq? @function.call "bezier"))

; animation — animation definition
(keyword
  name: (identifier) @function.call
  (#eq? @function.call "animation"))

; plugin — plugin loading
(keyword
  name: (identifier) @keyword.modifier
  (#eq? @keyword.modifier "plugin"))

; submap — submap definition
(keyword
  name: (identifier) @label
  (#eq? @label "submap"))

; device — per-device configuration
(keyword
  name: (identifier) @type
  (#eq? @type "device"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🏷️  ASSIGNMENTS — key = value pairs inside sections
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; LHS identifier (property name)
(assignment
  name: (identifier) @property)

; Nested assignments (sub-properties)
(assignment
  (assignment
    name: (identifier) @property))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔢 LITERALS — values on the RHS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Integer literal
(integer_literal) @number

; Float literal (e.g. 1.5, 0.8)
(float_literal) @number.float

; Boolean values
((identifier) @boolean
  (#any-of? @boolean "true" "false" "yes" "no" "on" "off"))

; Negative numbers (unary minus)
(unary_expression
  operator: "-"
  operand: (integer_literal) @number)

(unary_expression
  operator: "-"
  operand: (float_literal) @number.float)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎨 COLOUR LITERALS — rgba(), rgb(), hex
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; rgba(RRGGBBAA) colour
(color_literal) @string.special

; Hex colours as identifiers (e.g. 0xRRGGBBAA)
((integer_literal) @string.special
  (#match? @string.special "^0[xX][0-9a-fA-F]+$"))

; rgb(r, g, b) function call style
((identifier) @string.special
  (#any-of? @string.special "rgb" "rgba"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔗 OPERATORS & PUNCTUATION
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Assignment operator
"=" @operator

; Arithmetic operators
"+" @operator
"-" @operator
"*" @operator
"/" @operator

; Comparison / logic
"==" @operator
"!=" @operator
"<"  @operator
">"  @operator
"<=" @operator
">=" @operator
"&&" @operator
"||" @operator
"!"  @operator

; Section braces
"{" @punctuation.bracket
"}" @punctuation.bracket

; Argument separators
"," @punctuation.delimiter
";" @punctuation.delimiter

; Range / flag prefix
"$" @punctuation.special
"%" @punctuation.special

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎯 VARIABLES — $VAR usage
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Variable definition
(variable_definition
  name: (variable) @variable)

; Variable reference inside expressions
(variable) @variable

; Variable with $ sigil
((variable) @variable.builtin
  (#match? @variable.builtin "^\\$"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔌 KNOWN PROPERTY VALUES — semantic colouring for well-known values
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Layout types
((identifier) @type.builtin
  (#any-of? @type.builtin
    "dwindle"
    "master"
    "scroller"
    "hyprfocus"
    "grid"))

; Blur / shadow keywords
((identifier) @keyword.modifier
  (#any-of? @keyword.modifier
    "enable"
    "disable"
    "toggle"
    "workspace"
    "silent"
    "float"
    "fullscreen"
    "maximize"
    "pin"
    "center"
    "focus"
    "immediate"))

; Window positions / sizes
((identifier) @constant.builtin
  (#any-of? @constant.builtin
    "left"
    "right"
    "up"
    "down"
    "top"
    "bottom"
    "center"
    "none"
    "inherit"
    "current"
    "previous"
    "next"
    "first"
    "last"
    "empty"
    "all"
    "active"
    "visible"))

; Workspace special
((identifier) @constant.builtin
  (#match? @constant.builtin "^special"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; ⌨️  MODIFIER KEYS — in bind statements
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Modifier key names
((identifier) @constant.macro
  (#any-of? @constant.macro
    "SUPER"
    "ALT"
    "CTRL"
    "SHIFT"
    "HYPER"
    "META"
    "CAPS"
    "MOD1"
    "MOD2"
    "MOD3"
    "MOD4"
    "MOD5"
    "MOD"
    "SUPERL"
    "SUPERR"
    "ALTL"
    "ALTR"
    "CTRLL"
    "CTRLR"
    "SHIFTR"
    "SHIFTL"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🎬 DISPATCHERS — hyprctl dispatch targets
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Dispatcher function names
((identifier) @function.builtin
  (#any-of? @function.builtin
    "exec"
    "execr"
    "pass"
    "sendshortcut"
    "killactive"
    "closewindow"
    "workspace"
    "movetoworkspace"
    "movetoworkspacesilent"
    "togglefloating"
    "fullscreen"
    "fakefullscreen"
    "dpms"
    "pin"
    "movefocus"
    "movewindow"
    "movewindowpixel"
    "resizeactive"
    "resizewindowpixel"
    "cyclenext"
    "swapnext"
    "swapwindow"
    "focuswindow"
    "focusmonitor"
    "splitratio"
    "toggleopaque"
    "movecursortocorner"
    "movecursor"
    "screenshot"
    "screenshottocursor"
    "global"
    "submap"
    "setprop"
    "layoutmsg"
    "exec-once"
    "togglegroup"
    "changegroupactive"
    "focusurgent"
    "centerwindow"
    "rollingscroll"
    "bringactivetotop"
    "alterzorder"
    "togglespecialworkspace"
    "focusspecialworkspace"
    "movespecialworkspace"
    "swapactiveworkspaces"
    "forcerenderreload"
    "renameworkspace"
    "exit"
    "forcerendererreload"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌊 ANIMATION NAMES — bezier/animation identifiers
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Built-in animation events
((identifier) @constant
  (#any-of? @constant
    "windows"
    "windowsIn"
    "windowsOut"
    "windowsMove"
    "fade"
    "fadeIn"
    "fadeOut"
    "fadeSwitch"
    "fadeShadow"
    "fadeDim"
    "fadeLayers"
    "fadeLayersIn"
    "fadeLayersOut"
    "border"
    "borderangle"
    "workspaces"
    "specialWorkspace"
    "layers"
    "layersIn"
    "layersOut"))

; Animation style keywords
((identifier) @string.special
  (#any-of? @string.special
    "slide"
    "slidevert"
    "slidefade"
    "slidefadevert"
    "popin"
    "fade"
    "gnomed"
    "squish"
    "once"
    "loop"
    "default"
    "easeInSine"
    "easeOutSine"
    "easeInOutSine"
    "easeInQuad"
    "easeOutQuad"
    "easeInOutQuad"
    "easeInCubic"
    "easeOutCubic"
    "easeInOutCubic"
    "easeInExpo"
    "easeOutExpo"
    "easeInOutExpo"
    "easeInCirc"
    "easeOutCirc"
    "easeInOutCirc"
    "easeInBack"
    "easeOutBack"
    "easeInOutBack"
    "linear"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📺 MONITOR PARAMS — in monitor = statements
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Special monitor names
((identifier) @constant.builtin
  (#any-of? @constant.builtin
    "preferred"
    "auto"
    "auto-left"
    "auto-right"
    "auto-up"
    "auto-down"
    "highrr"
    "highres"
    "transform"
    "mirror"
    "desc"
    "bitdepth"
    "vrr"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🪟 WINDOW RULE PARAMS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Window rule actions
((identifier) @attribute.builtin
  (#any-of? @attribute.builtin
    "float"
    "tile"
    "fullscreen"
    "maximize"
    "nofullscreenrequest"
    "nomaximizerequest"
    "move"
    "size"
    "minsize"
    "maxsize"
    "center"
    "pseudo"
    "monitor"
    "workspace"
    "opacity"
    "opaque"
    "forceinput"
    "windowdance"
    "pin"
    "noanim"
    "noblur"
    "noshadow"
    "noborder"
    "nodim"
    "nofocus"
    "noinitialfocus"
    "forcergbx"
    "rounding"
    "animation"
    "bordercolor"
    "renderunfocused"
    "xray"
    "scrolltouchpad"
    "stayfocused"
    "idleinhibit"
    "suppressevent"
    "dimaround"
    "decal"
    "keepaspectratio"
    "group"
    "tag"
    "focusonactivate"))

; Window rule matchers
((identifier) @attribute
  (#any-of? @attribute
    "class"
    "title"
    "xwayland"
    "floating"
    "fullscreen"
    "maximized"
    "pinned"
    "focus"
    "workspace"
    "monitor"
    "onworkspace"
    "activewindow"
    "pid"
    "tag"
    "initialtitle"
    "initialclass"
    "contenttype"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔌 PLUGIN NAMES — commonly used Hyprland plugins
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

((identifier) @module.builtin
  (#any-of? @module.builtin
    "hyprspace"
    "hyprexpo"
    "hyprbars"
    "hyprwinwrap"
    "hy3"
    "hyprscroller"
    "hyprfocus"
    "hyprtasking"
    "hyprfloat"
    "hycov"
    "hyprtrails"
    "hyprgrass"
    "hyprswitch"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 📐 DWINDLE / MASTER LAYOUT PARAMS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Layout-specific keywords
((identifier) @keyword.modifier
  (#any-of? @keyword.modifier
    "pseudotile"
    "preserve_split"
    "force_split"
    "special_scale_factor"
    "new_is_master"
    "new_on_top"
    "mfact"
    "orientation"
    "smart_split"
    "smart_resizing"
    "permanent_direction_override"
    "use_active_for_splits"
    "default_split_ratio"
    "slave"
    "left"
    "right"
    "top"
    "bottom"
    "center"
    "inherit_fullscreen"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🌟 SPECIAL IDENTIFIERS — $mainMod and common variables
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Commonly defined variable names — highlight as constants
((variable) @constant
  (#match? @constant "^\\$(mainMod|terminal|browser|fileManager|menu|editor|lock|player)$"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔠 IDENTIFIERS — fallback catch-all for remaining identifiers
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; Generic identifier (lowest priority, only if no other rule matched)
(identifier) @variable

; Keyword values in assignments (rhs identifier that is a known config value)
(assignment
  value: (identifier) @string)

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🖥️  EXEC COMMANDS — special treatment for exec/exec-once values
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

; The command argument in exec/exec-once
(keyword
  name: (identifier) @function.macro
  (#match? @function.macro "^exec")
  params: (params (identifier) @string))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🔒 IDLE INHIBIT VALUES
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

((identifier) @constant.builtin
  (#any-of? @constant.builtin
    "always"
    "focus"
    "fullscreen"
    "open"
    "none"
    "visible"))

; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
; 🧩 GROUPBAR & GROUP PARAMS
; ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

((identifier) @keyword.modifier
  (#any-of? @keyword.modifier
    "lock"
    "inverted"
    "deny"
    "barHeight"
    "font"
    "fontSize"
    "gradients"
    "render_titles"
    "scrolling"
    "text_color"
    "gradients"
    "col.active"
    "col.inactive"
    "col.locked_active"
    "col.locked_inactive"))